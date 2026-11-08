import 'local_date.dart';
import 'task.dart';
import 'task_data.dart';

/// Daily quests, the weekly challenge and gold (Altın), computed from the
/// ticks alone, like XP. Only ticks made on their own day count for quests,
/// so a past day cannot be farmed afterwards.
enum QuestKind {
  count3('3 görev bitir', 3, 20),
  early2('Öğleden önce 2 görev bitir', 2, 25),
  perfect('Bugünün tüm görevlerini bitir', 0, 30),
  hard1('Bir zor görev bitir', 1, 30);

  const QuestKind(this.title, this.fixedGoal, this.reward);
  final String title;

  /// 0 means "every expected task of the day".
  final int fixedGoal;
  final int reward;
}

class QuestDay {
  const QuestDay({
    required this.date,
    required this.kind,
    required this.progress,
    required this.goal,
  });

  final LocalDate date;
  final QuestKind kind;
  final int progress;
  final int goal;

  bool get done => goal > 0 && progress >= goal;
}

class WeekChallenge {
  const WeekChallenge({required this.monday, required this.progress});

  static const int goal = 5;
  static const int reward = 100;
  static const String title = 'Bu hafta 5 mükemmel gün';

  final LocalDate monday;
  final int progress;

  bool get done => progress >= goal;
}

class QuestBook {
  const QuestBook({
    required this.today,
    required this.week,
    required this.gold,
    required this.questsDone,
  });

  final QuestDay today;
  final WeekChallenge week;
  final int gold;
  final int questsDone;

  /// The quest for [date]: the same date always gets the same quest. A
  /// "hard task" quest on a day without an expected hard task becomes
  /// "3 görev bitir".
  static QuestKind kindFor(TaskData data, LocalDate date) {
    final epochDay = LocalDate(1970, 1, 1).daysUntil(date);
    var kind = QuestKind.values[epochDay % QuestKind.values.length];
    if (kind == QuestKind.hard1 &&
        !data.tasksOn(date).any((t) => t.difficulty == Difficulty.zor)) {
      kind = QuestKind.count3;
    }
    return kind;
  }

  static QuestDay dayOf(TaskData data, LocalDate date) {
    final kind = kindFor(data, date);
    final expected = data.tasksOn(date);
    bool onTime(Task t) {
      final at = data.doneAt(t.id, date);
      return at != null && LocalDate.of(at) == date;
    }

    final done = expected.where(onTime).toList();
    final int progress;
    final int goal;
    switch (kind) {
      case QuestKind.count3:
        progress = done.length;
        goal = 3;
      case QuestKind.early2:
        progress = done
            .where((t) => data.doneAt(t.id, date)!.toLocal().hour < 12)
            .length;
        goal = 2;
      case QuestKind.perfect:
        progress = done.length;
        goal = expected.length;
      case QuestKind.hard1:
        progress = done.where((t) => t.difficulty == Difficulty.zor).length;
        goal = 1;
    }
    return QuestDay(date: date, kind: kind, progress: progress, goal: goal);
  }

  static bool _perfect(TaskData data, LocalDate d) {
    final expected = data.tasksOn(d);
    return expected.isNotEmpty && expected.every((t) => data.isDone(t.id, d));
  }

  static QuestBook of(TaskData data, LocalDate today) {
    LocalDate? earliest;
    for (final t in data.tasks) {
      if (earliest == null || t.startDate.isBefore(earliest)) {
        earliest = t.startDate;
      }
      for (final d in data.completions[t.id]?.keys ?? const <LocalDate>[]) {
        if (d.isBefore(earliest!)) earliest = d;
      }
    }
    var gold = 0;
    var questsDone = 0;
    final weekPerfect = <LocalDate, int>{};
    if (earliest != null) {
      for (var d = earliest; !d.isAfter(today); d = d.addDays(1)) {
        final q = dayOf(data, d);
        if (q.done) {
          gold += q.kind.reward;
          questsDone++;
        }
        if (_perfect(data, d)) {
          final monday = d.addDays(1 - d.weekday);
          weekPerfect[monday] = (weekPerfect[monday] ?? 0) + 1;
        }
      }
    }
    for (final count in weekPerfect.values) {
      if (count >= WeekChallenge.goal) gold += WeekChallenge.reward;
    }
    final monday = today.addDays(1 - today.weekday);
    return QuestBook(
      today: dayOf(data, today),
      week: WeekChallenge(monday: monday, progress: weekPerfect[monday] ?? 0),
      gold: gold,
      questsDone: questsDone,
    );
  }

  /// Share of expected tasks done on [date], or null when nothing was
  /// expected (an empty day is not a bad day).
  static double? dayRatio(TaskData data, LocalDate date) {
    final expected = data.tasksOn(date);
    if (expected.isEmpty) return null;
    return expected.where((t) => data.isDone(t.id, date)).length /
        expected.length;
  }
}
