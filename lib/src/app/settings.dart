import 'dart:convert';

/// Choices that belong to this device, kept apart from the tasks.
class AppSettings {
  const AppSettings({
    this.themeId = 'diyar',
    this.gameMode = true,
    this.charClass = 'savasci',
    this.uiScale = 1.0,
  });

  /// One of the ids in `appThemes` (unknown ids fall back to the default).
  final String themeId;

  /// XP, levels, stats and badges on screen. Off shows a plain list.
  final bool gameMode;

  /// Cosmetic character class (emblem and motto only; no rule changes).
  final String charClass;

  /// Whole-interface zoom, independent of the operating system's text size.
  final double uiScale;

  static const minScale = 0.8;
  static const maxScale = 2.0;

  double get safeScale =>
      uiScale.isFinite ? uiScale.clamp(minScale, maxScale) : 1.0;

  AppSettings copyWith({
    String? themeId,
    bool? gameMode,
    String? charClass,
    double? uiScale,
  }) => AppSettings(
    themeId: themeId ?? this.themeId,
    gameMode: gameMode ?? this.gameMode,
    charClass: charClass ?? this.charClass,
    uiScale: uiScale ?? this.uiScale,
  );

  String encode() => const JsonEncoder.withIndent('  ').convert({
    'theme': themeId,
    'game_mode': gameMode,
    'class': charClass,
    'ui_scale': safeScale,
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
      );
    } on FormatException {
      return const AppSettings();
    }
  }
}
