import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../domain/game.dart';
import '../domain/local_date.dart';
import '../domain/quests.dart';
import '../domain/repeat_rule.dart';
import '../domain/task.dart';
import '../domain/task_data.dart';
import '../storage/task_store.dart';
import 'settings.dart';

enum LoadState { loading, ready, unreadable }

/// Holds the tasks, applies every change and saves it.
///
/// Every change is saved at once. When a save fails the change stays on
/// screen, [saveError] says so, and the next change tries again.
class TaskController extends ChangeNotifier {
  TaskController({
    required this.store,
    DateTime Function()? clock,
    Random? random,
  }) : _clock = clock ?? DateTime.now,
       _random = random ?? Random.secure() {
    _today = LocalDate.of(_clock());
  }

  final TaskStore store;
  final DateTime Function() _clock;
  final Random _random;

  LoadState _state = LoadState.loading;
  LoadState get state => _state;

  String? _loadError;

  /// Why the saved file could not be used ([LoadState.unreadable]).
  String? get loadError => _loadError;

  String? _saveError;

  /// Set while the latest change could not be saved.
  String? get saveError => _saveError;

  TaskData _data = TaskData.empty;
  TaskData get data => _data;

  late LocalDate _today;
  LocalDate get today => _today;

  DateTime now() => _clock();

  AppSettings _settings = const AppSettings();
  AppSettings get settings => _settings;

  /// Changes and saves the settings (a failed save keeps them for now).
  Future<void> updateSettings(AppSettings next) async {
    _settings = next;
    notifyListeners();
    try {
      await store.saveSettings(next);
    } catch (e) {
      _saveError = 'Ayarlar kaydedilemedi: $e';
      notifyListeners();
    }
  }

  GameProfile? _profile;
  LocalDate? _profileDay;

  /// XP, level, stats and badges for the current data (cached).
  GameProfile get profile {
    if (_profile == null || _profileDay != _today) {
      _profile = GameProfile.of(_data, _today);
      _profileDay = _today;
    }
    return _profile!;
  }

  QuestBook? _quests;
  LocalDate? _questsDay;

  /// Daily quest, weekly challenge and gold for the current data (cached).
  QuestBook get quests {
    if (_quests == null || _questsDay != _today) {
      _quests = QuestBook.of(_data, _today);
      _questsDay = _today;
    }
    return _quests!;
  }

  Future<void> load() async {
    _settings = await store.loadSettings();
    final result = await store.load();
    switch (result) {
      case LoadMissing():
        _data = TaskData.empty;
        _state = LoadState.ready;
      case LoadOk(:final data):
        _data = data;
        _state = LoadState.ready;
      case LoadUnreadable(:final message):
        _loadError = message;
        _state = LoadState.unreadable;
    }
    _profile = null;
    _quests = null;
    notifyListeners();
  }

  /// Moves the unreadable file aside and starts an empty list.
  Future<String> startOverAfterUnreadable() async {
    final movedTo = await store.setAsideUnreadable(now: _clock());
    _loadError = null;
    _data = TaskData.empty;
    _profile = null;
    _quests = null;
    _state = LoadState.ready;
    notifyListeners();
    return movedTo;
  }

  /// Picks up a new day after midnight. Returns true when the day changed.
  bool refreshToday() {
    final day = LocalDate.of(_clock());
    if (day == _today) return false;
    _today = day;
    notifyListeners();
    return true;
  }

  String _newId() {
    final stamp = _clock().microsecondsSinceEpoch.toRadixString(36);
    final noise = List.generate(
      6,
      (_) => _random.nextInt(16).toRadixString(16),
    ).join();
    return 't$stamp$noise';
  }

  /// Adds a task expected from [start] on (a one-off on its own date).
  Task addTask({
    required String title,
    String note = '',
    required RepeatRule rule,
    required LocalDate start,
    Difficulty difficulty = Difficulty.orta,
    ClockTime? time,
    List<String> steps = const [],
  }) {
    final from = rule is OnceRule ? rule.date : start;
    final task = Task(
      id: _newId(),
      title: title.trim(),
      note: note.trim(),
      schedule: [ScheduleSegment(from, rule)],
      createdAt: _clock().toUtc(),
      order: _data.nextOrder,
      difficulty: difficulty,
      time: time,
      steps: _stepsFrom(steps, const []),
    );
    _apply(_data.withTask(task));
    return task;
  }

  /// The day from which a new rule for [task] applies: today, or the start
  /// of a task that has not begun yet. A one-off moved to an earlier date
  /// applies from that date (the person chose that day).
  LocalDate effectiveFrom(Task task, RepeatRule rule) {
    var from = task.startDate.isAfter(_today) ? task.startDate : _today;
    if (rule is OnceRule && rule.date.isBefore(from)) from = rule.date;
    return from;
  }

