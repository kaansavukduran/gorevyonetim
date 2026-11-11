import 'package:flutter/material.dart';

import 'l10n.dart';

import '../app/task_controller.dart';
import '../domain/game.dart';
import '../domain/local_date.dart';
import '../domain/quests.dart';
import '../domain/task_data.dart';
import 'themes.dart';

/// The round emblem with the level number.
class LevelBadge extends StatelessWidget {
  const LevelBadge({super.key, required this.level, this.size = 44, this.icon});

  final int level;
  final double size;

  /// Emblem behind the number (the class icon); the theme's by default.
  final IconData? icon;

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
            icon ?? style.emblem,
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
  const HeroStrip({super.key, required this.profile, this.onTap, this.icon});

  final GameProfile profile;
  final VoidCallback? onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = GameStyle.of(context);
    return Material(
      key: const Key('hero-strip'),
      color: theme.colorScheme.surface.withValues(alpha: 0.85),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(style.radius),
        side: BorderSide(color: style.cardBorder),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(style.radius),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 14, 8),
          child: Row(
            children: [
              LevelBadge(level: profile.level, size: 40, icon: icon),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            context.t('Seviye {p0} · {p1}', {
                              'p0': profile.level,
                              'p1': context.t(profile.title),
                            }),
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
                  Text(context.t('bugün'), style: theme.textTheme.labelSmall),
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
  final animate =
      controller.settings.celebrationEffects &&
      !MediaQuery.disableAnimationsOf(context) &&
      !WidgetsBinding
          .instance
          .platformDispatcher
          .accessibilityFeatures
          .reduceMotion;
  final before = controller.profile;
  int doneToday() => controller.data
      .tasksOn(controller.today)
      .where((t) => controller.data.isDone(t.id, controller.today))
      .length;
  final beforeCount = doneToday();
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
    final goalReached =
        beforeCount < controller.settings.dailyGoal &&
        doneToday() >= controller.settings.dailyGoal;
    if ((perfect || goalReached) && controller.settings.celebrationEffects) {
      showConfetti(context);
    }
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        key: const Key('xp-snack'),
        width: MediaQuery.sizeOf(context).width > 560 ? 520 : null,
        duration: const Duration(seconds: 3),
        content: Text(
          [
            '+$gained XP',
            if (perfect) context.t('Mükemmel gün! +1 İrade'),
            if (goalReached) context.t('Günlük hedef tamam!'),
            if (opened.isNotEmpty) 'Yeni rozet: ${opened.join(', ')}',
          ].join('   ·   '),
        ),
      ),
    );
    if (after.level > before.level) {
      showDialog<void>(
        context: context,
        builder: (_) => LevelUpDialog(profile: after, animate: animate),
      );
    }
  }
  return result;
}

class LevelUpDialog extends StatelessWidget {
  const LevelUpDialog({super.key, required this.profile, this.animate = true});

  final GameProfile profile;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = GameStyle.of(context);
    return AlertDialog(
      key: Key('level-up'),
      contentPadding: EdgeInsets.fromLTRB(28, 28, 28, 8),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.4, end: 1),
            duration: animate ? Duration(milliseconds: 600) : Duration.zero,
            curve: Curves.elasticOut,
            builder: (_, v, child) => Transform.scale(scale: v, child: child),
            child: LevelBadge(level: profile.level, size: 96),
          ),
          SizedBox(height: 18),
          Text(
            context.t('Seviye atladın!'),
            style: theme.textTheme.headlineSmall?.copyWith(
              color: style.xp,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 6),
          Text(
            context.t('Seviye {p0}: {p1}', {
              'p0': profile.level,
              'p1': context.t(profile.title),
            }),
            style: theme.textTheme.titleMedium,
          ),
          SizedBox(height: 6),
          Text(
            context.t('Sonraki seviye için {p0} XP', {'p0': profile.xpForNext}),
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.t('Devam')),
        ),
      ],
    );
  }
}

