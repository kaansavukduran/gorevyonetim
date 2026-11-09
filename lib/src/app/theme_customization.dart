/// Device-only visual preferences. Colours are opaque 24-bit RGB values.
class ThemeCustomization {
  const ThemeCustomization({
    this.enabled = false,
    this.appearance = 'preset',
    this.primary,
    this.secondary,
    this.surface,
    this.backgroundStart,
    this.backgroundEnd,
    this.xp,
    this.radius,
    this.glow,
    this.serifTitles,
  });

  final bool enabled;
  final String appearance;
  final int? primary;
  final int? secondary;
  final int? surface;
  final int? backgroundStart;
  final int? backgroundEnd;
  final int? xp;
  final double? radius;
  final bool? glow;
  final bool? serifTitles;

  double? get safeRadius =>
      radius != null && radius!.isFinite ? radius!.clamp(0.0, 28.0) : null;

  ThemeCustomization copyWith({
    bool? enabled,
    String? appearance,
    int? primary,
    int? secondary,
    int? surface,
    int? backgroundStart,
    int? backgroundEnd,
    int? xp,
    double? radius,
    bool? glow,
    bool? serifTitles,
  }) => ThemeCustomization(
    enabled: enabled ?? this.enabled,
    appearance: appearance ?? this.appearance,
    primary: primary ?? this.primary,
    secondary: secondary ?? this.secondary,
    surface: surface ?? this.surface,
    backgroundStart: backgroundStart ?? this.backgroundStart,
    backgroundEnd: backgroundEnd ?? this.backgroundEnd,
    xp: xp ?? this.xp,
    radius: radius ?? this.radius,
    glow: glow ?? this.glow,
    serifTitles: serifTitles ?? this.serifTitles,
  );

  Map<String, Object?> toJson() => {
    'enabled': enabled,
    'appearance': appearance,
    'primary': primary,
    'secondary': secondary,
    'surface': surface,
    'background_start': backgroundStart,
    'background_end': backgroundEnd,
    'xp': xp,
    'radius': safeRadius,
    'glow': glow,
    'serif_titles': serifTitles,
  };

  factory ThemeCustomization.fromJson(Object? value) {
    if (value is! Map<String, Object?>) return const ThemeCustomization();
    int? color(String key) {
      final v = value[key];
      return v is int && v >= 0 && v <= 0xFFFFFF ? v : null;
    }

    final radius = value['radius'];
    final appearance = value['appearance'];
    return ThemeCustomization(
      enabled: value['enabled'] == true,
      appearance:
          appearance is String &&
              ['preset', 'light', 'dark'].contains(appearance)
          ? appearance
          : 'preset',
      primary: color('primary'),
      secondary: color('secondary'),
      surface: color('surface'),
      backgroundStart: color('background_start'),
      backgroundEnd: color('background_end'),
      xp: color('xp'),
      radius: radius is num && radius.isFinite
          ? radius.toDouble().clamp(0.0, 28.0)
          : null,
      glow: value['glow'] is bool ? value['glow']! as bool : null,
      serifTitles: value['serif_titles'] is bool
          ? value['serif_titles']! as bool
          : null,
    );
  }
}
