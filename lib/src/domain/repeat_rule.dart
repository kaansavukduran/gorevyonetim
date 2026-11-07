import 'local_date.dart';

/// On which days a task is expected.
sealed class RepeatRule {
  const RepeatRule();

  /// Whether the rule itself lands on [date] (start and end dates of the
  /// task are checked by the task, not here).
  bool matches(LocalDate date);

  Map<String, Object?> toJson();

  static RepeatRule fromJson(Object? json) {
    if (json is! Map<String, Object?>) {
      throw const FormatException('Tekrar kuralı bir nesne olmalı');
    }
    switch (json['type']) {
      case 'daily':
        return const DailyRule();
      case 'weekly':
        final raw = json['weekdays'];
        if (raw is! List<Object?>) {
          throw const FormatException('Haftalık kural gün listesi içermeli');
        }
        final days = <int>{};
        for (final d in raw) {
          if (d is! int || d < 1 || d > 7) {
            throw FormatException('Geçersiz hafta günü', d);
          }
          days.add(d);
        }
        return WeeklyRule(days);
      case 'once':
        final date = json['date'];
        if (date is! String) {
          throw const FormatException('Tek seferlik görevin tarihi yok');
        }
        return OnceRule(LocalDate.parse(date));
      default:
        throw FormatException('Bilinmeyen tekrar türü', json['type']);
    }
  }
}

/// Every day.
class DailyRule extends RepeatRule {
  const DailyRule();

  @override
  bool matches(LocalDate date) => true;

  @override
  Map<String, Object?> toJson() => {'type': 'daily'};

  @override
  bool operator ==(Object other) => other is DailyRule;

  @override
  int get hashCode => 0;
}

/// Chosen days of the week (1 = Monday … 7 = Sunday). At least one day.
class WeeklyRule extends RepeatRule {
  WeeklyRule(Set<int> weekdays) : weekdays = Set.unmodifiable(weekdays) {
    if (weekdays.isEmpty) {
      throw ArgumentError('En az bir gün seçilmeli');
    }
    if (weekdays.any((d) => d < 1 || d > 7)) {
      throw ArgumentError('Hafta günü 1 ile 7 arasında olmalı');
    }
  }

  final Set<int> weekdays;

  List<int> get sortedDays => weekdays.toList()..sort();

  @override
  bool matches(LocalDate date) => weekdays.contains(date.weekday);

  @override
  Map<String, Object?> toJson() => {'type': 'weekly', 'weekdays': sortedDays};

  @override
  bool operator ==(Object other) =>
      other is WeeklyRule &&
      other.weekdays.length == weekdays.length &&
      other.weekdays.containsAll(weekdays);

  @override
  int get hashCode => Object.hashAllUnordered(weekdays);
}

/// A single day.
class OnceRule extends RepeatRule {
  const OnceRule(this.date);

  final LocalDate date;

  @override
  bool matches(LocalDate date) => date == this.date;

  @override
  Map<String, Object?> toJson() => {'type': 'once', 'date': date.toIso()};

  @override
  bool operator ==(Object other) => other is OnceRule && other.date == date;

  @override
  int get hashCode => date.hashCode;
}
