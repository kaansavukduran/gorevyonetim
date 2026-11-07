import 'local_date.dart';
import 'repeat_rule.dart';

const List<String> monthNames = [
  'Ocak',
  'Şubat',
  'Mart',
  'Nisan',
  'Mayıs',
  'Haziran',
  'Temmuz',
  'Ağustos',
  'Eylül',
  'Ekim',
  'Kasım',
  'Aralık',
];

/// Index 0 = Monday.
const List<String> weekdayNames = [
  'Pazartesi',
  'Salı',
  'Çarşamba',
  'Perşembe',
  'Cuma',
  'Cumartesi',
  'Pazar',
];

/// Index 0 = Monday.
const List<String> weekdayShort = [
  'Pzt',
  'Sal',
  'Çar',
  'Per',
  'Cum',
  'Cmt',
  'Paz',
];

String weekdayName(LocalDate d) => weekdayNames[d.weekday - 1];

/// "7 Kasım 2026"
String longDate(LocalDate d) => '${d.day} ${monthNames[d.month - 1]} ${d.year}';

/// "7 Kasım"
String shortDate(LocalDate d) => '${d.day} ${monthNames[d.month - 1]}';

/// "Bugün", "Dün", "Yarın", or the weekday name.
String relativeDay(LocalDate d, LocalDate today) {
  switch (today.daysUntil(d)) {
    case 0:
      return 'Bugün';
    case -1:
      return 'Dün';
    case 1:
      return 'Yarın';
    default:
      return weekdayName(d);
  }
}

/// "Her gün", "Pzt, Çar, Cum", "Hafta içi", "Hafta sonu", "Tek sefer: 7 Kasım"
String describeRule(RepeatRule rule) => switch (rule) {
  DailyRule() => 'Her gün',
  WeeklyRule(:final weekdays) when weekdays.length == 7 => 'Her gün',
  WeeklyRule(:final weekdays)
      when weekdays.length == 5 &&
          !weekdays.contains(6) &&
          !weekdays.contains(7) =>
    'Hafta içi',
  WeeklyRule(:final weekdays)
      when weekdays.length == 2 &&
          weekdays.contains(6) &&
          weekdays.contains(7) =>
    'Hafta sonu',
  final WeeklyRule w => [
    for (final d in w.sortedDays) weekdayShort[d - 1],
  ].join(', '),
  OnceRule(:final date) => 'Tek sefer: ${shortDate(date)}',
};

/// "14:05" in the device's time.
String clockTime(DateTime moment) {
  final l = moment.toLocal();
  return '${l.hour.toString().padLeft(2, '0')}:${l.minute.toString().padLeft(2, '0')}';
}
