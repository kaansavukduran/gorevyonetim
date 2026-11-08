import 'package:flutter/material.dart';

import '../app/task_controller.dart';
import '../storage/task_store.dart';
import 'task_actions.dart';
import 'themes.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key, required this.controller, this.version = ''});

  final TaskController controller;
  final String version;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final store = controller.store;
    final settings = controller.settings;
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 860),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
          children: [
            Text('Tema', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final t in appThemes)
                  _ThemeCard(
                    spec: t,
                    selected: themeById(settings.themeId).id == t.id,
                    onTap: () => controller.updateSettings(
                      settings.copyWith(themeId: t.id),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Card(
              child: SwitchListTile(
                key: const Key('game-mode'),
                value: settings.gameMode,
                onChanged: (v) =>
                    controller.updateSettings(settings.copyWith(gameMode: v)),
                title: const Text('Oyun modu'),
                subtitle: const Text(
                  'XP, seviye, statlar ve rozetler. Kapatırsan sade bir liste kalır; '
                  'puanlar kaybolmaz, geçmişten yeniden hesaplanır.',
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('Yedek', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Görevlerini bir dosyaya kaydet (İndirilenler klasörüne) ya da '
                      'daha önce kaydettiğin bir yedeği geri yükle. Başka bir '
                      'bilgisayara taşımak için de kullanılır.',
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        FilledButton.icon(
                          key: const Key('export'),
                          icon: const Icon(Icons.upload_file),
                          label: const Text('Yedeği dışa aktar'),
                          onPressed: () => _export(context),
                        ),
                        OutlinedButton.icon(
                          key: const Key('import'),
                          icon: const Icon(Icons.download),
                          label: const Text('Yedeği içe aktar'),
                          onPressed: () => _import(context),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('Veriler', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Görevlerin yalnızca bu bilgisayarda, tek bir dosyada durur; '
                      'internete hiçbir şey gönderilmez. Her gün otomatik yedek '
                      'alınır (son 14 gün).',
                    ),
                    const SizedBox(height: 8),
                    SelectableText(
                      store.location,
                      key: const Key('about-location'),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      key: const Key('about-open-folder'),
                      icon: const Icon(Icons.folder_open, size: 18),
                      label: const Text('Klasörü aç'),
                      onPressed: () async {
                        final ok = await store.revealLocation();
                        if (!ok && context.mounted) {
                          showUndoSnack(
                            context,
                            'Klasör açılamadı. Yukarıdaki yolu seçip kopyalayabilirsin.',
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('Kısayollar', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Ctrl + N  yeni görev\n'
                  'Alt + ← / →  önceki / sonraki gün\n'
                  'Alt + B  bugüne dön\n'
                  'Ctrl + 1 … 5  sekmeler\n'
                  'Sağ tık  görev menüsü',
                ),
              ),
            ),
            if (version.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('Sürüm $version', style: theme.textTheme.bodySmall),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _export(BuildContext context) async {
    try {
      final path = await controller.exportBackup();
      if (!context.mounted) return;
      showUndoSnack(
        context,
        path == null
            ? 'Bu sürümde dosyaya yedek alınamıyor.'
            : 'Yedek kaydedildi: $path',
      );
    } catch (e) {
      if (context.mounted) showUndoSnack(context, 'Yedek kaydedilemedi: $e');
    }
  }

  Future<void> _import(BuildContext context) async {
    final candidates = await controller.store.importCandidates();
    if (!context.mounted) return;
    final chosen = await showDialog<BackupCandidate>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yedek seç'),
        content: SizedBox(
          width: 520,
          child: candidates.isEmpty
              ? const Text(
                  'İndirilenler klasöründe ya da otomatik yedeklerde bu uygulamaya '
                  'ait bir yedek bulunamadı. Yedek dosyasını İndirilenler '
                  'klasörüne koyup tekrar dene.',
                )
              : ListView(
                  shrinkWrap: true,
                  children: [
                    for (final c in candidates)
                      ListTile(
                        key: Key('candidate-${c.name}'),
                        leading: const Icon(Icons.description_outlined),
                        title: Text(c.name),
                        subtitle: Text(
                          '${c.taskCount} görev · ${_when(c.modified)}',
                        ),
                        onTap: () => Navigator.pop(context, c),
                      ),
                  ],
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Vazgeç'),
          ),
        ],
      ),
    );
    if (chosen == null || !context.mounted) return;
    final sure = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bu yedek yüklensin mi?'),
        content: Text(
          '"${chosen.name}" (${chosen.taskCount} görev) şu anki listenin yerine '
          'geçecek. Şu anki liste önce otomatik yedeklere kaydedilir; '
          'istersen ondan geri dönebilirsin.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            key: const Key('confirm-import'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yükle'),
          ),
        ],
      ),
    );
    if (sure != true || !context.mounted) return;
    try {
      final data = await controller.store.readCandidate(chosen);
      final before = controller.data;
      final kept = await controller.importBackup(data);
      if (!context.mounted) return;
      showUndoSnack(
        context,
        'Yedek yüklendi.${kept == null ? '' : ' Önceki liste: $kept'}',
        onUndo: () => controller.restore(before),
      );
    } on FormatException catch (e) {
      if (context.mounted) {
        showUndoSnack(context, 'Bu yedek okunamadı: ${e.message}');
      }
    }
  }

  static String _when(DateTime t) {
    final l = t.toLocal();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(l.day)}.${two(l.month)}.${l.year} ${two(l.hour)}:${two(l.minute)}';
  }
}

class _ThemeCard extends StatelessWidget {
  const _ThemeCard({
    required this.spec,
    required this.selected,
    required this.onTap,
  });

  final AppThemeSpec spec;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dark = spec.brightness == Brightness.dark;
    final fg = dark ? Colors.white : const Color(0xFF1D1B20);
    return SizedBox(
      width: 196,
      height: 148,
      child: Material(
        key: Key('theme-${spec.id}'),
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Ink(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: spec.gradient.length == 1
                    ? [spec.gradient.first, spec.gradient.first]
                    : spec.gradient,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected ? spec.primary : fg.withValues(alpha: 0.15),
                width: selected ? 3 : 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(spec.emblem, color: spec.primary),
                      const Spacer(),
                      if (selected)
                        Icon(Icons.check_circle, color: spec.primary),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    spec.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: fg,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      fontFamily: spec.serifTitles ? 'Georgia' : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    spec.tagline,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: fg.withValues(alpha: 0.75),
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      for (final c in [spec.primary, spec.secondary, spec.xp])
                        Container(
                          width: 14,
                          height: 14,
                          margin: const EdgeInsets.only(right: 4),
                          decoration: BoxDecoration(
                            color: c,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