  /// Renames, re-notes and, when [rule] differs, changes the rule from
  /// [effectiveFrom] on. Earlier days keep the rule they had.
  void updateTask(
    String id, {
    required String title,
    String note = '',
    RepeatRule? rule,
    Difficulty? difficulty,
    ClockTime? Function()? time,
    List<String>? steps,
  }) {
    final old = _require(id);
    var task = old.copyWith(
      title: title.trim(),
      note: note.trim(),
      difficulty: difficulty,
      time: time,
      steps: steps == null ? null : _stepsFrom(steps, old.steps),
    );
    if (rule != null && rule != task.ruleOn(effectiveFrom(task, rule))) {
      task = task.withRuleFrom(effectiveFrom(task, rule), rule);
    }
    _apply(_data.withTask(task));
  }

  /// Ends the task from today on. Earlier days and every tick stay; a tick
  /// made today stays visible.
  void endTask(String id) {
    final task = _require(id);
    final from = task.startDate.isAfter(_today) ? task.startDate : _today;
    _apply(_data.withTask(task.withRuleFrom(from, null)));
  }

  /// Starts an ended task again from today with [rule]. The days it was
  /// ended stay "not expected".
  void restartTask(String id, RepeatRule rule) {
    final task = _require(id);
    final from = rule is OnceRule && rule.date.isAfter(_today)
        ? rule.date
        : _today;
    _apply(_data.withTask(task.withRuleFrom(from, rule)));
  }

  /// Removes the task and all its ticks.
  void deleteTask(String id) {
    _require(id);
    _apply(_data.withoutTask(id));
  }

  /// Ticks or unticks [id] for [date]. A later day cannot be ticked.
  /// Returns whether the task is now ticked.
  bool toggle(String id, LocalDate date) {
    _require(id);
    if (date.isAfter(_today)) {
      throw StateError('İleri bir gün işaretlenemez');
    }
    final done = _data.isDone(id, date);
    _apply(_data.withTick(id, date, done ? null : _clock()));
    return !done;
  }

  void reorder(List<String> ids) => _apply(_data.reordered(ids));

  /// Builds steps from titles, keeping the id of a step whose title is
  /// unchanged (so its ticks stay).
  List<TaskStep> _stepsFrom(List<String> titles, List<TaskStep> old) {
    final pool = [...old];
    final out = <TaskStep>[];
    for (final raw in titles) {
      final title = raw.trim();
      if (title.isEmpty) continue;
      final i = pool.indexWhere((s) => s.title == title);
      if (i >= 0) {
        out.add(pool.removeAt(i));
      } else {
        String id;
        do {
          id = 's${_random.nextInt(1 << 30).toRadixString(36)}';
        } while (out.any((s) => s.id == id) || pool.any((s) => s.id == id));
        out.add(TaskStep(id, title));
      }
    }
    return out;
  }

  /// Ticks or unticks one step of [id] on [date]. Ticking the last open step
  /// ticks the task; unticking a step of a ticked task unticks the task (it
  /// is no longer fully done). Returns whether the task is now ticked.
  bool toggleStep(String id, LocalDate date, String stepId) {
    final task = _require(id);
    if (date.isAfter(_today)) {
      throw StateError('İleri bir gün işaretlenemez');
    }
    final on = !_data.stepsDone(id, date).contains(stepId);
    var next = _data.withStepTick(id, date, stepId, on);
    final allDone =
        task.steps.isNotEmpty &&
        next.stepsDone(id, date).length == task.steps.length;
    if (on && allDone && !next.isDone(id, date)) {
      next = next.withTick(id, date, _clock());
    } else if (!on && next.isDone(id, date)) {
      next = next.withTick(id, date, null);
    }
    _apply(next);
    return next.isDone(id, date);
  }

  /// Exports the current data to a backup file; returns its path.
  Future<String?> exportBackup() => store.exportBackup(_data, now: _clock());

  /// Replaces everything with [imported], after keeping the current data
  /// aside. Returns where the current data was kept.
  Future<String?> importBackup(TaskData imported) async {
    final kept = await store.keepBeforeImport(_data, now: _clock());
    _apply(imported);
    return kept;
  }

  /// Puts back an earlier state (undo).
  void restore(TaskData snapshot) => _apply(snapshot);

  Task _require(String id) {
    final task = _data.taskById(id);
    if (task == null) throw StateError('Görev bulunamadı: $id');
    return task;
  }

  Future<void> _pending = Future.value();

  /// Completes when every change so far has been written (or has failed).
  Future<void> get saved => _pending;

  void _apply(TaskData next) {
    if (_state != LoadState.ready) {
      throw StateError('Veri dosyası okunamadı; değişiklik yapılamaz');
    }
    _data = next;
    _profile = null;
    _quests = null;
    notifyListeners();
    _pending = _save(next);
  }

  Future<void> _save(TaskData snapshot) async {
    try {
      await store.save(snapshot, now: _clock());
      if (identical(snapshot, _data) && _saveError != null) {
        _saveError = null;
        notifyListeners();
      }
    } catch (e) {
      _saveError = 'Kaydedilemedi: $e';
      notifyListeners();
    }
  }
}
