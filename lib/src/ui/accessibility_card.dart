import 'package:flutter/material.dart';

import '../app/settings.dart';
import '../app/task_controller.dart';
import 'fine_slider.dart';
import 'l10n.dart';
import 'themes.dart';

/// Language choice (Settings → Genel ve Dil).
class LanguageCard extends StatelessWidget {
  const LanguageCard({super.key, required this.controller});

  final TaskController controller;

  @override
  Widget build(BuildContext context) {
    final settings = controller.settings;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.t('Dil')),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              key: const Key('language'),
              showSelectedIcon: false,
              segments: [
                ButtonSegment(
                  value: 'system',
                  label: Text(context.t('Sistem')),
                ),
                // Language names are shown in their own language.
                const ButtonSegment(value: 'tr', label: Text('Türkçe')),
                const ButtonSegment(value: 'en', label: Text('English')),
              ],
              selected: {settings.language},
              onSelectionChanged: (v) => controller.updateSettings(
                settings.copyWith(language: v.first),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              context.t(
                'Sistem: cihazın dili İngilizceyse English, değilse Türkçe. '
                'Bu ayar yalnız bu cihazda geçerlidir.',
              ),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

/// Font, text size and contrast (Settings → Erişilebilirlik). Each choice
/// is saved on its own; none changes another.
class AccessibilityCard extends StatelessWidget {
  const AccessibilityCard({super.key, required this.controller});

  final TaskController controller;

  static const sample = 'Çiçekli bağda ışıl ışıl güneş: ÇĞİÖŞÜ çğıöşü 0123';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = controller.settings;
    final percent = (settings.safeTextScale * 100).round();
    String fontName(String id) => switch (id) {
      'atkinson' => 'Atkinson Hyperlegible Next',
      'lexend' => 'Lexend',
      'dyslexic' => context.t('Disleksi dostu yazı tipi (OpenDyslexic)'),
      _ => context.t('Sistem yazı tipi'),
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.t('Yazı tipi'), style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            for (final id in AppSettings.fontChoices)
              ListTile(
                key: Key('font-$id'),
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  settings.fontChoice == id
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: settings.fontChoice == id
                      ? theme.colorScheme.primary
                      : null,
                ),
                title: Text(fontName(id)),
                subtitle: Text(
                  sample,
                  // inherit: false so the system sample is really the
                  // platform font, not the font chosen above it.
                  style: TextStyle(
                    inherit: false,
                    fontFamily: fontFamilyFor(id),
                    fontSize: 14,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                selected: settings.fontChoice == id,
                onTap: () => controller.updateSettings(
                  settings.copyWith(fontChoice: id),
                ),
              ),
            const Divider(height: 24),
            FineSlider(
              id: 'text-scale',
              label: context.t('Yazı boyutu'),
              value: percent,
              min: 80,
              max: 200,
              unit: '%',
              onChanged: (v) => controller.updateSettings(
                settings.copyWith(textScale: v / 100),
              ),
            ),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final p in [80, 100, 125, 150, 175, 200])
                  ChoiceChip(
                    key: Key('text-scale-$p'),
                    label: Text(context.isEnglish ? '$p%' : '%$p'),
                    selected: percent == p,
                    onSelected: (_) => controller.updateSettings(
                      settings.copyWith(textScale: p / 100),
                    ),
                  ),
                TextButton(
                  key: const Key('text-scale-reset'),
                  onPressed: percent == 100
                      ? null
                      : () => controller.updateSettings(
                          settings.copyWith(textScale: 1),
                        ),
                  child: Text(context.t('Varsayılana dön')),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              context.t(
                'Arayüz ölçeğinden bağımsızdır; düğmeler ve boşluklar aynı '
                'kalır, yalnız yazılar büyür.',
              ),
              style: theme.textTheme.bodySmall,
            ),
            const Divider(height: 24),
            SwitchListTile(
              key: const Key('high-contrast'),
              contentPadding: EdgeInsets.zero,
              value: settings.highContrast,
              onChanged: (v) =>
                  controller.updateSettings(settings.copyWith(highContrast: v)),
              title: Text(context.t('Yüksek kontrast')),
              subtitle: Text(
                context.t(
                  'Seçili temanın açık ya da koyu hâlini düz arka plan, tam '
                  'kontrastlı yazı ve belirgin kenarlarla gösterir.',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
