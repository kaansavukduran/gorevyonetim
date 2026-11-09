import 'package:flutter_test/flutter_test.dart';
import 'package:gunluk_gorevler/src/app/settings.dart';

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
