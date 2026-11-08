import 'package:flutter/material.dart';

import '../app/task_controller.dart';
import '../domain/game.dart';
import 'themes.dart';

/// The round emblem with the level number.
class LevelBadge extends StatelessWidget {
  const LevelBadge({super.key, required this.level, this.size = 44});

  final int level;
  final double size;

  @override
  Widget build(BuildContext context) {
    final style = GameStyle.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [style.xp, Color.lerp(style.xp, Colors.black, 0.45)!],
        ),
        boxShadow: style.glow
            ? [
                BoxShadow(
                  color: style.xp.withValues(alpha: 0.5),
                  blurRadius: 12,
                ),
              ]
            : null,
        border: Border.all(color: scheme.surface, width: 2),
      ),
      alignment: Alignment.center,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            style.emblem,
            size: size * 0.78,
            color: Colors.white.withValues(alpha: 0.22),
          ),
          Text(
            '$level',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: size * 0.4,
              shadows: const [Shadow(blurRadius: 3, color: Colors.black54)],
            ),
          ),
        ],
      ),
    );
  }
}

/// The XP bar towards the next level.
class XpBar extends StatelessWidget {
  const XpBar({super.key, required this.profile, this.height = 10});

  final GameProfile profile;
  final double height;

  @override
  Widget build(BuildContext context) {
    final style = GameStyle.of(context);
    final scheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: Stack(
        children: [
          Container(
            height: height,
            color: scheme.onSurface.withValues(alpha: 0.12),
          ),
          FractionallySizedBox(
            widthFactor: (profile.xpIntoLevel / profile.xpForNext).clamp(
              0.0,
              1.0,
            ),
            child: Container(
              height: height,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color.lerp(style.xp, Colors.white, 0.25)!, style.xp],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One line for the top of the day: level, title, XP bar, XP today.
class HeroStrip extends StatelessWidget {
  const HeroStrip({super.key, required this.profile, this.onTap});

  final GameProfile profile;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = GameStyle.of(context);
    return Material(
      key: const Key('hero-strip'),
      color: theme.colorScheme.surface.withValues(alpha: 0.85),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: style.cardBorder),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 14, 8),
          child: Row(
            children: [
              LevelBadge(level: profile.level, size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Seviye ${profile.level} · ${profile.title}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              fontFamily: style.headlineFamily,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${profile.xpIntoLevel} / ${profile.xpForNext} XP',
                          key: const Key('hero-xp'),
                          style: theme.textTheme.labelMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    XpBar(profile: profile, height: 8),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                children: [
                  Text(
                    '+${profile.xpToday}',
                    key: const Key('hero-today'),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: style.xp,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text('bugün', style: theme.textTheme.labelSmall),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Runs [change] (a tick or untick) and tells the person what it earned:
/// "+27 XP", a level-up window, newly opened badges. Returns what [change]
/// returned. With game mode off it only runs [change].
T withGameFeedback<T>(
  BuildContext context,
  TaskController controller,
  T Function() change,
) {
  if (!controller.settings.gameMode) return change();
  final before = controller.profile;
  final result = change();
  final after = controller.profile;
  final gained = after.totalXp - before.totalXp;
  final messenger = ScaffoldMessenger.of(context);
  if (gained > 0) {
    final opened = [
      for (var i = 0; i < after.badges.length; i++)
        if (after.badges[i].unlocked && !before.badges[i].unlocked)
          after.badges[i].name,
    ];
    final perfect = after.willpower > before.willpower;
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        key: const Key('xp-snack'),
        width: 520,
        duration: const Duration(seconds: 3),
        content: Text(
          [
            '+$gained XP',
            if (perfect) 'Mükemmel gün! +1 İrade',
            if (opened.isNotEmpty) 'Yeni rozet: ${opened.join(', ')}',
          ].join('   ·   '),
        ),
      ),
    );
    if (after.level > before.level) {
      showDialog<void>(
        context: context,
        builder: (_) => LevelUpDialog(profile: after),
      );
    }
  }
  return result;
}

class LevelUpDialog extends StatelessWidget {
  const LevelUpDialog({super.key, required this.profile});

  final GameProfile profile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = GameStyle.of(context);
    return AlertDialog(
      key: const Key('level-up'),
      contentPadding: const EdgeInsets.fromLTRB(28, 28, 28, 8),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.4, end: 1),
            duration: const Duration(milliseconds: 600),
            curve: Curves.elasticOut,
            builder: (_, v, child) => Transform.scale(scale: v, child: child),
            child: LevelBadge(level: profile.level, size: 96),
          ),
          const SizedBox(height: 18),
          Text(
            'Seviye atladın!',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: style.xp,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Seviye ${profile.level}: ${profile.title}',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(
            'Sonraki seviye için ${profile.xpForNext} XP',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Devam'),
        ),
      ],
    );
  }
}
