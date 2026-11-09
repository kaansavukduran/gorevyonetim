import 'package:flutter/material.dart';

import '../app/task_controller.dart';
import '../app/theme_customization.dart';
import 'color_picker.dart';
import 'fine_slider.dart';
import 'themes.dart';

class ThemeCustomizationCard extends StatelessWidget {
  const ThemeCustomizationCard({super.key, required this.controller});
  final TaskController controller;

  void _save(ThemeCustomization value) => controller.updateSettings(
    controller.settings.copyWith(customTheme: value),
  );

  @override
  Widget build(BuildContext context) {
    final custom = controller.settings.customTheme;
    final base = themeById(controller.settings.themeId);
    final palette = customizedTheme(base, custom.copyWith(enabled: true));
    final active = customizedTheme(base, custom);
    final selections =
        <(String, String, Color, ThemeCustomization Function(int))>[
          (
            'primary',
            'Ana vurgu',
            palette.primary,
            (v) => custom.copyWith(primary: v),
          ),
          (
            'secondary',
            'İkinci vurgu',
            palette.secondary,
            (v) => custom.copyWith(secondary: v),
          ),
          (
            'background-start',
            'Arka plan başlangıcı',
            palette.gradient.first,
            (v) => custom.copyWith(backgroundStart: v),
          ),
          (
            'background-end',
            'Arka plan bitişi',
            palette.gradient.last,
            (v) => custom.copyWith(backgroundEnd: v),
          ),
          (
            'surface',
            'Kart zemini',
            palette.surface,
            (v) => custom.copyWith(surface: v),
          ),
          ('xp', 'İlerleme ve XP', palette.xp, (v) => custom.copyWith(xp: v)),
        ];
    return Card(
      key: const Key('theme-customization'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              key: const Key('custom-theme-enabled'),
              contentPadding: EdgeInsets.zero,
              title: const Text('Özel görünüm'),
              subtitle: const Text(
                'Renkleri, kartları ve başlıkları kendine göre ayarla. Renk veya biçim seçtiğinde özel görünüm açılır.',
              ),
              value: custom.enabled,
              onChanged: (v) => _save(custom.copyWith(enabled: v)),
            ),
            const SizedBox(height: 8),
            _ThemePreview(spec: active),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final selection in selections)
                  SizedBox(
                    width: 240,
                    child: OutlinedButton(
                      key: Key('custom-color-${selection.$1}'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.all(12),
                      ),
                      onPressed: () async {
                        final color = await showAppColorPicker(
                          context,
                          title: selection.$2,
                          initial: selection.$3,
                        );
                        if (color != null) {
                          _save(
                            selection
                                .$4(color.toARGB32() & 0xFFFFFF)
                                .copyWith(enabled: true),
                          );
                        }
                      },
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: selection.$3,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(selection.$2),
                                Text(
                                  '#${colorHex(selection.$3)}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.colorize, size: 18),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            const Text('Görünüm'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final option in [
                  ('preset', 'Temadan'),
                  ('light', 'Açık'),
                  ('dark', 'Koyu'),
                ])
                  ChoiceChip(
                    key: Key('custom-appearance-${option.$1}'),
                    label: Text(option.$2),
                    selected: custom.appearance == option.$1,
                    onSelected: (_) => _save(
                      custom.copyWith(enabled: true, appearance: option.$1),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text('Kart köşeleri: ${palette.radius.round()} px'),
            const SizedBox(height: 8),
            FineSlider(
              id: 'theme-radius',
              label: 'Köşe',
              value: palette.radius.round(),
              min: 0,
              max: 28,
              unit: 'px',
              onChanged: (v) =>
                  _save(custom.copyWith(enabled: true, radius: v.toDouble())),
            ),
            SwitchListTile(
              key: const Key('custom-glow'),
              contentPadding: EdgeInsets.zero,
              title: const Text('Rozet parlaması'),
              value: palette.glow,
              onChanged: (v) => _save(custom.copyWith(enabled: true, glow: v)),
            ),
            SwitchListTile(
              key: const Key('custom-serif'),
              contentPadding: EdgeInsets.zero,
              title: const Text('Klasik başlık yazısı'),
              subtitle: const Text(
                'Kapalıyken modern, sade başlıklar kullanılır.',
              ),
              value: palette.serifTitles,
              onChanged: (v) =>
                  _save(custom.copyWith(enabled: true, serifTitles: v)),
            ),
            TextButton.icon(
              key: const Key('custom-theme-reset'),
              icon: const Icon(Icons.restart_alt),
              label: const Text('Hazır temaya dön'),
              onPressed: () => _save(const ThemeCustomization()),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemePreview extends StatelessWidget {
  const _ThemePreview({required this.spec});
  final AppThemeSpec spec;

  @override
  Widget build(BuildContext context) => Theme(
    data: buildTheme(spec),
    child: Builder(
      builder: (context) => Container(
        key: const Key('custom-theme-preview'),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: spec.gradient),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Görünüm önizlemesi',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.check_circle, color: spec.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Örnek görev',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                    Icon(Icons.auto_awesome, color: spec.secondary),
                  ],
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(value: 0.65, color: spec.xp),
                const SizedBox(height: 8),
                Text(
                  '65 / 100 XP · yeni seviyeye doğru',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
