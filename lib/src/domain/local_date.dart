/// A calendar day without a time or a time zone.
///
/// Arithmetic runs on UTC midnights, so a clock change (DST) never makes a
/// day 23 or 25 hours long and never skips or repeats a date.
class LocalDate implements Comparable<LocalDate> {
  LocalDate(int year, int month, int day)
    : this._fromUtc(DateTime.utc(year, month, day));

  LocalDate._fromUtc(DateTime utc)
    : year = utc.year,
      month = utc.month,
      day = utc.day;

  /// The calendar day of [moment] in the device's time zone.
  factory LocalDate.of(DateTime moment) {
    final local = moment.toLocal();
    return LocalDate(local.year, local.month, local.day);
  }

  /// Parses `YYYY-MM-DD`. Throws [FormatException] for anything else,
  /// including dates that do not exist (2026-02-30).
  factory LocalDate.parse(String text) {
    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(text);
    if (match == null) {
      throw FormatException('Tarih YYYY-AA-GG biçiminde olmalı', text);
    }
    final y = int.parse(match.group(1)!);
    final m = int.parse(match.group(2)!);
    final d = int.parse(match.group(3)!);
    final date = LocalDate(y, m, d);
    if (date.year != y || date.month != m || date.day != d) {
      throw FormatException('Böyle bir gün yok', text);
    }
    return date;
  }

  final int year;
  final int month;
  final int day;

  DateTime get _utc => DateTime.utc(year, month, day);

  /// 1 = Monday … 7 = Sunday (ISO 8601, as in [DateTime.weekday]).
  int get weekday => _utc.weekday;

  LocalDate addDays(int days) =>
      LocalDate._fromUtc(_utc.add(Duration(days: days)));

  /// Whole days from this date to [other] (negative when [other] is earlier).
  int daysUntil(LocalDate other) => other._utc.difference(_utc).inDays;

  bool isBefore(LocalDate other) => compareTo(other) < 0;
  bool isAfter(LocalDate other) => compareTo(other) > 0;

  String toIso() =>
      '${year.toString().padLeft(4, '0')}-'
      '${month.toString().padLeft(2, '0')}-'
      '${day.toString().padLeft(2, '0')}';

  @override
  int compareTo(LocalDate other) {
    if (year != other.year) return year.compareTo(other.year);
    if (month != other.month) return month.compareTo(other.month);
    return day.compareTo(other.day);
  }

  @override
  bool operator ==(Object other) =>
      other is LocalDate &&
      other.year == year &&
      other.month == month &&
      other.day == day;

  @override
  int get hashCode => Object.hash(year, month, day);

  @override
  String toString() => toIso();
}
