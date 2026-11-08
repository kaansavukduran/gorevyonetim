import 'package:flutter_test/flutter_test.dart';
import 'package:gunluk_gorevler/src/domain/local_date.dart';
import 'package:gunluk_gorevler/src/domain/quests.dart';
import 'package:gunluk_gorevler/src/domain/repeat_rule.dart';
import 'package:gunluk_gorevler/src/domain/task.dart';
import 'package:gunluk_gorevler/src/domain/task_data.dart';

LocalDate d(String iso) => LocalDate.parse(iso);

Task task(String id, {Difficulty diff = Difficulty.orta}) => Task(
  id: id,
  title: id,
  note: '',
  schedule: [ScheduleSegment(d('2026-10-01'), const DailyRule())],
  createdAt: DateTime.utc(2026),
  order: 0,
  difficulty: diff,
);

/// First date from 2026-11-01 whose quest is [kind] (with a hard task).
LocalDate dateFor(QuestKind kind, TaskData data) {
  var x = d('2026-11-01');
  while (QuestBook.kindFor(data, x) != kind) {
    x = x.addDays(1);
  }
  return x;
}

DateTime atHour(LocalDate day, int hour) =>
    DateTime(day.year, day.month, day.day, hour);

void main() {
  final withHard = TaskData(
    tasks: [
      task('a'),
      task('b'),
      task('c'),
      task('z', diff: Difficulty.zor),
    ],
  );

  test('the same date always gets the same quest; four days cover all', () {
    final kinds = {
      for (var i = 0; i < 4; i++)
        QuestBook.kindFor(withHard, d('2026-11-01').addDays(i)),
    };
    expect(kinds, QuestKind.values.toSet());
    expect(
      QuestBook.kindFor(withHard, d('2026-11-05')),
      QuestBook.kindFor(withHard, d('2026-11-05')),
    );
  });

  test('a hard-task quest without a hard task becomes "3 görev bitir"', () {
    final noHard = TaskData(tasks: [task('a')]);
    final day = dateFor(QuestKind.hard1, withHard);
    expect(QuestBook.kindFor(noHard, day), QuestKind.count3);
  });

  test('count3 counts only ticks made on their own day', () {
    final day = dateFor(QuestKind.count3, withHard);
    var data = withHard
        .withTick('a', day, atHour(day, 9))
        .withTick('b', day, atHour(day, 10))
        .withTick('c', day, atHour(day.addDays(1), 9)); // late
    expect(QuestBook.dayOf(data, day).progress, 2);
    expect(QuestBook.dayOf(data, day).done, isFalse);
    data = data.withTick('z', day, atHour(day, 20));
    expect(QuestBook.dayOf(data, day).done, isTrue);
  });

  test('early2 needs two ticks before noon', () {
    final day = dateFor(QuestKind.early2, withHard);
    final data = withHard
        .withTick('a', day, atHour(day, 9))
        .withTick('b', day, atHour(day, 13));
    expect(QuestBook.dayOf(data, day).progress, 1);
    final data2 = data.withTick('c', day, atHour(day, 11));
    expect(QuestBook.dayOf(data2, day).done, isTrue);
  });

  test('perfect needs every expected task; an empty day is never done', () {
    final day = dateFor(QuestKind.perfect, withHard);
    var data = withHard;
    for (final id in ['a', 'b', 'c']) {
      data = data.withTick(id, day, atHour(day, 9));
    }
    expect(QuestBook.dayOf(data, day).done, isFalse);
    data = data.withTick('z', day, atHour(day, 9));
    expect(QuestBook.dayOf(data, day).done, isTrue);
    final empty = QuestBook.dayOf(TaskData(), day);
    expect(empty.goal, 0);
    expect(empty.done, isFalse);
  });

  test('gold sums quest rewards and the weekly challenge', () {
    // One task, every day of the week of 2026-11-02 ticked on time.
    final one = TaskData(tasks: [task('a')]);
    var data = one;
    final monday = d('2026-11-02');
    for (var i = 0; i < 7; i++) {
      final day = monday.addDays(i);
      data = data.withTick('a', day, atHour(day, 9));
    }
    final book = QuestBook.of(data, d('2026-11-08'));
    var expected = 0;
    for (
      var day = d('2026-10-01');
      !day.isAfter(d('2026-11-08'));
      day = day.addDays(1)
    ) {
      final q = QuestBook.dayOf(data, day);
      if (q.done) expected += q.kind.reward;
    }
    expect(book.gold, expected + WeekChallenge.reward);
    expect(book.week.progress, 7);
    expect(book.week.done, isTrue);
    expect(QuestBook.of(one, d('2026-11-08')).gold, 0);
  });

  test('day ratio is unknown on an empty day', () {
    expect(QuestBook.dayRatio(TaskData(), d('2026-11-01')), isNull);
    final data = TaskData(tasks: [task('a'), task('b')])
        .withTick('a', d('2026-11-01'), atHour(d('2026-11-01'), 9));
    expect(QuestBook.dayRatio(data, d('2026-11-01')), 0.5);
  });

  test('exactly five perfect days earn the weekly reward, four do not', () {
    final one = TaskData(tasks: [task('a')]);
    int questGold(TaskData data) {
      var g = 0;
      for (
        var day = d('2026-10-01');
        !day.isAfter(d('2026-11-08'));
        day = day.addDays(1)
      ) {
        final q = QuestBook.dayOf(data, day);
        if (q.done) g += q.kind.reward;
      }
      return g;
    }

    var data = one;
    for (var i = 0; i < 4; i++) {
      final day = d('2026-11-02').addDays(i);
      data = data.withTick('a', day, atHour(day, 9));
    }
    expect(QuestBook.of(data, d('2026-11-08')).gold, questGold(data));
    final day5 = d('2026-11-06');
    data = data.withTick('a', day5, atHour(day5, 9));
    expect(
      QuestBook.of(data, d('2026-11-08')).gold,
      questGold(data) + WeekChallenge.reward,
    );
  });
}
