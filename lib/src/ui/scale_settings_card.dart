import 'package:flutter/material.dart';

import '../app/task_controller.dart';
import 'fine_slider.dart';

class ScaleSettingsCard extends StatefulWidget {
  const ScaleSettingsCard({super.key, required this.controller});
  final TaskController controller;

  @override
  State<ScaleSettingsCard> createState() => _ScaleSettingsCardState();
}

class _ScaleSettingsCardState extends State<ScaleSettingsCard> {
  int? _preview;

  @override
  Widget build(BuildContext context) {
    final settings = widget.controller.settings;
    final percent = (settings.safeScale * 100).round();
    final preview = _preview ?? percent;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Arayüz ölçeği: %$percent',
              key: const Key('scale-label'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Çubuğu sürükle veya yüzdeyi yaz. Örnek anında değişir; çubuğu bıraktığında tüm arayüze uygulanır. Dar ekranlarda büyütme ekrana göre sınırlandırılır.',
            ),
            const SizedBox(height: 16),
            FineSlider(
              id: 'scale',
              label: 'Ölçek',
              value: percent,
              min: 80,
              max: 200,
              unit: '%',
              onPreview: (v) => setState(() => _preview = v),
              onChanged: (v) {
                setState(() => _preview = null);
                widget.controller.updateSettings(
                  settings.copyWith(uiScale: v / 100),
                );
              },
            ),
            Container(
              key: const Key('scale-preview'),
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 24 * preview / percent,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Örnek yazı · %$preview',
                      style: TextStyle(fontSize: 14 * preview / percent),
                    ),
                  ),
                ],
              ),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final scale in [0.8, 1.0, 1.25, 1.5, 1.75, 2.0])
                  ChoiceChip(
                    key: Key('scale-${(scale * 100).round()}'),
                    label: Text('%${(scale * 100).round()}'),
                    selected: settings.safeScale == scale,
                    onSelected: (_) {
                      setState(() => _preview = null);
                      widget.controller.updateSettings(
                        settings.copyWith(uiScale: scale),
                      );
                    },
                  ),
              ],
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              key: const Key('scale-reset'),
              onPressed: () {
                setState(() => _preview = null);
                widget.controller.updateSettings(
                  settings.copyWith(uiScale: 1.0),
                );
              },
              icon: const Icon(Icons.restart_alt),
              label: const Text('Varsayılan boyuta dön'),
            ),
          ],
        ),
      ),
    );
  }
}
