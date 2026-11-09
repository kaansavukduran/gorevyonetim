import 'package:flutter_test/flutter_test.dart';
import 'package:gunluk_gorevler/src/app/settings.dart';
import 'package:gunluk_gorevler/src/app/theme_customization.dart';

void main() {
  test('every setting survives encoding and an app restart', () {
    const original = AppSettings(
      themeId: 'neon',
      gameMode: false,
      charClass: 'buyucu',
      uiScale: 1.75,
    );
    final loaded = AppSettings.decode(original.encode());
    expect(loaded.themeId, 'neon');
    expect(loaded.gameMode, isFalse);
    expect(loaded.charClass, 'buyucu');
    expect(loaded.uiScale, 1.75);
    expect(loaded.copyWith(gameMode: true).uiScale, 1.75);
  });

  test(
    'fine scale, ordering, game goal and custom palette survive a restart',
    () {
      final settings = AppSettings.decode(
        const AppSettings(
          uiScale: 1.37,
          sortByTime: true,
          dailyGoal: 7,
          celebrationEffects: false,
          customTheme: ThemeCustomization(
            enabled: true,
            appearance: 'light',
            primary: 0x000000,
            secondary: 0x00AACC,
            surface: 0xFFFFFF,
            backgroundStart: 0xCCCCCC,
            backgroundEnd: 0x999999,
            xp: 0x3366FF,
            radius: 23,
            glow: false,
            serifTitles: true,
          ),
        ).encode(),
      );
      expect(settings.uiScale, 1.37);
      expect(settings.sortByTime, isTrue);
      expect(settings.dailyGoal, 7);
      expect(settings.celebrationEffects, isFalse);
      final theme = settings.customTheme;
      expect(theme.enabled, isTrue);
      expect(theme.appearance, 'light');
      expect(theme.primary, 0x000000);
      expect(theme.secondary, 0x00AACC);
      expect(theme.surface, 0xFFFFFF);
      expect(theme.backgroundStart, 0xCCCCCC);
      expect(theme.backgroundEnd, 0x999999);
      expect(theme.xp, 0x3366FF);
      expect(theme.radius, 23);
      expect(theme.glow, isFalse);
      expect(theme.serifTitles, isTrue);
      expect(settings.copyWith(gameMode: false).customTheme.primary, 0);
    },
  );

  test(
    'malformed custom fields are ignored without losing valid preferences',
    () {
      final settings = AppSettings.decode(
        '{"theme":"neon","daily_goal":999,"custom_theme":{"enabled":true,"appearance":"unknown","primary":-1,"secondary":16777216,"surface":"white","xp":255,"radius":900,"glow":"yes"}}',
      );
      expect(settings.themeId, 'neon');
      expect(settings.dailyGoal, 20);
      final theme = settings.customTheme;
      expect(theme.appearance, 'preset');
      expect(theme.primary, isNull);
      expect(theme.secondary, isNull);
      expect(theme.surface, isNull);
      expect(theme.xp, 255);
      expect(theme.safeRadius, 28);
      expect(theme.glow, isNull);
      expect(
        AppSettings.decode('{"custom_theme":[]}').customTheme.enabled,
        isFalse,
      );
      expect(AppSettings.decode('{"daily_goal":0}').dailyGoal, 1);
    },
  );

  test('old and malformed settings start with safe scale', () {
    for (final text in [
      '{}',
      '{"theme":"orman"}',
      '[]',
      '{',
      '{"ui_scale":"large"}',
      '{"ui_scale":null}',
    ]) {
      expect(AppSettings.decode(text).safeScale, 1.0);
    }
    expect(AppSettings.decode('{"ui_scale":-9}').uiScale, 0.8);
    expect(AppSettings.decode('{"ui_scale":900}').uiScale, 2.0);
    expect(const AppSettings(uiScale: double.nan).safeScale, 1.0);
    expect(
      const AppSettings(uiScale: double.infinity).encode(),
      contains('1.0'),
    );
  });
}