/// A cosmetic character class: emblem and motto.
class CharClass {
  const CharClass(this.id, this.name, this.icon, this.motto);
  final String id;
  final String name;
  final IconData icon;
  final String motto;
}

const List<CharClass> charClasses = [
  CharClass('savasci', 'Savaşçı', Icons.shield, 'Zor görevlerden kaçmaz.'),
  CharClass('buyucu', 'Büyücü', Icons.auto_awesome, 'Odak onun büyüsüdür.'),
  CharClass('okcu', 'Okçu', Icons.gps_fixed, 'Hedefini her gün vurur.'),
  CharClass('sifaci', 'Şifacı', Icons.healing, 'Önce kendine iyi bakar.'),
];

CharClass charClassById(String id) =>
    charClasses.firstWhere((c) => c.id == id, orElse: () => charClasses.first);

/// Today's quest, this week's challenge and the gold so far.
class QuestCard extends StatelessWidget {
  const QuestCard({super.key, required this.book});

  final QuestBook book;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = GameStyle.of(context);
    final q = book.today;
    final w = book.week;
    Widget line(
      IconData icon,
      String title,
      int progress,
      int goal,
      bool done,
      int reward,
      Key key,
    ) => Row(
      key: key,
      children: [
        Icon(
          done ? Icons.check_circle : icon,
          size: 20,
          color: done ? style.xp : theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              decoration: done ? TextDecoration.lineThrough : null,
            ),
          ),
        ),
        Text(
          goal == 0 ? '–' : '$progress / $goal',
          style: theme.textTheme.labelMedium,
        ),
        const SizedBox(width: 10),
        Icon(Icons.paid, size: 16, color: style.xp),
        const SizedBox(width: 2),
        Text(
          '$reward',
          style: theme.textTheme.labelMedium?.copyWith(color: style.xp),
        ),
      ],
    );
    return Material(
      key: const Key('quest-card'),
      color: theme.colorScheme.surface.withValues(alpha: 0.8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(style.radius),
        side: BorderSide(color: style.cardBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    context.t('Görevler tahtası'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontFamily: style.headlineFamily,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.savings, size: 18, color: style.xp),
                const SizedBox(width: 4),
                Text(
                  context.t('{p0} Altın', {'p0': book.gold}),
                  key: const Key('gold'),
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: style.xp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            line(
              Icons.flag,
              context.t('Günlük: {p0}', {'p0': context.t(q.kind.title)}),
              q.progress,
              q.goal,
              q.done,
              q.kind.reward,
              const Key('quest-today'),
            ),
            const SizedBox(height: 6),
            line(
              Icons.castle,
              context.t('Haftalık: {p0}', {
                'p0': context.t(WeekChallenge.title),
              }),
              w.progress,
              WeekChallenge.goal,
              w.done,
              WeekChallenge.reward,
              const Key('quest-week'),
            ),
          ],
        ),
      ),
    );
  }
}

/// The last [weeks] weeks as a grid of days (Monday at the top), darker for
/// more of the day done; empty days stay blank.
class ActivityHeatmap extends StatelessWidget {
  const ActivityHeatmap({
    super.key,
    required this.data,
    required this.today,
    this.weeks = 26,
  });

  final TaskData data;
  final LocalDate today;
  final int weeks;

