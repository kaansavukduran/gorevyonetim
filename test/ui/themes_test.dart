import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gunluk_gorevler/src/app/theme_customization.dart';
import 'package:gunluk_gorevler/src/ui/themes.dart';

void main() {
  test('custom palette overrides each color and shape independently', () {
    final preset = themeById('diyar');
    final custom = customizedTheme(
      preset,
      const ThemeCustomization(
        enabled: true,
        appearance: 'light',
        primary: 0x123456,
        secondary: 0xABCDEF,
        surface: 0xFFFFFF,
        backgroundStart: 0xCCCCCC,
        backgroundEnd: 0x999999,
        xp: 0xFF0000,
        radius: 23,
        glow: false,
        serifTitles: false,
      ),
    );
    expect(custom.brightness, Brightness.light);
    expect(custom.primary, const Color(0xFF123456));
    expect(custom.secondary, const Color(0xFFABCDEF));
    expect(custom.surface, Colors.white);
    expect(custom.gradient, [const Color(0xFFCCCCCC), const Color(0xFF999999)]);
    expect(custom.xp, const Color(0xFFFF0000));
    expect(custom.radius, 23);
    expect(custom.glow, isFalse);
    expect(custom.serifTitles, isFalse);
    expect(
      identical(
        customizedTheme(preset, const ThemeCustomization(primary: 0)),
        preset,
      ),
      isTrue,
    );
  });

  test('custom controls and card surfaces retain readable foregrounds', () {
    for (final rgb in [0x000000, 0xFFFFFF, 0x777777, 0xFF00FF, 0x00FFFF]) {
      final spec = customizedTheme(
        themeById('diyar'),
        ThemeCustomization(
          enabled: true,
          primary: rgb,
          secondary: rgb,
          surface: rgb,
        ),
      );
      final colors = buildTheme(spec).colorScheme;
      for (final pair in [
        (colors.primary, colors.onPrimary),
        (colors.secondary, colors.onSecondary),
        (colors.surface, colors.onSurface),
      ]) {
        final a = pair.$1.computeLuminance();
        final b = pair.$2.computeLuminance();
        final ratio = ((a > b ? a : b) + .05) / ((a > b ? b : a) + .05);
        expect(ratio, greaterThanOrEqualTo(4.5));
      }
    }
  });
}
