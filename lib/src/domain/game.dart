import 'local_date.dart';
import 'task.dart';
import 'task_data.dart';

/// XP, level, stats and badges, computed from the ticks alone.
///
/// Nothing here is stored: the same history always gives the same profile,
/// so deleting a task takes its XP with it and no number can drift. A tick
/// made on a later day ("sonradan işaretlendi") earns only the base XP.
class GameRules {
  const GameRules._();

  /// Extra XP when a day is ticked on that same day.
  static const int onTimeBonus = 5;

  /// Extra XP per day of the task's current streak, up to [streakBonusCap].
  static const int streakBonusPerDay = 2;
  static const int streakBonusCap = 20;

  /// Extra XP for a day on which every expected task was ticked.
  static const int perfectDayBonus = 25;

  /// XP needed to go from [level] to the next one.
  static int xpForNext(int level) => 100 + 40 * (level - 1);

  /// XP for one ticked day of a task.
  static int xpFor({
    required Difficulty difficulty,
    required bool onTime,
    required int streak,
  }) {
    final bonus = streak * streakBonusPerDay;
    return difficulty.baseXp +
        (onTime ? onTimeBonus : 0) +
        (onTime ? (bonus > streakBonusCap ? streakBonusCap : bonus) : 0);
  }

  static const List<(int, String)> titles = [
    (1, 'Çaylak'),
    (3, 'Çırak'),
    (5, 'Yolcu'),
    (8, 'Savaşçı'),
    (12, 'Şövalye'),
    (17, 'Usta'),
    (23, 'Kahraman'),
    (30, 'Efsane'),
    (40, 'Ölümsüz'),
  ];

  static String titleFor(int level) {
    var title = titles.first.$2;
    for (final (min, name) in titles) {
      if (level >= min) title = name;
    }
    return title;
  }
}

class GameBadge {
  const GameBadge({
    required this.id,
    required this.name,
    required this.description,
    required this.progress,
    required this.goal,
  });

  final String id;
  final String name;
  final String description;
  final int progress;
  final int goal;

  bool get unlocked => progress >= goal;
}

class GameProfile {
  const GameProfile({
    required this.totalXp,
    required this.xpToday,
    required this.level,
    required this.xpIntoLevel,
    required this.xpForNext,
    required this.willpower,
    required this.discipline,
    required this.endurance,
    required this.courage,
    required this.focus,
    required this.totalDone,
    required this.badges,
  });

  final int totalXp;

  /// XP earned by ticks of today and today's perfect day bonus.
  final int xpToday;
  final int level;
  final int xpIntoLevel;
  final int xpForNext;

  /// İrade: days on which every expected task was ticked.
  final int willpower;

  /// Disiplin: % of settled days done in the last 30 days, or null when
  /// nothing was settled yet (unknown ≠ 0).
  final int? discipline;

  /// Dayanıklılık: the longest streak any task ever had.
  final int endurance;

  /// Cesaret: ticked days of hard (zor) tasks.
  final int courage;

  /// Odak: % of ticks made on their own day, or null without ticks.
  final int? focus;

  /// Toplam başarı: all ticked days.
  final int totalDone;

  final List<GameBadge> badges;

  String get title => GameRules.titleFor(level);

  int get unlockedBadges => badges.where((b) => b.unlocked).length;

