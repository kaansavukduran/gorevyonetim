import 'package:flutter_test/flutter_test.dart';
import 'package:gunluk_gorevler/src/domain/codec.dart';
import 'package:gunluk_gorevler/src/domain/local_date.dart';
import 'package:gunluk_gorevler/src/domain/repeat_rule.dart';
import 'package:gunluk_gorevler/src/domain/task.dart';
import 'package:gunluk_gorevler/src/domain/task_data.dart';

LocalDate d(String iso) => LocalDate.parse(iso);

Task task(String id, RepeatRule rule, String start, {int order = 0}) => Task(
  id: id,
  title: 'Görev $id',
  note: '',
  schedule: [ScheduleSegment(d(start), rule)],
  createdAt: DateTime.utc(2026, 11, 1),
  order: order,
);

final at = DateTime.utc(2026, 11, 7, 9);

void main() {
  final today = d('2026-11-07'); // Saturday

  group('status of a day', () {
    final daily = task('a', const DailyRule(), '2026-11-01');
    final data = TaskData(tasks: [daily]).withTick('a', d('2026-11-05'), at);

    test('ticked is done, whatever the day', () {
      expect(data.statusOf(daily, d('2026-11-05'), today), DayStatus.done);
    });

    test('a past expected day without a tick is missed', () {
      expect(data.statusOf(daily, d('2026-11-06'), today), DayStatus.missed);
    });

    test('today without a tick is pending, not missed', () {
      expect(data.statusOf(daily, today, today), DayStatus.pending);
    });

    test('a later day is upcoming', () {
      expect(data.statusOf(daily, d('2026-11-08'), today), DayStatus.upcoming);
    });

    test('before the start nothing was expected (not missed)', () {
      expect(
        data.statusOf(daily, d('2026-10-31'), today),
        DayStatus.notScheduled,
      );
    });

    test('a tick on a day the rule no longer covers stays visible', () {
      final changed = daily.withRuleFrom(d('2026-11-02'), WeeklyRule({1}));
      final next = data.withTask(changed);
      // Thursday is not a Monday, but it was ticked.
      expect(next.statusOf(changed, d('2026-11-05'), today), DayStatus.done);
      expect(next.tasksOn(d('2026-11-05')).map((t) => t.id), ['a']);
      expect(next.tasksOn(d('2026-11-04')), isEmpty);
    });
  });

  group('statistics', () {
    final daily = task('a', const DailyRule(), '2026-11-01');
    var data = TaskData(tasks: [daily]);
    for (final day in [
      '2026-11-01',
      '2026-11-02',
      '2026-11-04',
      '2026-11-05',
      '2026-11-06',
    ]) {
      data = data.withTick('a', d(day), at);
    }

    test('counts done and missed over settled days, today pending apart', () {
      final s = data.statsFor(
        daily,
        from: d('2026-11-01'),
        to: today,
        today: today,
      );
      expect(s.done, 5);
      expect(s.missed, 1); // 3 November
      expect(s.todayPending, isTrue);
      expect(s.settled, 6);
    });

    test('days before the start are not counted as missed', () {
      final s = data.statsFor(
        daily,
        from: d('2026-10-20'),
        to: today,
        today: today,
      );
      expect(s.missed, 1);
    });

    test('days after today are never counted', () {
      final s = data.statsFor(
        daily,
        from: d('2026-11-01'),
        to: d('2026-11-30'),
        today: today,
      );
      expect(s.done + s.missed, 6);
    });

    test('streak runs back to the first missed day; today pending does not break it', () {
      expect(data.streakFor(daily, today), 3);
      final tickedToday = data.withTick('a', today, at);
      expect(tickedToday.streakFor(daily, today), 4);
    });

    test('days the task is not expected do not break the streak', () {
      final mwf = task('m', WeeklyRule({1, 3, 5}), '2026-11-01');
      var md = TaskData(tasks: [mwf]);
      for (final day in ['2026-11-02', '2026-11-04', '2026-11-06']) {
        md = md.withTick('m', d(day), at);
      }
      expect(md.streakFor(mwf, today), 3);
      expect(
        md.statsFor(mwf, from: d('2026-11-01'), to: today, today: today).missed,
        0,
      );
    });

    test('a missed day yesterday ends the streak at zero', () {
      final t = task('x', const DailyRule(), '2026-11-05');
      final xd = TaskData(tasks: [t]).withTick('x', d('2026-11-05'), at);
      expect(xd.streakFor(t, today), 0);
    });
  });

  group('changes', () {
    test('untick removes only that day', () {
      final t = task('a', const DailyRule(), '2026-11-01');
      final data = TaskData(tasks: [t])
          .withTick('a', d('2026-11-05'), at)
          .withTick('a', d('2026-11-06'), at)
          .withTick('a', d('2026-11-05'), null);
      expect(data.isDone('a', d('2026-11-05')), isFalse);
      expect(data.isDone('a', d('2026-11-06')), isTrue);
    });

    test('removing a task removes its ticks', () {
      final data = TaskData(
        tasks: [
          task('a', const DailyRule(), '2026-11-01'),
          task('b', const DailyRule(), '2026-11-01', order: 1),
        ],
      ).withTick('a', today, at).withTick('b', today, at).withoutTask('a');
      expect(data.tasks.map((t) => t.id), ['b']);
      expect(data.completions.keys, ['b']);
    });

    test('reorder follows the given ids and renumbers', () {
      final data = TaskData(
        tasks: [
          task('a', const DailyRule(), '2026-11-01'),
          task('b', const DailyRule(), '2026-11-01', order: 1),
          task('c', const DailyRule(), '2026-11-01', order: 2),
        ],
      ).reordered(['c', 'a']);
      expect(data.tasks.map((t) => t.id), ['c', 'a', 'b']);
      expect(data.tasks.map((t) => t.order), [0, 1, 2]);
      expect(data.nextOrder, 3);
    });
  });

  group('file format', () {
    final data = TaskData(
      tasks: [
        task('a', const DailyRule(), '2026-11-01'),
        task('b', WeeklyRule({1, 3}), '2026-11-02', order: 1),
      ],
    ).withTick('a', d('2026-11-05'), at).withTick('b', d('2026-11-04'), at);

    test('round-trips', () {
      final text = encodeTaskData(data, savedAt: at);
      final back = decodeTaskData(text);
      expect(back.tasks.map((t) => t.id), ['a', 'b']);
      expect(back.doneAt('a', d('2026-11-05')), at);
      expect(back.isDone('b', d('2026-11-04')), isTrue);
      expect(encodeTaskData(back, savedAt: at), text);
    });

    test('keeps Turkish characters', () {
      final t = task(
        'a',
        const DailyRule(),
        '2026-11-01',
      ).copyWith(title: 'Çiçekleri sula, ğüşıöç');
      final back = decodeTaskData(
        encodeTaskData(TaskData(tasks: [t]), savedAt: at),
      );
      expect(back.tasks.single.title, 'Çiçekleri sula, ğüşıöç');
    });

    test('refuses a newer format without guessing', () {
      final text = encodeTaskData(
        data,
        savedAt: at,
      ).replaceFirst('"schema_version": 2', '"schema_version": 3');
      expect(() => decodeTaskData(text), throwsA(isA<NewerSchemaException>()));
    });

    test('refuses broken files', () {
      final good = encodeTaskData(data, savedAt: at);
      for (final bad in [
        '',
        'not json',
        '[]',
        '{"app": "baska"}',
        good.replaceFirst('"app": "gunluk_gorevler"', '"app": "x"'),
        good.replaceFirst('"task_id": "a"', '"task_id": "zzz"'),
        good.replaceFirst('"id": "b"', '"id": "a"'),
        good.replaceFirst('"date": "2026-11-05"', '"date": "2026-11-31"'),
      ]) {
        expect(() => decodeTaskData(bad), throwsFormatException, reason: bad);
      }
    });
  });
}