  @override
  Widget build(BuildContext context) {
    final style = GameStyle.of(context);
    final scheme = Theme.of(context).colorScheme;
    final lastMonday = today.addDays(1 - today.weekday);
    final firstMonday = lastMonday.addDays(-7 * (weeks - 1));
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      reverse: true,
      child: Row(
        key: const Key('heatmap'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var w = 0; w < weeks; w++)
            Column(
              children: [
                for (var i = 0; i < 7; i++)
                  Builder(
                    builder: (context) {
                      final d = firstMonday.addDays(7 * w + i);
                      final future = d.isAfter(today);
                      final r = future ? null : QuestBook.dayRatio(data, d);
                      final color = r == null
                          ? scheme.onSurface.withValues(alpha: 0.06)
                          : Color.lerp(
                              scheme.onSurface.withValues(alpha: 0.12),
                              style.xp,
                              r,
                            )!;
                      return Tooltip(
                        message: r == null
                            ? context.t('{p0}: görev yok', {'p0': d.toIso()})
                            : context.t('{p0}: %{p1} yapıldı', {
                                'p0': d.toIso(),
                                'p1': (r * 100).round(),
                              }),
                        child: Container(
                          width: 14,
                          height: 14,
                          margin: const EdgeInsets.all(1.5),
                          decoration: BoxDecoration(
                            color: future ? Colors.transparent : color,
                            borderRadius: BorderRadius.circular(3),
                            border: d == today
                                ? Border.all(color: scheme.primary)
                                : null,
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

/// A short burst of confetti over the screen (perfect day).
void showConfetti(BuildContext context) {
  if (MediaQuery.disableAnimationsOf(context) ||
      WidgetsBinding
          .instance
          .platformDispatcher
          .accessibilityFeatures
          .reduceMotion) {
    return;
  }
  final overlay = Overlay.maybeOf(context);
  if (overlay == null) return;
  late OverlayEntry entry;
  entry = OverlayEntry(builder: (_) => _Confetti(onDone: () => entry.remove()));
  overlay.insert(entry);
}

/// An adjustable goal based only on actual completed tasks; it grants no XP.
class DailyGoalProgress extends StatelessWidget {
  const DailyGoalProgress({super.key, required this.done, required this.goal});
  final int done;
  final int goal;

  @override
  Widget build(BuildContext context) {
    final completed = done >= goal;
    final scheme = Theme.of(context).colorScheme;
    return Column(
      key: const Key('daily-goal'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              completed ? Icons.emoji_events : Icons.flag_outlined,
              size: 18,
              color: scheme.primary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                completed
                    ? context.t('Günlük hedef tamam! {p0} / {p1}', {
                        'p0': done,
                        'p1': goal,
                      })
                    : context.t('Günlük hedef: {p0} / {p1}', {
                        'p0': done,
                        'p1': goal,
                      }),
                key: const Key('daily-goal-label'),
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          key: const Key('daily-goal-progress'),
          value: (done / goal).clamp(0.0, 1.0),
          minHeight: 5,
          color: GameStyle.of(context).xp,
        ),
      ],
    );
  }
}

class _Confetti extends StatefulWidget {
  const _Confetti({required this.onDone});
  final VoidCallback onDone;

  @override
  State<_Confetti> createState() => _ConfettiState();
}

class _ConfettiState extends State<_Confetti>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..forward().whenComplete(widget.onDone);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = GameStyle.of(context);
    final scheme = Theme.of(context).colorScheme;
    return IgnorePointer(
      child: AnimatedBuilder(
        key: const Key('confetti'),
        animation: _c,
        builder: (_, _) => CustomPaint(
          size: MediaQuery.sizeOf(context),
          painter: _ConfettiPainter(_c.value, [
            style.xp,
            scheme.primary,
            scheme.secondary,
            scheme.tertiary,
          ]),
        ),
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.t, this.colors);
  final double t;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    // Deterministic pieces (no randomness: the same frame looks the same).
    for (var i = 0; i < 70; i++) {
      final x0 = ((i * 37) % 100) / 100 * size.width;
      final drift = (((i * 53) % 21) - 10) * 6.0 * t;
      final speed = 0.6 + ((i * 29) % 40) / 100;
      final y = -20 + (size.height + 40) * t * speed;
      final paint = Paint()
        ..color = colors[i % colors.length].withValues(alpha: 1 - t * 0.6);
      canvas.save();
      canvas.translate(x0 + drift, y);
      canvas.rotate(t * 6 + i);
      canvas.drawRect(const Rect.fromLTWH(-4, -2, 8, 4), paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}
