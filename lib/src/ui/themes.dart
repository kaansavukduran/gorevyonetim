import 'package:flutter/material.dart';

import '../app/theme_customization.dart';

/// Extra look of a theme beyond Material colours: the background gradient,
/// the XP colour, card borders and the emblem on the character card.
class GameStyle extends ThemeExtension<GameStyle> {
  const GameStyle({
    required this.gradient,
    required this.xp,
    required this.cardBorder,
    required this.emblem,
    required this.glow,
    this.headlineFamily,
    this.radius = 14,
  });

  final List<Color> gradient;
  final Color xp;
  final Color cardBorder;
  final IconData emblem;

  /// Soft coloured shadow around cards (game-like themes).
  final bool glow;
  final double radius;

  /// Font family for titles (falls back to the system font if missing).
  final String? headlineFamily;

  static GameStyle of(BuildContext context) =>
      Theme.of(context).extension<GameStyle>()!;

  @override
  GameStyle copyWith() => this;

  @override
  GameStyle lerp(GameStyle? other, double t) =>
      t < 0.5 ? this : (other ?? this);
}

class AppThemeSpec {
  const AppThemeSpec({
    required this.id,
    required this.name,
    required this.tagline,
    required this.brightness,
    required this.primary,
    required this.secondary,
    required this.surface,
    required this.gradient,
    required this.xp,
    required this.emblem,
    this.glow = false,
    this.serifTitles = false,
    this.radius = 14,
  });

  final String id;
  final String name;
  final String tagline;
  final Brightness brightness;
  final Color primary;
  final Color secondary;
  final Color surface;
  final List<Color> gradient;
  final Color xp;
  final IconData emblem;
  final bool glow;
  final bool serifTitles;
  final double radius;
}

const String defaultThemeId = 'diyar';

const List<AppThemeSpec> appThemes = [
  AppThemeSpec(
    id: 'diyar',
    name: 'Fantastik Diyar',
    tagline: 'Altın, parşömen ve gece göğü: bir MMORPG kalesinde görev tahtası',
    brightness: Brightness.dark,
    primary: Color(0xFFE0B24F),
    secondary: Color(0xFFC0574C),
    surface: Color(0xFF231B30),
    gradient: [Color(0xFF120E22), Color(0xFF221832), Color(0xFF2C1F16)],
    xp: Color(0xFFF2C14E),
    emblem: Icons.shield,
    glow: true,
    serifTitles: true,
  ),
  AppThemeSpec(
    id: 'neon',
    name: 'Neon Şehir',
    tagline: 'Siberpunk sokakları, camgöbeği ışıklar',
    brightness: Brightness.dark,
    primary: Color(0xFF25E2F2),
    secondary: Color(0xFFFF3DCB),
    surface: Color(0xFF13132B),
    gradient: [Color(0xFF07071A), Color(0xFF140A2E), Color(0xFF1E0730)],
    xp: Color(0xFFFF3DCB),
    emblem: Icons.bolt,
    glow: true,
  ),
  AppThemeSpec(
    id: 'orman',
    name: 'Orman Ruhu',
    tagline: 'Yosun, toprak ve sabah ışığı',
    brightness: Brightness.light,
    primary: Color(0xFF3E7B3A),
    secondary: Color(0xFFA0682B),
    surface: Color(0xFFF8FBF3),
    gradient: [Color(0xFFEFF6E7), Color(0xFFDCEBD0)],
    xp: Color(0xFF7BA23F),
    emblem: Icons.park,
  ),
  AppThemeSpec(
    id: 'pastel',
    name: 'Pastel Rüya',
    tagline: 'Yumuşak pembe ve lavanta, bol yuvarlak köşe',
    brightness: Brightness.light,
    primary: Color(0xFFCF4F92),
    secondary: Color(0xFF7C6BD6),
    surface: Color(0xFFFFFAFD),
    gradient: [Color(0xFFFFF0F6), Color(0xFFEDE7FF)],
    xp: Color(0xFFE478B5),
    emblem: Icons.favorite,
    radius: 22,
  ),
  AppThemeSpec(
    id: 'gece',
    name: 'Gece Yarısı',
    tagline: 'Koyu ve sade, göz yormayan',
    brightness: Brightness.dark,
    primary: Color(0xFF7AA2F7),
    secondary: Color(0xFFBB9AF7),
    surface: Color(0xFF171C26),
    gradient: [Color(0xFF0F131A), Color(0xFF151B25)],
    xp: Color(0xFF7AA2F7),
    emblem: Icons.nightlight_round,
  ),
  AppThemeSpec(
    id: 'sade',
    name: 'Sade',
    tagline: 'Açık renk, sakin ve düz',
    brightness: Brightness.light,
    primary: Color(0xFF2F7D6D),
    secondary: Color(0xFF5B6C8F),
    surface: Color(0xFFFFFFFF),
    gradient: [Color(0xFFF6F8F7), Color(0xFFF6F8F7)],
    xp: Color(0xFF2F7D6D),
    emblem: Icons.emoji_events,
  ),
];

AppThemeSpec themeById(String id) => appThemes.firstWhere(
  (t) => t.id == id,
  orElse: () => appThemes.firstWhere((t) => t.id == defaultThemeId),
);

