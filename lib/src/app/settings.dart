import 'dart:convert';

/// Choices that belong to this device, kept apart from the tasks.
class AppSettings {
  const AppSettings({this.themeId = 'diyar', this.gameMode = true});

  /// One of the ids in `appThemes` (unknown ids fall back to the default).
  final String themeId;

  /// XP, levels, stats and badges on screen. Off shows a plain list.
  final bool gameMode;

  AppSettings copyWith({String? themeId, bool? gameMode}) => AppSettings(
    themeId: themeId ?? this.themeId,
    gameMode: gameMode ?? this.gameMode,
  );

  String encode() =>
      const JsonEncoder.withIndent('  ')
          .convert({'theme': themeId, 'game_mode': gameMode});

  /// Reads settings; anything missing or malformed falls back to defaults
  /// (settings are a convenience, never a reason to refuse to start).
  static AppSettings decode(String text) {
    try {
      final j = jsonDecode(text);
      if (j is! Map<String, Object?>) return const AppSettings();
      return AppSettings(
        themeId: j['theme'] is String ? j['theme']! as String : 'diyar',
        gameMode: j['game_mode'] is bool ? j['game_mode']! as bool : true,
      );
    } on FormatException {
      return const AppSettings();
    }
  }
}
