import 'package:flutter_test/flutter_test.dart';
import 'package:gunluk_gorevler/src/domain/local_date.dart';
import 'package:gunluk_gorevler/src/domain/repeat_rule.dart';
import 'package:gunluk_gorevler/src/domain/task.dart';
import 'package:gunluk_gorevler/src/domain/turkish_dates.dart';

LocalDate d(String iso) => LocalDate.parse(iso);

Task task(List<ScheduleSegment> schedule, {String id = 't1'}) => Task(
  id: id,
  title: 'Su iç',
  note: '',
  schedule: schedule,
  createdAt: DateTime.utc(2026, 11, 1),
  order: 0,
);

void main() {
  group('LocalDate', () {
    test('parses and prints YYYY-MM-DD', () {
      expect(d('2026-11-07').toIso(), '2026-11-07');
      expect(d('2026-11-07').weekday, DateTime.saturday);
    });

    test('refuses malformed text and days that do not exist', () {
      for (final bad in ['2026-2-1', '2026-02-30', '2025-02-29', 'dün', '']) {
        expect(() => d(bad), throwsFormatException, reason: bad);
      }
      expect(d('2024-02-29').toIso(), '2024-02-29');
    });

    test('adds days across month, year and leap boundaries', () {
      expect(d('2026-12-31').addDays(1), d('2027-01-01'));
      expect(d('2024-02-28').addDays(1), d('2024-02-29'));
      expect(d('2026-03-01').addDays(-1), d('2026-02-28'));
      expect(d('2026-01-01').daysUntil(d('2026-12-31')), 364);
      expect(d('2026-11-07').daysUntil(d('2026-11-01')), -6);
    });

    test('a day is one day even across a clock change', () {
      // Europe changes clocks on 2026-03-29 and 2026-10-25.
      expect(d('2026-03-28').addDays(1), d('2026-03-29'));
      expect(d('2026-03-29').addDays(1), d('2026-03-30'));
      expect(d('2026-10-25').addDays(1), d('2026-10-26'));
    });

    test('of() takes the local calendar day', () {
      final local = DateTime(2026, 11, 7, 23, 59);
      expect(LocalDate.of(local), d('2026-11-07'));
    });

    test('compares by calendar', () {
      expect(d('2026-11-07').isBefore(d('2026-11-08')), isTrue);
      expect(d('2026-11-07').isAfter(d('2025-12-31')), isTrue);
      expect(d('2026-11-07'), d('2026-11-07'));
    });
  });

  group('RepeatRule', () {
    test('daily matches every day', () {
      expect(const DailyRule().matches(d('2026-11-07')), isTrue);
    });

    test('weekly matches only its weekdays', () {
      final mwf = WeeklyRule({1, 3, 5});
      expect(mwf.matches(d('2026-11-09')), isTrue); // Monday
      expect(mwf.matches(d('2026-11-10')), isFalse); // Tuesday
      expect(mwf.matches(d('2026-11-13')), isTrue); // Friday
      expect(mwf.matches(d('2026-11-08')), isFalse); // Sunday
    });

    test('weekly refuses no days and out-of-range days', () {
      expect(() => WeeklyRule({}), throwsArgumentError);
      expect(() => WeeklyRule({0}), throwsArgumentError);
      expect(() => WeeklyRule({8}), throwsArgumentError);
    });

    test('once matches its own day only', () {
      final once = OnceRule(d('2026-11-07'));
      expect(once.matches(d('2026-11-07')), isTrue);
      expect(once.matches(d('2026-11-08')), isFalse);
    });

    test('round-trips through JSON', () {
      for (final rule in <RepeatRule>[
        const DailyRule(),
        WeeklyRule({7, 1}),
        OnceRule(d('2026-11-07')),
      ]) {
        expect(RepeatRule.fromJson(rule.toJson()), rule);
      }
      expect(WeeklyRule({7, 1}).toJson()['weekdays'], [1, 7]);
    });

    test('refuses unknown or broken JSON', () {
      for (final bad in <Object?>[
        null,
        {'type': 'monthly'},
        {'type': 'weekly'},
        {
          'type': 'weekly',
          'weekdays': [9],
        },
        {'type': 'once'},
        {'type': 'once', 'date': '2026-13-01'},
      ]) {
        expect(() => RepeatRule.fromJson(bad), throwsFormatException);
      }
    });

    test('describes itself in Turkish', () {
      expect(describeRule(const DailyRule()), 'Her gün');
      expect(describeRule(WeeklyRule({1, 2, 3, 4, 5})), 'Hafta içi');
      expect(describeRule(WeeklyRule({6, 7})), 'Hafta sonu');
      expect(describeRule(WeeklyRule({5, 1, 3})), 'Pzt, Çar, Cum');
      expect(describeRule(WeeklyRule({1, 2, 3, 4, 5, 6, 7})), 'Her gün');
      expect(describeRule(OnceRule(d('2026-11-07'))), 'Tek sefer: 7 Kasım');
    });
  });

  group('Task schedule', () {
    test('is not expected before its start', () {
      final t = task([ScheduleSegment(d('2026-11-05'), const DailyRule())]);
      expect(t.isScheduledOn(d('2026-11-04')), isFalse);
      expect(t.isScheduledOn(d('2026-11-05')), isTrue);
      expect(t.isScheduledOn(d('2030-01-01')), isTrue);
    });

    test('a rule change applies from its day on and keeps earlier days', () {
      final t = task([ScheduleSegment(d('2026-11-01'), const DailyRule())])
          .withRuleFrom(d('2026-11-07'), WeeklyRule({1}));
      expect(t.isScheduledOn(d('2026-11-03')), isTrue); // Tuesday, old rule
      expect(t.isScheduledOn(d('2026-11-07')), isFalse); // Saturday, new rule
      expect(t.isScheduledOn(d('2026-11-09')), isTrue); // Monday
      expect(t.schedule, hasLength(2));
    });

    test('ending keeps the past and stops from the end day', () {
      final t = task([ScheduleSegment(d('2026-11-01'), const DailyRule())])
          .withRuleFrom(d('2026-11-07'), null);
      expect(t.isScheduledOn(d('2026-11-06')), isTrue);
      expect(t.isScheduledOn(d('2026-11-07')), isFalse);
      expect(t.isEndedOn(d('2026-11-07')), isTrue);
      expect(t.isEndedOn(d('2026-11-06')), isFalse);
      expect(t.hasFutureOn(d('2026-11-07')), isFalse);
      expect(t.lastRule, const DailyRule());
    });

    test('restarting on the end day removes the end marker', () {
      final t = task([ScheduleSegment(d('2026-11-01'), const DailyRule())])
          .withRuleFrom(d('2026-11-07'), null)
          .withRuleFrom(d('2026-11-07'), const DailyRule());
      expect(t.schedule, [ScheduleSegment(d('2026-11-01'), const DailyRule())]);
    });

    test('restarting later leaves the ended days unexpected', () {
      final t = task([ScheduleSegment(d('2026-11-01'), const DailyRule())])
          .withRuleFrom(d('2026-11-03'), null)
          .withRuleFrom(d('2026-11-07'), const DailyRule());
      expect(t.isScheduledOn(d('2026-11-02')), isTrue);
      expect(t.isScheduledOn(d('2026-11-04')), isFalse);
      expect(t.isScheduledOn(d('2026-11-07')), isTrue);
      expect(t.isEndedOn(d('2026-11-07')), isFalse);
    });

    test('the same rule again changes nothing', () {
      final base = task([ScheduleSegment(d('2026-11-01'), const DailyRule())]);
      expect(
        base.withRuleFrom(d('2026-11-07'), const DailyRule()).schedule,
        base.schedule,
      );
    });

    test('a one-off has a future only until its day', () {
      final t = task([
        ScheduleSegment(d('2026-11-07'), OnceRule(d('2026-11-07'))),
      ]);
      expect(t.hasFutureOn(d('2026-11-06')), isTrue);
      expect(t.hasFutureOn(d('2026-11-07')), isTrue);
      expect(t.hasFutureOn(d('2026-11-08')), isFalse);
    });

    test('ending before the start leaves no rule', () {
      final t = task([ScheduleSegment(d('2026-11-10'), const DailyRule())])
          .withRuleFrom(d('2026-11-10'), null);
      expect(t.lastRule, isNull);
      expect(t.isScheduledOn(d('2026-11-12')), isFalse);
      expect(t.hasFutureOn(d('2026-11-07')), isFalse);
    });

    test('refuses an empty title and unsorted segments', () {
      expect(
        () => Task(
          id: 'x',
          title: '  ',
          note: '',
          schedule: [ScheduleSegment(d('2026-11-01'), const DailyRule())],
          createdAt: DateTime.utc(2026),
          order: 0,
        ),
        throwsArgumentError,
      );
      expect(
        () => task([
          ScheduleSegment(d('2026-11-05'), const DailyRule()),
          ScheduleSegment(d('2026-11-05'), null),
        ]),
        throwsArgumentError,
      );
    });

    test('round-trips through JSON', () {
      final t = task([
        ScheduleSegment(d('2026-11-01'), const DailyRule()),
        ScheduleSegment(d('2026-11-04'), null),
        ScheduleSegment(d('2026-11-06'), WeeklyRule({1, 3})),
      ]);
      final back = Task.fromJson(t.toJson());
      expect(back.schedule, t.schedule);
      expect(back.title, t.title);
      expect(back.createdAt, t.createdAt);
    });
  });
}
