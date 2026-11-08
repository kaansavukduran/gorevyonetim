import 'package:flutter/material.dart';

import '../app/task_controller.dart';
import '../domain/game.dart';
import '../domain/task.dart';
import 'game_widgets.dart';
import 'themes.dart';

/// The character sheet: level, title, stats and badges.
class CharacterPage extends StatelessWidget {
  const CharacterPage({super.key, required this.controller});

  final TaskController controller;

  @override
  Widget build(BuildContext context) {
    final p = controller.profile;
    final book = controller.quests;
    final cls = charClassById(controller.settings.charClass);
    final theme = Theme.of(context);
    final style = GameStyle.of(context);
    final stats = <(IconData, String, String, String)>[
      (
        Icons.local_fire_department,
        'İrade',
        '${p.willpower}',
        'Tüm görevlerini bitirdiğin gün sayısı (mükemmel gün)',
      ),
      (
        Icons.military_tech,
        'Disiplin',
        p.discipline == null ? '–' : '%${p.discipline}',
        'Son 30 günde beklenen günlerin yüzde kaçında yaptın',
      ),
      (
        Icons.favorite,
        'Dayanıklılık',
        '${p.endurance} gün',
        'Bir görevde ulaştığın en uzun seri',
      ),
      (Icons.shield, 'Cesaret', '${p.courage}', 'Bitirdiğin zor görev sayısı'),
      (
        Icons.center_focus_strong,
        'Odak',
        p.focus == null ? '–' : '%${p.focus}',
        'İşaretlerin yüzde kaçı kendi gününde yapıldı',
      ),
      (
        Icons.check_circle,
        'Toplam başarı',
        '${p.totalDone}',
        'İşaretlediğin tüm görev günleri',
      ),
      (
        Icons.savings,
        'Altın',
        '${book.gold}',
        'Günlük görevler ve haftalık meydan okumadan (${book.questsDone} görev)',
      ),
    ];

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 860),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
          children: [
            Card(
              key: const Key('character-card'),
              elevation: style.glow ? 6 : 0,
              shadowColor: style.xp.withValues(alpha: 0.4),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    LevelBadge(level: p.level, size: 92, icon: cls.icon),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.title,
                            key: const Key('character-title'),
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: style.xp,
                            ),
                          ),
                          Text(
                            '${cls.name} · ${cls.motto}',
                            key: const Key('character-class'),
                            style: theme.textTheme.bodyMedium,
                          ),
                          Text(
                            'Seviye ${p.level} · toplam ${p.totalXp} XP',
                            style: theme.textTheme.titleSmall,
                          ),
                          const SizedBox(height: 12),
                          XpBar(profile: p, height: 14),
                          const SizedBox(height: 6),
                          Text(
                            'Sonraki seviyeye ${p.xpForNext - p.xpIntoLevel} XP '
                            '· bugün +${p.xpToday} XP',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('Statlar', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            LayoutBuilder(
              builder: (context, c) {
                final cols = c.maxWidth > 640 ? 3 : 2;
                final w = (c.maxWidth - (cols - 1) * 10) / cols;
                return Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final s in stats)
                      SizedBox(
                        width: w,
                        child: Tooltip(
                          message: s.$4,
                          child: Card(
                            margin: EdgeInsets.zero,
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                children: [
                                  Icon(s.$1, color: style.xp, size: 28),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          s.$3,
                                          key: Key('stat-${s.$2}'),
                                          style: theme.textTheme.titleLarge
                                              ?.copyWith(
                                                fontWeight: FontWeight.w800,
                                              ),
                                        ),
                                        Text(
                                          s.$2,
                                          style: theme.textTheme.labelMedium,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),
            Text('Sınıf', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final c in charClasses)
                  ChoiceChip(
                    key: Key('class-${c.id}'),
                    avatar: Icon(c.icon, size: 18),
                    label: Text(c.name),
                    selected: c.id == cls.id,
                    onSelected: (_) => controller.updateSettings(
                      controller.settings.copyWith(charClass: c.id),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Sınıf yalnızca görünüşü değiştirir; kurallar herkes için aynı.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 20),
            Text('Son 26 hafta', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: ActivityHeatmap(
                  data: controller.data,
                  today: controller.today,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Text('Rozetler', style: theme.textTheme.titleLarge),
                const SizedBox(width: 10),
                Text(
                  '${p.unlockedBadges} / ${p.badges.length}',
                  style: theme.textTheme.titleSmall,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [for (final b in p.badges) _BadgeTile(badge: b)],
            ),
            const SizedBox(height: 20),
            const _HowItWorks(),
          ],
        ),
      ),
    );
  }
}

class _BadgeTile extends StatelessWidget {
  const _BadgeTile({required this.badge});

  final GameBadge badge;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = GameStyle.of(context);
    final on = badge.unlocked;
    return Tooltip(
      message: on
          ? '${badge.description} (açıldı)'
          : '${badge.description}: ${badge.progress} / ${badge.goal}',
      child: SizedBox(
        width: 132,
        height: 118,
        child: Card(
          key: Key('badge-${badge.id}'),
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Icon(
                  on ? Icons.emoji_events : Icons.lock_outline,
                  size: 34,
                  color: on ? style.xp : theme.disabledColor,
                ),
                const SizedBox(height: 6),
                Text(
                  badge.name,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: on ? null : theme.disabledColor,
                  ),
                ),
                const SizedBox(height: 6),
                if (!on)
                  LinearProgressIndicator(
                    value: badge.progress / badge.goal,
                    minHeight: 4,
                    borderRadius: BorderRadius.circular(4),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HowItWorks extends StatelessWidget {
  const _HowItWorks();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: ExpansionTile(
        key: const Key('how-xp'),
        title: const Text('Nasıl XP kazanırım?'),
        shape: const Border(),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• Her işaretlediğin görev günü: Kolay ${Difficulty.kolay.baseXp}, '
            'Orta ${Difficulty.orta.baseXp}, Zor ${Difficulty.zor.baseXp} XP.\n'
            '• Kendi gününde işaretlersen +${GameRules.onTimeBonus} XP ve seri '
            'bonusu: seri günü başına +${GameRules.streakBonusPerDay} XP '
            '(en fazla +${GameRules.streakBonusCap}).\n'
            '• Sonradan işaretlenen günler yalnızca temel XP alır.\n'
            '• Bir günün tüm görevlerini bitirirsen: mükemmel gün, '
            '+${GameRules.perfectDayBonus} XP ve +1 İrade.\n'
            '• XP her zaman geçmişten yeniden hesaplanır: bir görevi silersen '
            'onun XP\'si de gider, hiçbir sayı kendiliğinden artmaz.',
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
