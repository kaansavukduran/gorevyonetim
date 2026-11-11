import 'package:flutter/material.dart';

import 'l10n.dart';

import '../app/task_controller.dart';
import '../storage/task_store.dart';
import 'task_actions.dart';
import 'themes.dart';
import 'accessibility_card.dart';
import 'scale_settings_card.dart';
import 'theme_customization_card.dart';
import 'fine_slider.dart';

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
          key: const Key('settings-list'),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
          children: [
            Text(context.t('Genel ve Dil'), style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            LanguageCard(controller: controller),
            const SizedBox(height: 20),
            Text(
              context.t('Erişilebilirlik'),
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            AccessibilityCard(controller: controller),
            const SizedBox(height: 20),
            Text(
              context.t('Görünüm ve boyut'),
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            ScaleSettingsCard(controller: controller),
            const SizedBox(height: 20),
            Text(context.t('Tema'), style: theme.textTheme.titleLarge),
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
                      settings.copyWith(
                        themeId: t.id,
                        customTheme: settings.customTheme.copyWith(
                          enabled: false,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            ThemeCustomizationCard(controller: controller),
            const SizedBox(height: 20),
            Card(
              child: SwitchListTile(
                key: const Key('game-mode'),
                value: settings.gameMode,
                onChanged: (v) =>
                    controller.updateSettings(settings.copyWith(gameMode: v)),
                title: Text(context.t('Oyun modu')),
                subtitle: Text(
                  context.t(
                    context.t(
                      'XP, seviye, statlar ve rozetler. Kapatırsan sade bir liste kalır; puanlar kaybolmaz, geçmişten yeniden hesaplanır.',
                    ),
                  ),
                ),
              ),
            ),
            if (settings.gameMode) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.t('Günlük hedef'),
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        context.t(
                          context.t(
                            'Günde kaç görev bitirmek istiyorsun? İlerleme yalnız işaretlediğin görevlerden hesaplanır.',
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      FineSlider(
                        id: 'daily-goal',
                        label: context.t('Hedef'),
                        value: settings.dailyGoal.clamp(1, 20),
                        min: 1,
                        max: 20,
                        onChanged: (v) => controller.updateSettings(
                          settings.copyWith(dailyGoal: v),
                        ),
                      ),
                      SwitchListTile(
                        key: const Key('celebration-effects'),
                        contentPadding: EdgeInsets.zero,
                        title: Text(context.t('Kutlama efektleri')),
                        subtitle: Text(
                          context.t(
                            context.t(
                              'Konfeti ve seviye animasyonu. Cihazın hareket azaltma ayarına uyulur.',
                            ),
                          ),
                        ),
                        value: settings.celebrationEffects,
                        onChanged: (v) => controller.updateSettings(
                          settings.copyWith(celebrationEffects: v),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
            Text(context.t('Yedek'), style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      store.usesSystemFilePicker
                          ? context.t(
                              context.t(
                                'Yedeğini dosya seçicisinden belirlediğin konuma kaydet veya daha önce aldığın bir yedeği aç. Başka bir cihaza taşımak için de kullanabilirsin.',
                              ),
                            )
                          : context.t(
                              context.t(
                                'Görevlerini İndirilenler klasörüne kaydet ya da daha önce aldığın bir yedeği geri yükle. Başka bir cihaza taşımak için de kullanabilirsin.',
                              ),
                            ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        FilledButton.icon(
                          key: const Key('export'),
                          icon: const Icon(Icons.upload_file),
                          label: Text(context.t('Yedeği dışa aktar')),
                          onPressed: () => _export(context),
                        ),
                        OutlinedButton.icon(
                          key: const Key('import'),
                          icon: const Icon(Icons.download),
                          label: Text(context.t('Yedeği içe aktar')),
                          onPressed: () => _import(context),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(context.t('Veriler'), style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      store.persistent
                          ? context.t(
                              context.t(
                                'Görevlerin yalnızca bu cihazda saklanır; uygulama bir sunucuya veri göndermez. Her gün otomatik yedek alınır (son 14 gün).',
                              ),
                            )
                          : context.t(
                              context.t(
                                'Bu tarayıcı önizlemesindeki görevler sekmenin belleğinde durur; sekme kapatılınca kaybolur.',
                              ),
                            ),
                    ),
                    const SizedBox(height: 8),
                    if (store.canRevealLocation) ...[
                      SelectableText(
                        store.location,
                        key: const Key('about-location'),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        key: const Key('about-open-folder'),
                        icon: const Icon(Icons.folder_open, size: 18),
                        label: Text(context.t('Klasörü aç')),
                        onPressed: () async {
                          final ok = await store.revealLocation();
                          if (!ok && context.mounted) {
                            showUndoSnack(
                              context,
                              context.t(
                                context.t(
                                  'Klasör açılamadı. Yukarıdaki yolu seçip kopyalayabilirsin.',
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    ] else if (store.persistent)
                      Text(
                        context.t(
                          context.t(
                            'Veriler uygulamanın özel alanında korunur. Dışarıda saklamak veya başka cihaza taşımak için Yedek bölümünü kullan. Uygulamayı kaldırmadan önce yedeğini dışa aktar.',
                          ),
                        ),
                        key: Key('private-storage-help'),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(context.t('Kısayollar'), style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  context.t(
                    context.t(
                      'Ctrl + N  yeni görev\nAlt + ← / →  önceki / sonraki gün\nAlt + B  bugüne dön\nCtrl + 1 … 5  sekmeler\nSağ tık  görev menüsü',
                    ),
                  ),
                ),
              ),
            ),
            if (version.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                context.t('Sürüm {p0}', {'p0': version}),
                style: theme.textTheme.bodySmall,
              ),
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
            ? context.t('Yedek kaydedilmedi veya işlem iptal edildi.')
            : context.t('Yedek kaydedildi: {p0}', {'p0': path}),
      );
    } catch (e) {
      if (context.mounted) {
        showUndoSnack(
          context,
          context.t('Yedek kaydedilemedi: {p0}', {'p0': e}),
        );
      }
    }
  }

  Future<void> _import(BuildContext context) async {
    final List<BackupCandidate> candidates;
    try {
      candidates = await controller.store.importCandidates();
    } catch (e) {
      if (context.mounted) {
        showUndoSnack(context, context.t('Yedek açılamadı: {p0}', {'p0': e}));
      }
      return;
    }
    if (!context.mounted) return;
    // A cancelled native picker with no local backup is simply dismissed.
    if (candidates.isEmpty && controller.store.usesSystemFilePicker) return;
    final chosen = await showDialog<BackupCandidate>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.t('Yedek seç')),
        content: SizedBox(
          width: 520,
          child: candidates.isEmpty
              ? Text(
                  context.t(
                    context.t(
                      'İndirilenler klasöründe ya da otomatik yedeklerde bu uygulamaya ait bir yedek bulunamadı. Yedek dosyasını İndirilenler klasörüne koyup tekrar dene.',
                    ),
                  ),
                )
              : ListView(
                  shrinkWrap: true,
                  children: [
                    for (final c in candidates)
                      ListTile(
                        key: Key('candidate-${c.name}'),
                        leading: const Icon(Icons.description_outlined),
                        title: Text(context.t(c.name)),
                        subtitle: Text(
                          context.t('{p0} görev · {p1}', {
                            'p0': c.taskCount,
                            'p1': _when(c.modified),
                          }),
                        ),
                        onTap: () => Navigator.pop(context, c),
                      ),
                  ],
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.t('Vazgeç')),
          ),
        ],
      ),
    );
    if (chosen == null || !context.mounted) return;
    final sure = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.t('Bu yedek yüklensin mi?')),
        content: Text(
          context.t(
            context.t(
              '"{p0}" ({p1} görev) şu anki listenin yerine geçecek. Şu anki liste önce otomatik yedeklere kaydedilir; istersen ondan geri dönebilirsin.',
            ),
            {'p0': chosen.name, 'p1': chosen.taskCount},
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.t('Vazgeç')),
          ),
          FilledButton(
            key: const Key('confirm-import'),
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.t('Yükle')),
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
        'Yedek yüklendi.${kept == null
            ? ''
            : controller.store.canRevealLocation
            ? context.t(' Önceki liste: {p0}', {'p0': kept})
            : context.t(' Önceki liste otomatik yedeklendi.')}',
        onUndo: () => controller.restore(before),
      );
    } on FormatException catch (e) {
      if (context.mounted) {
        showUndoSnack(
          context,
          context.t('Bu yedek okunamadı: {p0}', {'p0': e.message}),
        );
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
                    context.t(spec.name),
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
                    context.t(spec.tagline),
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
