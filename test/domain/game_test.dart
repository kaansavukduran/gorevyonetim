import 'package:flutter_test/flutter_test.dart';
import 'package:gunluk_gorevler/src/domain/game.dart';
import 'package:gunluk_gorevler/src/domain/local_date.dart';
import 'package:gunluk_gorevler/src/domain/repeat_rule.dart';
import 'package:gunluk_gorevler/src/domain/task.dart';
import 'package:gunluk_gorevler/src/domain/task_data.dart';

LocalDate d(String iso) => LocalDate.parse(iso);

/// Ticked at noon of [day] (on time) or of the day after (late).
DateTime at(String day, {bool late = false}) {
  final x = d(day).addDays(late ? 1 : 0);
  return DateTime(x.year, x.month, x.day, 12);
}

Task task(
  String id, {
  Difficulty difficulty = Difficulty.orta,
  RepeatRule rule = const DailyRule(),
  String start = '2026-11-01',
}) => Task(
  id: id,
  title: 'Görev $id',
  note: '',
  schedule: [ScheduleSegment(d(start), rule)],
  createdAt: DateTime.utc(2026, 11, 1),
  order: 0,
  difficulty: difficulty,
);

void main() {
  final today = d('2026-11-07');

  test('XP per tick: base by difficulty, on-time and capped streak bonus', () {
    expect(
      GameRules.xpFor(difficulty: Difficulty.kolay, onTime: true, streak: 0),
      15,
    );
    expect(
      GameRules.xpFor(difficulty: Difficulty.zor, onTime: true, streak: 3),
      35 + 5 + 6,
    );
    expect(
      GameRules.xpFor(difficulty: Difficulty.orta, onTime: true, streak: 50),
      20 + 5 + 20,
    );
    // A late tick earns the base only.
    expect(
      GameRules.xpFor(difficulty: Difficulty.orta, onTime: false, streak: 5),
      20,
    );
  });

  test('levels follow the curve and titles follow levels', () {
    expect(GameRules.xpForNext(1), 100);
    expect(GameRules.xpForNext(2), 140);
    expect(GameRules.titleFor(1), 'Çaylak');
    expect(GameRules.titleFor(8), 'Savaşçı');
    expect(GameRules.titleFor(99), 'Ölümsüz');
  });

  test('an empty history is level 1 with unknown percentages', () {
    final p = GameProfile.of(TaskData(), today);
    expect(p.level, 1);
    expect(p.totalXp, 0);
    expect(p.discipline, isNull);
    expect(p.focus, isNull);
    expect(p.badges.every((b) => !b.unlocked), isTrue);
  });

  test('streak, perfect days and XP add up from the history', () {
    var data = TaskData(tasks: [task('a', start: '2026-11-05')]);
    data = data
        .withTick('a', d('2026-11-05'), at('2026-11-05'))
        .withTick('a', d('2026-11-06'), at('2026-11-06'));
    final p = GameProfile.of(data, today);
    // Day 1: 20+5+0 = 25, day 2: 20+5+2 = 27, two perfect days: 2*25.
    expect(p.totalXp, 25 + 27 + 50);
    expect(p.willpower, 2);
    expect(p.endurance, 2);
    expect(p.totalDone, 2);
    expect(p.focus, 100);
    expect(p.discipline, 100); // today is pending, not settled
    expect(p.xpToday, 0);
    expect(p.level, 2);
    expect(p.xpIntoLevel, 2);
  });

  test('a late tick earns base XP only and lowers focus', () {
    final data = TaskData(tasks: [task('a', start: '2026-11-06')])
        .withTick('a', d('2026-11-06'), at('2026-11-06', late: true));
    final p = GameProfile.of(data, today);
    expect(p.totalXp, 20 + 25);
    expect(p.focus, 0);
  });

  test('a missed day breaks the streak and the perfect-day run', () {
    var data = TaskData(tasks: [task('a', start: '2026-11-04')]);
    data = data
        .withTick('a', d('2026-11-04'), at('2026-11-04'))
        .withTick('a', d('2026-11-06'), at('2026-11-06'));
    final p = GameProfile.of(data, today);
    expect(p.endurance, 1);
    expect(p.willpower, 2);
    expect(p.discipline, 67);
    // Both ticks have streak 0: 2 * 25, plus 2 perfect days.
    expect(p.totalXp, 50 + 50);
  });

  test('today counts as soon as it is complete', () {
    final data = TaskData(tasks: [task('a', start: '2026-11-07')])
        .withTick('a', today, at('2026-11-07'));
    final p = GameProfile.of(data, today);
    expect(p.xpToday, 25 + 25);
    expect(p.willpower, 1);
  });

  test('hard tasks raise courage; deleting a task takes its XP', () {
    final data = TaskData(
      tasks: [task('z', difficulty: Difficulty.zor, start: '2026-11-07')],
    ).withTick('z', today, at('2026-11-07'));
    expect(GameProfile.of(data, today).courage, 1);
    expect(GameProfile.of(data.withoutTask('z'), today).totalXp, 0);
  });

  test('badges open when their goal is reached', () {
    var data = TaskData(tasks: [task('a', start: '2026-10-31')]);
    for (var i = 0; i < 7; i++) {
      final day = d('2026-10-31').addDays(i).toIso();
      data = data.withTick('a', d(day), at(day));
    }
    final p = GameProfile.of(data, today);
    bool open(String id) => p.badges.firstWhere((b) => b.id == id).unlocked;
    expect(open('ilk-adim'), isTrue);
    expect(open('isinma'), isTrue);
    expect(open('hafta'), isTrue);
    expect(open('mukemmel-hafta'), isTrue);
    expect(open('ay'), isFalse);
    expect(p.badges.firstWhere((b) => b.id == 'ay').progress, 7);
  });
}
