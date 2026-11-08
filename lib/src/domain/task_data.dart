import 'local_date.dart';
import 'task.dart';

/// What a day holds for one task.
enum DayStatus {
  /// Ticked for that day.
  done,

  /// Expected on a past day and not ticked.
  missed,

  /// Expected today and not ticked yet.
  pending,

  /// Expected on a later day.
  upcoming,

  /// Not expected that day (not started, ended, or not one of its days).
  notScheduled,
}

/// Counts for one task over a range of days, never past today.
class TaskStats {
  const TaskStats({
    required this.done,
    required this.missed,
    required this.todayPending,
    required this.streak,
  });

  /// Days ticked.
  final int done;

  /// Past days that were expected and not ticked.
  final int missed;

  /// Expected today and not ticked yet (counted neither as done nor missed).
  final bool todayPending;

  /// Expected days in a row that were ticked, ending today or yesterday.
  /// Days the task was not expected do not break it; today pending does not
  /// break it either.
  final int streak;

  /// Done out of the days that are settled (done + missed).
  int get settled => done + missed;
}

/// All tasks and the days they were ticked.
class TaskData {
  TaskData({
    List<Task> tasks = const [],
    Map<String, Map<LocalDate, DateTime>> completions = const {},
    Map<String, Map<LocalDate, Set<String>>> stepTicks = const {},
  }) : stepTicks = Map<String, Map<LocalDate, Set<String>>>.unmodifiable({
         for (final e in stepTicks.entries)
           if (e.value.values.any((s) => s.isNotEmpty))
             e.key: Map<LocalDate, Set<String>>.unmodifiable({
               for (final d in e.value.entries)
                 if (d.value.isNotEmpty)
                   d.key: Set<String>.unmodifiable(d.value),
             }),
       }),
       tasks = List<Task>.unmodifiable(
         <Task>[...tasks]..sort((a, b) => a.order.compareTo(b.order)),
       ),
       completions = Map<String, Map<LocalDate, DateTime>>.unmodifiable({
         for (final e in completions.entries)
           if (e.value.isNotEmpty)
             e.key: Map<LocalDate, DateTime>.unmodifiable(e.value),
       });

  static final TaskData empty = TaskData();

  /// Sorted by [Task.order].
  final List<Task> tasks;

  /// Task id → day → when the tick was made (UTC).
  final Map<String, Map<LocalDate, DateTime>> completions;

  /// Task id → day → ids of the steps ticked that day.
  final Map<String, Map<LocalDate, Set<String>>> stepTicks;

  /// Steps of [taskId] ticked on [date] (only ids of steps that still exist).
  Set<String> stepsDone(String taskId, LocalDate date) {
    final ticked = stepTicks[taskId]?[date];
    if (ticked == null) return const {};
    final ids = taskById(taskId)?.steps.map((s) => s.id).toSet() ?? const {};
    return ticked.intersection(ids);
  }

  /// Ticks ([on]) or unticks one step of [taskId] for [date].
  TaskData withStepTick(String taskId, LocalDate date, String stepId, bool on) {
    final forTask = <LocalDate, Set<String>>{
      for (final e in (stepTicks[taskId] ?? const {}).entries)
        e.key: {...e.value},
    };
    final day = forTask.putIfAbsent(date, () => {});
    on ? day.add(stepId) : day.remove(stepId);
    return copyWith(stepTicks: {...stepTicks, taskId: forTask});
  }

  Task? taskById(String id) {
    for (final t in tasks) {
      if (t.id == id) return t;
    }
    return null;
  }

  /// When [taskId] was ticked for [date], or null.
  DateTime? doneAt(String taskId, LocalDate date) => completions[taskId]?[date];

  bool isDone(String taskId, LocalDate date) => doneAt(taskId, date) != null;

  DayStatus statusOf(Task task, LocalDate date, LocalDate today) {
    if (isDone(task.id, date)) return DayStatus.done;
    if (!task.isScheduledOn(date)) return DayStatus.notScheduled;
    if (date.isBefore(today)) return DayStatus.missed;
    if (date == today) return DayStatus.pending;
    return DayStatus.upcoming;
  }

