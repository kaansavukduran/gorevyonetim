import 'dart:convert';

import 'theme_customization.dart';

/// Choices that belong to this device, kept apart from the tasks.
class AppSettings {
  const AppSettings({
    this.themeId = 'diyar',
    this.gameMode = true,
    this.charClass = 'savasci',
    this.uiScale = 1.0,
    this.sortByTime = false,
    this.customTheme = const ThemeCustomization(),
    this.dailyGoal = 3,
    this.celebrationEffects = true,
  });

  /// One of the ids in `appThemes` (unknown ids fall back to the default).
  final String themeId;

  /// XP, levels, stats and badges on screen. Off shows a plain list.
  final bool gameMode;

  /// Cosmetic character class (emblem and motto only; no rule changes).
  final String charClass;

  /// Whole-interface zoom, independent of the operating system's text size.
  final double uiScale;
  final bool sortByTime;
  final ThemeCustomization customTheme;
  final int dailyGoal;
  final bool celebrationEffects;

  static const minScale = 0.8;
  static const maxScale = 2.0;

  double get safeScale =>
      uiScale.isFinite ? uiScale.clamp(minScale, maxScale) : 1.0;

  AppSettings copyWith({
    String? themeId,
    bool? gameMode,
    String? charClass,
    double? uiScale,
    bool? sortByTime,
    ThemeCustomization? customTheme,
    int? dailyGoal,
    bool? celebrationEffects,
  }) => AppSettings(
    themeId: themeId ?? this.themeId,
    gameMode: gameMode ?? this.gameMode,
    charClass: charClass ?? this.charClass,
    uiScale: uiScale ?? this.uiScale,
    sortByTime: sortByTime ?? this.sortByTime,
    customTheme: customTheme ?? this.customTheme,
    dailyGoal: (dailyGoal ?? this.dailyGoal).clamp(1, 20),
    celebrationEffects: celebrationEffects ?? this.celebrationEffects,
  );

  String encode() => const JsonEncoder.withIndent('  ').convert({
    'theme': themeId,
    'game_mode': gameMode,
    'class': charClass,
    'ui_scale': safeScale,
    'sort_by_time': sortByTime,
    'custom_theme': customTheme.toJson(),
    'daily_goal': dailyGoal.clamp(1, 20),
    'celebration_effects': celebrationEffects,
  });

  /// Reads settings; anything missing or malformed falls back to defaults
  /// (settings are a convenience, never a reason to refuse to start).
  static AppSettings decode(String text) {
    try {
      final j = jsonDecode(text);
      if (j is! Map<String, Object?>) return const AppSettings();
      return AppSettings(
        themeId: j['theme'] is String ? j['theme']! as String : 'diyar',
        gameMode: j['game_mode'] is bool ? j['game_mode']! as bool : true,
        charClass: j['class'] is String ? j['class']! as String : 'savasci',
        uiScale: j['ui_scale'] is num && (j['ui_scale']! as num).isFinite
            ? (j['ui_scale']! as num).toDouble().clamp(minScale, maxScale)
            : 1.0,
        sortByTime: j['sort_by_time'] is bool
            ? j['sort_by_time']! as bool
            : false,
        customTheme: ThemeCustomization.fromJson(j['custom_theme']),
        dailyGoal: j['daily_goal'] is int
            ? (j['daily_goal']! as int).clamp(1, 20)
            : 3,
        celebrationEffects: j['celebration_effects'] is bool
            ? j['celebration_effects']! as bool
            : true,
      );
    } on FormatException {
      return const AppSettings();
    }
  }
}
