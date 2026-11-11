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

const List<String> monthNamesEn = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

/// Index 0 = Monday.
const List<String> weekdayNamesEn = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

/// Index 0 = Monday.
const List<String> weekdayShortEn = [
  'Mon',
  'Tue',
  'Wed',
  'Thu',
  'Fri',
  'Sat',
  'Sun',
];

String weekdayName(LocalDate d, {bool en = false}) =>
    (en ? weekdayNamesEn : weekdayNames)[d.weekday - 1];

String weekdayAbbr(int weekday, {bool en = false}) =>
    (en ? weekdayShortEn : weekdayShort)[weekday - 1];

/// "7 Kasım 2026" / "November 7, 2026"
String longDate(LocalDate d, {bool en = false}) => en
    ? '${monthNamesEn[d.month - 1]} ${d.day}, ${d.year}'
    : '${d.day} ${monthNames[d.month - 1]} ${d.year}';

/// "7 Kasım" / "November 7"
String shortDate(LocalDate d, {bool en = false}) => en
    ? '${monthNamesEn[d.month - 1]} ${d.day}'
    : '${d.day} ${monthNames[d.month - 1]}';

/// "Bugün", "Dün", "Yarın", or the weekday name (English when [en]).
String relativeDay(LocalDate d, LocalDate today, {bool en = false}) {
  switch (today.daysUntil(d)) {
    case 0:
      return en ? 'Today' : 'Bugün';
    case -1:
      return en ? 'Yesterday' : 'Dün';
    case 1:
      return en ? 'Tomorrow' : 'Yarın';
    default:
      return weekdayName(d, en: en);
  }
}

/// "Her gün", "Pzt, Çar, Cum", "Hafta içi", "Hafta sonu", "Tek sefer: 7 Kasım"
/// (English when [en]).
String describeRule(RepeatRule rule, {bool en = false}) => switch (rule) {
  DailyRule() => en ? 'Every day' : 'Her gün',
  WeeklyRule(:final weekdays) when weekdays.length == 7 =>
    en ? 'Every day' : 'Her gün',
  WeeklyRule(:final weekdays)
      when weekdays.length == 5 &&
          !weekdays.contains(6) &&
          !weekdays.contains(7) =>
    en ? 'Weekdays' : 'Hafta içi',
  WeeklyRule(:final weekdays)
      when weekdays.length == 2 &&
          weekdays.contains(6) &&
          weekdays.contains(7) =>
    en ? 'Weekends' : 'Hafta sonu',
  final WeeklyRule w => [
    for (final d in w.sortedDays) weekdayAbbr(d, en: en),
  ].join(', '),
  OnceRule(:final date) =>
    en ? 'Once: ${shortDate(date, en: true)}' : 'Tek sefer: ${shortDate(date)}',
};

/// "14:05" in the device's time.
String clockTime(DateTime moment) {
  final l = moment.toLocal();
  return '${l.hour.toString().padLeft(2, '0')}:${l.minute.toString().padLeft(2, '0')}';
}