AppThemeSpec customizedTheme(AppThemeSpec base, ThemeCustomization custom) {
  if (!custom.enabled) return base;
  final brightness = switch (custom.appearance) {
    'light' => Brightness.light,
    'dark' => Brightness.dark,
    _ => base.brightness,
  };
  final palette = brightness == base.brightness
      ? base
      : themeById(brightness == Brightness.dark ? 'gece' : 'sade');
  Color color(int? rgb, Color fallback) =>
      rgb == null ? fallback : Color(0xFF000000 | rgb);
  return AppThemeSpec(
    id: base.id,
    name: base.name,
    tagline: base.tagline,
    brightness: brightness,
    primary: color(custom.primary, base.primary),
    secondary: color(custom.secondary, base.secondary),
    surface: color(custom.surface, palette.surface),
    gradient: [
      color(custom.backgroundStart, palette.gradient.first),
      color(custom.backgroundEnd, palette.gradient.last),
    ],
    xp: color(custom.xp, base.xp),
    emblem: base.emblem,
    glow: custom.glow ?? base.glow,
    serifTitles: custom.serifTitles ?? base.serifTitles,
    radius: custom.safeRadius ?? base.radius,
  );
}

/// Choose the more readable foreground, including on arbitrary custom colours.
Color contrastingText(Color background) {
  final luminance = background.computeLuminance();
  final blackContrast = (luminance + 0.05) / 0.05;
  final whiteContrast = 1.05 / (luminance + 0.05);
  return blackContrast >= whiteContrast ? Colors.black : Colors.white;
}

/// Bundled font family for a font choice (null = the system font).
String? fontFamilyFor(String choice) => switch (choice) {
  'atkinson' => 'AtkinsonHyperlegibleNext',
  'lexend' => 'Lexend',
  'dyslexic' => 'OpenDyslexic',
  _ => null,
};

/// [spec] with strong contrast: pure background, full-strength text and
/// borders, and an accent that stands out on it.
AppThemeSpec highContrastOf(AppThemeSpec spec) {
  final dark = spec.brightness == Brightness.dark;
  final bg = dark ? Colors.black : Colors.white;
  final accent = dark ? const Color(0xFFFFE066) : const Color(0xFF0031B3);
  return AppThemeSpec(
    id: spec.id,
    name: spec.name,
    tagline: spec.tagline,
    brightness: spec.brightness,
    primary: accent,
    secondary: dark ? const Color(0xFF7DF9FF) : const Color(0xFF8A0057),
    surface: bg,
    gradient: [bg, bg],
    xp: accent,
    emblem: spec.emblem,
    serifTitles: spec.serifTitles,
    radius: spec.radius,
  );
}

ThemeData buildTheme(
  AppThemeSpec spec, {
  String? fontFamily,
  bool highContrast = false,
}) {
  if (highContrast) spec = highContrastOf(spec);
  final base = ColorScheme.fromSeed(
    seedColor: spec.primary,
    brightness: spec.brightness,
  );
  final dark = spec.brightness == Brightness.dark;
  final scheme = base.copyWith(
    primary: spec.primary,
    onPrimary: contrastingText(spec.primary),
    secondary: spec.secondary,
    onSecondary: contrastingText(spec.secondary),
    surface: spec.surface,
    onSurface: contrastingText(spec.surface),
    onSurfaceVariant: highContrast
        ? contrastingText(spec.surface)
        : Color.lerp(contrastingText(spec.surface), spec.surface, 0.25),
    outline: highContrast ? contrastingText(spec.surface) : null,
    outlineVariant: highContrast ? contrastingText(spec.surface) : null,
    surfaceContainerLow: Color.alphaBlend(
      spec.primary.withValues(alpha: dark ? 0.06 : 0.04),
      spec.surface,
    ),
  );
  final border = highContrast
      ? contrastingText(spec.surface)
      : spec.primary.withValues(alpha: dark ? 0.35 : 0.25);
  // A chosen reading font is used everywhere, titles included.
  final titles = fontFamily ?? (spec.serifTitles ? 'Georgia' : null);
  const serifFallback = [
    'Georgia',
    'Cambria',
    'DejaVu Serif',
    'Times New Roman',
  ];
  final text = ThemeData(colorScheme: scheme, fontFamily: fontFamily).textTheme
      .apply(
        bodyColor: scheme.onSurface,
        displayColor: scheme.onSurface,
        fontFamily: fontFamily,
      );
  TextStyle? t(TextStyle? s) => titles == null
      ? s
      : s?.copyWith(
          fontFamily: titles,
          fontFamilyFallback: fontFamily == null ? serifFallback : null,
        );
  return ThemeData(
    colorScheme: scheme,
    fontFamily: fontFamily,
    useMaterial3: true,
    scaffoldBackgroundColor: Colors.transparent,
    textTheme: text.copyWith(
      headlineSmall: t(text.headlineSmall),
      headlineMedium: t(text.headlineMedium),
      titleLarge: t(text.titleLarge),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: scheme.onSurface,
        fontFamily: titles,
        fontFamilyFallback: titles == null ? null : serifFallback,
      ),
    ),
    navigationRailTheme: const NavigationRailThemeData(
      backgroundColor: Colors.transparent,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: scheme.surface.withValues(alpha: 0.9),
    ),
    dividerTheme: DividerThemeData(color: border),
    cardTheme: CardThemeData(
      color: scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(spec.radius),
        side: BorderSide(color: border),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    extensions: [
      GameStyle(
        gradient: spec.gradient,
        xp: spec.xp,
        cardBorder: border,
        emblem: spec.emblem,
        glow: spec.glow,
        headlineFamily: titles,
        radius: spec.radius,
      ),
    ],
  );
}