  static GameProfile of(TaskData data, LocalDate today) {
    var totalXp = 0;
    var xpToday = 0;
    var totalDone = 0;
    var onTime = 0;
    var courage = 0;
    var endurance = 0;

    LocalDate? earliest;
    for (final t in data.tasks) {
      final start = t.startDate;
      if (earliest == null || start.isBefore(earliest)) earliest = start;
      for (final d in data.completions[t.id]?.keys ?? const <LocalDate>[]) {
        if (d.isBefore(earliest!)) earliest = d;
      }
    }

    // Per task: walk the days in order, carrying the streak.
    for (final t in data.tasks) {
      var streak = 0;
      var best = 0;
      var first = t.startDate;
      for (final d in data.completions[t.id]?.keys ?? const <LocalDate>[]) {
        if (d.isBefore(first)) first = d;
      }
      for (var d = first; !d.isAfter(today); d = d.addDays(1)) {
        switch (data.statusOf(t, d, today)) {
          case DayStatus.done:
            streak++;
            if (streak > best) best = streak;
            final at = data.doneAt(t.id, d)!;
            final sameDay = LocalDate.of(at) == d;
            final xp = GameRules.xpFor(
              difficulty: t.difficulty,
              onTime: sameDay,
              streak: streak - 1,
            );
            totalXp += xp;
            if (d == today) xpToday += xp;
            totalDone++;
            if (sameDay) onTime++;
            if (t.difficulty == Difficulty.zor) courage++;
          case DayStatus.missed:
            streak = 0;
          case DayStatus.pending:
          case DayStatus.upcoming:
          case DayStatus.notScheduled:
            break;
        }
      }
      if (best > endurance) endurance = best;
    }

    // Perfect days, and the longest run of them.
    var perfect = 0;
    var perfectRun = 0;
    var bestPerfectRun = 0;
    if (earliest != null) {
      for (var d = earliest; !d.isAfter(today); d = d.addDays(1)) {
        final expected = data.tasksOn(d);
        if (expected.isEmpty) continue;
        if (expected.every((t) => data.isDone(t.id, d))) {
          perfect++;
          perfectRun++;
          if (perfectRun > bestPerfectRun) bestPerfectRun = perfectRun;
          totalXp += GameRules.perfectDayBonus;
          if (d == today) xpToday += GameRules.perfectDayBonus;
        } else {
          perfectRun = 0;
        }
      }
    }

    // Discipline over the last 30 days.
    var done30 = 0;
    var settled30 = 0;
    for (final t in data.tasks) {
      final s = data.statsFor(
        t,
        from: today.addDays(-29),
        to: today,
        today: today,
      );
      done30 += s.done;
      settled30 += s.settled;
    }

    var level = 1;
    var rest = totalXp;
    while (rest >= GameRules.xpForNext(level)) {
      rest -= GameRules.xpForNext(level);
      level++;
    }

    GameBadge b(String id, String name, String desc, int progress, int goal) =>
        GameBadge(
          id: id,
          name: name,
          description: desc,
          progress: progress > goal ? goal : progress,
          goal: goal,
        );

    return GameProfile(
      totalXp: totalXp,
      xpToday: xpToday,
      level: level,
      xpIntoLevel: rest,
      xpForNext: GameRules.xpForNext(level),
      willpower: perfect,
      discipline: settled30 == 0 ? null : (100 * done30 / settled30).round(),
      endurance: endurance,
      courage: courage,
      focus: totalDone == 0 ? null : (100 * onTime / totalDone).round(),
      totalDone: totalDone,
      badges: [
        b('ilk-adim', 'İlk Adım', 'İlk görevini işaretle', totalDone, 1),
        b('isinma', 'Isınma', 'Bir görevde 3 günlük seri', endurance, 3),
        b(
          'hafta',
          'Haftalık Savaşçı',
          'Bir görevde 7 günlük seri',
          endurance,
          7,
        ),
        b('ay', 'Ayın Efsanesi', 'Bir görevde 30 günlük seri', endurance, 30),
        b(
          'mukemmel',
          'Mükemmel Gün',
          'Bir günün tüm görevlerini bitir',
          perfect,
          1,
        ),
        b(
          'mukemmel-hafta',
          'Kusursuz Hafta',
          'Üst üste 7 mükemmel gün',
          bestPerfectRun,
          7,
        ),
        b('irade', 'Demir İrade', '30 mükemmel gün', perfect, 30),
        b('cesur', 'Cesur Yürek', '10 kez zor görev bitir', courage, 10),
        b(
          'erkenci',
          'Zamanında',
          '50 görevi kendi gününde işaretle',
          onTime,
          50,
        ),
        b('yuzler', 'Yüzler Kulübü', '100 görev başar', totalDone, 100),
        b('bin', 'Bin Adım', '1000 görev başar', totalDone, 1000),
        b('sv5', 'Yolcu', '5. seviyeye ulaş', level, 5),
        b('sv12', 'Şövalye', '12. seviyeye ulaş', level, 12),
        b('sv23', 'Kahraman', '23. seviyeye ulaş', level, 23),
      ],
    );
  }
}