  /// Tasks to show on [date]: those expected that day, and those ticked
  /// that day even if they are no longer expected (a tick is never hidden).
  List<Task> tasksOn(LocalDate date) => [
    for (final t in tasks)
      if (t.isScheduledOn(date) || isDone(t.id, date)) t,
  ];

  /// Statistics for [task] over [from]..[to] (both included), clipped at
  /// [today].
  TaskStats statsFor(
    Task task, {
    required LocalDate from,
    required LocalDate to,
    required LocalDate today,
  }) {
    final last = to.isAfter(today) ? today : to;
    var done = 0;
    var missed = 0;
    var todayPending = false;
    for (var d = from; !d.isAfter(last); d = d.addDays(1)) {
      switch (statusOf(task, d, today)) {
        case DayStatus.done:
          done++;
        case DayStatus.missed:
          missed++;
        case DayStatus.pending:
          todayPending = true;
        case DayStatus.upcoming:
        case DayStatus.notScheduled:
          break;
      }
    }
    return TaskStats(
      done: done,
      missed: missed,
      todayPending: todayPending,
      streak: streakFor(task, today),
    );
  }

  /// See [TaskStats.streak].
  int streakFor(Task task, LocalDate today) {
    final ticks = completions[task.id];
    var earliest = task.startDate;
    if (ticks != null) {
      for (final d in ticks.keys) {
        if (d.isBefore(earliest)) earliest = d;
      }
    }
    var streak = 0;
    for (var d = today; !d.isBefore(earliest); d = d.addDays(-1)) {
      switch (statusOf(task, d, today)) {
        case DayStatus.done:
          streak++;
        case DayStatus.missed:
          return streak;
        case DayStatus.pending:
        case DayStatus.upcoming:
        case DayStatus.notScheduled:
          break;
      }
    }
    return streak;
  }

  TaskData copyWith({
    List<Task>? tasks,
    Map<String, Map<LocalDate, DateTime>>? completions,
    Map<String, Map<LocalDate, Set<String>>>? stepTicks,
  }) => TaskData(
    tasks: tasks ?? this.tasks,
    completions: completions ?? this.completions,
    stepTicks: stepTicks ?? this.stepTicks,
  );

  /// [task] added, or replacing the task with the same id.
  TaskData withTask(Task task) {
    final list = [...tasks];
    final i = list.indexWhere((t) => t.id == task.id);
    if (i >= 0) {
      list[i] = task;
    } else {
      list.add(task);
    }
    return copyWith(tasks: list);
  }

  /// The task and every tick it had removed.
  TaskData withoutTask(String taskId) => TaskData(
    tasks: [
      for (final t in tasks)
        if (t.id != taskId) t,
    ],
    completions: {
      for (final e in completions.entries)
        if (e.key != taskId) e.key: e.value,
    },
    stepTicks: {
      for (final e in stepTicks.entries)
        if (e.key != taskId) e.key: e.value,
    },
  );

  /// Ticks ([at] non-null) or unticks [taskId] for [date].
  TaskData withTick(String taskId, LocalDate date, DateTime? at) {
    final forTask = {...?completions[taskId]};
    if (at == null) {
      forTask.remove(date);
    } else {
      forTask[date] = at.toUtc();
    }
    return copyWith(completions: {...completions, taskId: forTask});
  }

  /// Orders the tasks as in [ids]; tasks missing from [ids] keep their
  /// relative order after them.
  TaskData reordered(List<String> ids) {
    final byId = {for (final t in tasks) t.id: t};
    final ordered = <Task>[
      for (final id in ids)
        if (byId.containsKey(id)) byId.remove(id)!,
      ...tasks.where((t) => byId.containsKey(t.id)),
    ];
    return copyWith(
      tasks: [
        for (var i = 0; i < ordered.length; i++) ordered[i].copyWith(order: i),
      ],
    );
  }

  /// One more than the largest order in use.
  int get nextOrder => tasks.isEmpty ? 0 : tasks.last.order + 1;
}
