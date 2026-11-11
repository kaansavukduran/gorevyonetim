import 'package:flutter/widgets.dart';

import 'l10n_en.dart';

/// The app's language for the widgets below it.
///
/// Texts are written in Turkish in the code and looked up in one central
/// English table ([enStrings]) when English is chosen; a text missing from
/// the table falls back to Turkish (a test lists every wrapped text without
/// an English entry, so nothing is left half translated by accident).
/// Placeholders are written `{name}` and filled from [args].
class L10n extends InheritedWidget {
  const L10n({super.key, required this.english, required super.child});

  final bool english;

  static L10n of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<L10n>() ??
      const L10n(english: false, child: SizedBox.shrink());

  String t(String turkish, [Map<String, Object?> args = const {}]) {
    var s = english ? (enStrings[turkish] ?? turkish) : turkish;
    for (final e in args.entries) {
      s = s.replaceAll('{${e.key}}', '${e.value}');
    }
    return s;
  }

  @override
  bool updateShouldNotify(L10n old) => old.english != english;

  /// 'system' follows the device language when it is English, else Turkish.
  static bool resolveEnglish(String setting, Locale device) =>
      setting == 'en' || (setting == 'system' && device.languageCode == 'en');
}

extension L10nContext on BuildContext {
  String t(String turkish, [Map<String, Object?> args = const {}]) =>
      L10n.of(this).t(turkish, args);

  bool get isEnglish => L10n.of(this).english;

  /// "%40" in Turkish, "40%" in English.
  String percent(num value) => isEnglish ? '$value%' : '%$value';
}
