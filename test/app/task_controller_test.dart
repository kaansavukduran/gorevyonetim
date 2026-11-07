import 'package:flutter_test/flutter_test.dart';
import 'package:gunluk_gorevler/src/app/task_controller.dart';
import 'package:gunluk_gorevler/src/domain/codec.dart';
import 'package:gunluk_gorevler/src/domain/local_date.dart';
import 'package:gunluk_gorevler/src/domain/repeat_rule.dart';
import 'package:gunluk_gorevler/src/storage/memory_task_store.dart';

LocalDate d(String iso) => LocalDate.parse(iso);

void main() {
  late DateTime now;
  late MemoryTaskStore store;
  late TaskController c;

  setUp(() async {
    now = DateTime(2026, 11, 7, 10); // Saturday, local time
    store = MemoryTaskStore();
    c = TaskController(store: store, clock: () => now);
    await c.load();
  });

  test('starts empty and ready when nothing is saved', () {
    expect(c.state, LoadState.ready);
    expect(c.data.tasks, isEmpty);
    expect(c.today, d('2026-11-07'));
  });

  test('every change is saved', () async {
    final t = c.addTask(
      title: '  Su iç  ',
      rule: const DailyRule(),
      start: c.today,
    );
    await c.saved;
    expect(t.title, 'Su iç');
    expect(decodeTaskData(store.saved!).tasks.single.title, 'Su iç');

    c.toggle(t.id, c.today);
    await c.saved;
    expect(decodeTaskData(store.saved!).isDone(t.id, c.today), isTrue);
    expect(store.saveCount, 2);
  });

  test('toggle ticks with the current time and unticks', () {
    final t = c.addTask(
      title: 'Su iç',
      rule: const DailyRule(),
      start: c.today,
    );
    expect(c.toggle(t.id, c.today), isTrue);
    expect(c.data.doneAt(t.id, c.today), now.toUtc());
    expect(c.toggle(t.id, c.today), isFalse);
    expect(c.data.isDone(t.id, c.today), isFalse);
  });

  test('a past day can be ticked later; a future day cannot', () {
    final t = c.addTask(
      title: 'Su iç',
      rule: const DailyRule(),
      start: d('2026-11-01'),
    );
    expect(c.toggle(t.id, d('2026-11-03')), isTrue);
    expect(() => c.toggle(t.id, d('2026-11-08')), throwsStateError);
    expect(c.data.isDone(t.id, d('2026-11-08')), isFalse);
  });

  test('a one-off starts on its own date', () {
    final t = c.addTask(
      title: 'Fatura',
      rule: OnceRule(d('2026-11-10')),
      start: c.today,
    );
    expect(t.startDate, d('2026-11-10'));
    expect(c.data.tasksOn(c.today), isEmpty);
    expect(c.data.tasksOn(d('2026-11-10')).single.id, t.id);
  });

  test('editing the rule keeps what earlier days expected', () {
    final t = c.addTask(
      title: 'Spor',
      rule: const DailyRule(),
      start: d('2026-11-01'),
    );
    c.updateTask(t.id, title: 'Spor salonu', rule: WeeklyRule({1, 3, 5}));
    final edited = c.data.taskById(t.id)!;
    expect(edited.title, 'Spor salonu');
    expect(edited.isScheduledOn(d('2026-11-03')), isTrue); // old rule, Tuesday
    expect(edited.isScheduledOn(c.today), isFalse); // Saturday, new rule
    expect(edited.isScheduledOn(d('2026-11-09')), isTrue);
  });

  test('editing only the title leaves the schedule alone', () {
    final t = c.addTask(
      title: 'Spor',
      rule: const DailyRule(),
      start: d('2026-11-01'),
    );
    c.updateTask(t.id, title: 'Yürüyüş', rule: const DailyRule());
    expect(c.data.taskById(t.id)!.schedule, t.schedule);
  });

  test('editing a task that has not started moves its rule, not its start', () {
    final t = c.addTask(
      title: 'Kurs',
      rule: const DailyRule(),
      start: d('2026-11-10'),
    );
    c.updateTask(t.id, title: 'Kurs', rule: WeeklyRule({2}));
    final edited = c.data.taskById(t.id)!;
    expect(edited.startDate, d('2026-11-10'));
    expect(edited.isScheduledOn(d('2026-11-09')), isFalse);
    expect(edited.isScheduledOn(d('2026-11-10')), isTrue); // Tuesday
  });

  test(
    'ending: earlier days stay, today\'s tick stays, later days are empty',
    () {
      final t = c.addTask(
        title: 'Su iç',
        rule: const DailyRule(),
        start: d('2026-11-05'),
      );
      c.toggle(t.id, d('2026-11-05'));
      c.toggle(t.id, c.today);
      c.endTask(t.id);
      final ended = c.data.taskById(t.id)!;
      expect(c.data.isDone(t.id, d('2026-11-05')), isTrue);
      expect(c.data.tasksOn(c.today).single.id, t.id);
      expect(c.data.tasksOn(d('2026-11-08')), isEmpty);
      final s = c.data.statsFor(
        ended,
        from: d('2026-11-01'),
        to: c.today,
        today: c.today,
      );
      expect(s.done, 2);
      expect(s.missed, 1); // 6 November
      expect(ended.hasFutureOn(c.today), isFalse);
    },
  );

  test('ending an unticked task today drops it from today without a miss', () {
    final t = c.addTask(
      title: 'Su iç',
      rule: const DailyRule(),
      start: c.today,
    );
    c.endTask(t.id);
    expect(c.data.tasksOn(c.today), isEmpty);
    final s = c.data.statsFor(
      c.data.taskById(t.id)!,
      from: c.today,
      to: c.today,
      today: c.today,
    );
    expect(s.missed, 0);
    expect(s.todayPending, isFalse);
  });

  test('restart after a gap keeps the gap unexpected', () {
    final t = c.addTask(
      title: 'Su iç',
      rule: const DailyRule(),
      start: d('2026-11-01'),
    );
    now = DateTime(2026, 11, 3, 9);
    c.refreshToday();
    c.endTask(t.id);
    now = DateTime(2026, 11, 7, 9);
    c.refreshToday();
    c.restartTask(t.id, const DailyRule());
    final task = c.data.taskById(t.id)!;
    expect(task.isScheduledOn(d('2026-11-02')), isTrue);
    expect(task.isScheduledOn(d('2026-11-05')), isFalse);
    expect(task.isScheduledOn(c.today), isTrue);
  });

  test('delete removes the task and its ticks; restore undoes it', () {
    final t = c.addTask(
      title: 'Su iç',
      rule: const DailyRule(),
      start: c.today,
    );
    c.toggle(t.id, c.today);
    final before = c.data;
    c.deleteTask(t.id);
    expect(c.data.tasks, isEmpty);
    expect(c.data.completions, isEmpty);
    c.restore(before);
    expect(c.data.isDone(t.id, c.today), isTrue);
  });

  test('refreshToday notices midnight', () {
    expect(c.refreshToday(), isFalse);
    now = DateTime(2026, 11, 8, 0, 1);
    expect(c.refreshToday(), isTrue);
    expect(c.today, d('2026-11-08'));
  });

  test('a failed save is reported and cleared by the next good save', () async {
    store.failWith = Exception('disk dolu');
    final t = c.addTask(
      title: 'Su iç',
      rule: const DailyRule(),
      start: c.today,
    );
    await c.saved;
    expect(c.saveError, contains('disk dolu'));
    expect(c.data.tasks.single.id, t.id); // the change stays on screen
    store.failWith = null;
    c.toggle(t.id, c.today);
    await c.saved;
    expect(c.saveError, isNull);
    expect(decodeTaskData(store.saved!).tasks.single.id, t.id);
  });

  test(
    'an unreadable file blocks changes until the user starts over',
    () async {
      final broken = MemoryTaskStore(saved: '{ bozuk');
      final bc = TaskController(store: broken, clock: () => now);
      await bc.load();
      expect(bc.state, LoadState.unreadable);
      expect(bc.loadError, isNotNull);
      expect(
        () => bc.addTask(title: 'x', rule: const DailyRule(), start: bc.today),
        throwsStateError,
      );
      expect(broken.saved, '{ bozuk');
      await bc.startOverAfterUnreadable();
      expect(bc.state, LoadState.ready);
      bc.addTask(title: 'x', rule: const DailyRule(), start: bc.today);
    },
  );

  test('ids are unique', () {
    final ids = {
      for (var i = 0; i < 50; i++)
        c.addTask(title: 'g$i', rule: const DailyRule(), start: c.today).id,
    };
    expect(ids, hasLength(50));
  });
}
