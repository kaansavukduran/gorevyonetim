import 'package:flutter/material.dart';

import '../app/task_controller.dart';
import '../domain/local_date.dart';
import '../domain/repeat_rule.dart';
import '../domain/task.dart';
import '../domain/task_data.dart';
import '../domain/turkish_dates.dart';
import 'game_widgets.dart';
import 'status_style.dart';
import 'task_actions.dart';
import 'task_editor.dart';
import 'themes.dart';

/// One day's list: the week at the top, a field to add, the tasks to tick.
class DayPage extends StatelessWidget {
  const DayPage({
    super.key,
    required this.controller,
    required this.day,
    required this.onDayChanged,
    this.onOpenCharacter,
  });

  final TaskController controller;
  final LocalDate day;
  final ValueChanged<LocalDate> onDayChanged;
  final VoidCallback? onOpenCharacter;

  @override
  Widget build(BuildContext context) {
    final data = controller.data;
    final today = controller.today;
    final tasks = data.tasksOn(day);
    // Tasks with a time come first, in time order; the rest keep their order.
    final open =
        [
          for (final t in tasks)
            if (!data.isDone(t.id, day)) t,
        ]..sort((a, b) {
          final ta = a.time, tb = b.time;
          if (ta != null && tb != null) return ta.compareTo(tb);
          if (ta != null) return -1;
          if (tb != null) return 1;
          return a.order.compareTo(b.order);
        });
    final done = [
      for (final t in tasks)
        if (data.isDone(t.id, day)) t,
    ];

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              sliver: SliverList.list(
                children: [
                  if (controller.settings.gameMode) ...[
                    HeroStrip(
                      profile: controller.profile,
                      onTap: onOpenCharacter,
                      icon: charClassById(controller.settings.charClass).icon,
                    ),
                    const SizedBox(height: 10),
                    QuestCard(book: controller.quests),
                    const SizedBox(height: 14),
                  ],
                  _DayTitle(day: day, today: today, onDayChanged: onDayChanged),
                  const SizedBox(height: 12),
                  _WeekStrip(
                    controller: controller,
                    day: day,
                    onDayChanged: onDayChanged,
                  ),
                  const SizedBox(height: 20),
                  _QuickAdd(controller: controller, day: day),
                  const SizedBox(height: 16),
                  _DaySummary(
                    day: day,
                    today: today,
                    total: tasks.length,
                    done: done.length,
                  ),
                ],
              ),
            ),
            if (tasks.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _EmptyDay(isPast: day.isBefore(today)),
              ),
            if (open.isNotEmpty) ...[
              _sectionHeader(
                context,
                day.isBefore(today)
                    ? 'Yapılmayanlar (${open.length})'
                    : 'Yapılacaklar (${open.length})',
              ),
              SliverList.builder(
                itemCount: open.length,
                itemBuilder: (_, i) =>
                    TaskTile(controller: controller, task: open[i], day: day),
              ),
            ],
            if (done.isNotEmpty) ...[
              _sectionHeader(context, 'Tamamlananlar (${done.length})'),
              SliverList.builder(
                itemCount: done.length,
                itemBuilder: (_, i) =>
                    TaskTile(controller: controller, task: done[i], day: day),
              ),
            ],
            const SliverToBoxAdapter(child: SizedBox(height: 48)),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String text) => SliverPadding(
    padding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
    sliver: SliverToBoxAdapter(
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelLarge
            ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
    ),
  );
}

/// "Bugün" / weekday, the date (click to pick another), and a way back.
class _DayTitle extends StatelessWidget {
  const _DayTitle({
    required this.day,
    required this.today,
    required this.onDayChanged,
  });

  final LocalDate day;
  final LocalDate today;
  final ValueChanged<LocalDate> onDayChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                relativeDay(day, today),
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              InkWell(
                key: const Key('day-title'),
                borderRadius: BorderRadius.circular(8),
                onTap: () async {
                  final picked = await pickDate(
                    context,
                    initial: day,
                    help: 'Gün seç',
                  );
                  if (picked != null) onDayChanged(picked);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${longDate(day)}, ${weekdayName(day)}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Icon(
                        Icons.arrow_drop_down,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (day != today)
          TextButton.icon(
            key: const Key('day-today'),
            icon: const Icon(Icons.today_rounded, size: 18),
            label: const Text('Bugüne dön'),
            onPressed: () => onDayChanged(today),
          ),
      ],
    );
  }
}

/// The week (Monday to Sunday) of the shown day: click a day to open it.
/// Each day shows how much of it is done, so the week is checked at a glance.
class _WeekStrip extends StatelessWidget {
  const _WeekStrip({
    required this.controller,
    required this.day,
    required this.onDayChanged,
  });

  final TaskController controller;
  final LocalDate day;
  final ValueChanged<LocalDate> onDayChanged;

  @override
  Widget build(BuildContext context) {
    final monday = day.addDays(1 - day.weekday);
    return Row(
      children: [
        IconButton(
          key: const Key('week-prev'),
          tooltip: 'Önceki hafta',
          icon: const Icon(Icons.chevron_left_rounded),
          onPressed: () => onDayChanged(day.addDays(-7)),
        ),
        for (var i = 0; i < 7; i++)
          Expanded(
            child: _DayPill(
              controller: controller,
              date: monday.addDays(i),
              selected: monday.addDays(i) == day,
              onTap: () => onDayChanged(monday.addDays(i)),
            ),
          ),
        IconButton(
          key: const Key('week-next'),
          tooltip: 'Sonraki hafta',
          icon: const Icon(Icons.chevron_right_rounded),
          onPressed: () => onDayChanged(day.addDays(7)),
        ),
      ],
    );
  }
}

class _DayPill extends StatelessWidget {
  const _DayPill({
    required this.controller,
    required this.date,
    required this.selected,
    required this.onTap,
  });

  final TaskController controller;
  final LocalDate date;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final data = controller.data;
    final today = controller.today;
    final tasks = data.tasksOn(date);
    final done = tasks.where((t) => data.isDone(t.id, date)).length;
    final isToday = date == today;
    final future = date.isAfter(today);

    final String tip;
    if (tasks.isEmpty) {
      tip = '${shortDate(date)}: görev yok';
    } else if (future) {
      tip = '${shortDate(date)}: ${tasks.length} görev planlı';
    } else {
      tip = '${shortDate(date)}: ${tasks.length} görevden $done tanesi yapıldı';
    }

    final Widget mark;
    if (tasks.isEmpty || future) {
      mark = const SizedBox(height: 14);
    } else if (done == tasks.length) {
      mark = Icon(Icons.check_rounded, size: 14, color: scheme.primary);
    } else {
      mark = Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: done / tasks.length,
            minHeight: 4,
            color: date.isBefore(today) ? scheme.error : scheme.primary,
            backgroundColor: scheme.surfaceContainerHighest,
          ),
        ),
      );
    }

    return Tooltip(
      message: tip,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Material(
          color: selected ? scheme.primaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            key: Key('week-day-${date.toIso()}'),
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                children: [
                  Text(
                    weekdayShort[date.weekday - 1],
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: selected
                          ? scheme.onPrimaryContainer
                          : scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${date.day}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: isToday ? FontWeight.w800 : FontWeight.w500,
                      color: isToday
                          ? scheme.primary
                          : (selected ? scheme.onPrimaryContainer : null),
                      decoration: isToday ? TextDecoration.underline : null,
                      decorationColor: scheme.primary,
                    ),
                  ),
                  mark,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DaySummary extends StatelessWidget {
  const _DaySummary({
    required this.day,
    required this.today,
    required this.total,
    required this.done,
  });

  final LocalDate day;
  final LocalDate today;
  final int total;
  final int done;

  @override
  Widget build(BuildContext context) {
    if (total == 0) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    if (!day.isAfter(today) && done == total) {
      return Container(
        key: const Key('day-all-done'),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: scheme.primaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: scheme.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                day == today
                    ? 'Bugünün hepsi tamam: $total / $total'
                    : 'O günün hepsi yapılmış: $total / $total',
                key: const Key('day-summary'),
                style: theme.textTheme.titleSmall?.copyWith(
                  color: scheme.onPrimaryContainer,
                ),
              ),
            ),
          ],
        ),
      );
    }
    final String text;
    if (day.isAfter(today)) {
      text = '$total görev planlı';
    } else if (day.isBefore(today)) {
      text =
          '$total görevden $done tanesi yapıldı, ${total - done} tanesi yapılmadı';
    } else {
      text = '$total görevden $done tanesi tamamlandı';
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          text,
          key: const Key('day-summary'),
          style: theme.textTheme.titleSmall,
        ),
        if (!day.isAfter(today)) ...[
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: done / total,
              minHeight: 6,
              backgroundColor: scheme.surfaceContainerHighest,
            ),
          ),
        ],
      ],
    );
  }
}

enum _QuickRepeat { daily, weekdays, once }

class _QuickAdd extends StatefulWidget {
  const _QuickAdd({required this.controller, required this.day});

  final TaskController controller;
  final LocalDate day;

  @override
  State<_QuickAdd> createState() => _QuickAddState();
}

class _QuickAddState extends State<_QuickAdd> {
  final _text = TextEditingController();
  final _focus = FocusNode();
  _QuickRepeat _repeat = _QuickRepeat.daily;

  @override
  void dispose() {
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  RepeatRule get _rule => switch (_repeat) {
    _QuickRepeat.daily => const DailyRule(),
    _QuickRepeat.weekdays => WeeklyRule(const {1, 2, 3, 4, 5}),
    _QuickRepeat.once => OnceRule(widget.day),
  };

  String _label(_QuickRepeat r) => switch (r) {
    _QuickRepeat.daily => 'Her gün',
    _QuickRepeat.weekdays => 'Hafta içi',
    _QuickRepeat.once => 'Sadece ${shortDate(widget.day)}',
  };

  void _add() {
    final title = _text.text.trim();
    if (title.isEmpty) return;
    widget.controller.addTask(title: title, rule: _rule, start: widget.day);
    _text.clear();
    _focus.requestFocus();
  }

  Future<void> _details() async {
    await addTaskWithEditor(
      context,
      widget.controller,
      start: widget.day,
      initialTitle: _text.text.trim(),
      initialRule: _rule,
    );
    _text.clear();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return TextField(
      key: const Key('quick-add-field'),
      controller: _text,
      focusNode: _focus,
      textInputAction: TextInputAction.done,
      onSubmitted: (_) => _add(),
      decoration: InputDecoration(
        hintText: 'Görev ekle ve Enter\'a bas',
        filled: true,
        fillColor: scheme.surfaceContainerLow,
        prefixIcon: const Icon(Icons.add_rounded),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        suffixIcon: Padding(
          padding: const EdgeInsets.only(right: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              PopupMenuButton<Object>(
                key: const Key('quick-repeat'),
                tooltip: 'Ne sıklıkla?',
                onSelected: (v) {
                  if (v is _QuickRepeat) {
                    setState(() => _repeat = v);
                  } else {
                    _details();
                  }
                },
                itemBuilder: (_) => [
                  for (final r in _QuickRepeat.values)
                    CheckedPopupMenuItem<Object>(
                      key: Key('quick-repeat-${r.name}'),
                      value: r,
                      checked: r == _repeat,
                      child: Text(_label(r)),
                    ),
                  const PopupMenuDivider(),
                  const PopupMenuItem<Object>(
                    key: Key('quick-details'),
                    value: 'details',
                    child: Text('Ayrıntılı ekle (not, belirli günler)…'),
                  ),
                ],
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.repeat_rounded,
                        size: 18,
                        color: scheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _label(_repeat),
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      Icon(
                        Icons.arrow_drop_down,
                        color: scheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: _text,
                builder: (_, value, _) => FilledButton(
                  key: const Key('quick-add-button'),
                  onPressed: value.text.trim().isEmpty ? null : _add,
                  child: const Text('Ekle'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyDay extends StatelessWidget {
  const _EmptyDay({required this.isPast});

  final bool isPast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.checklist_rounded,
            size: 48,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(height: 12),
          Text(
            isPast ? 'Bu gün için görev yoktu.' : 'Bu gün için görev yok.',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Yukarıya bir görev yaz, Enter\'a bas. Her gün listende olur;\n'
            'sıklığı yandaki seçimle değiştirebilirsin.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// One task on one day. Click to tick, right-click or ⋮ for more.
class TaskTile extends StatefulWidget {
  const TaskTile({
    super.key,
    required this.controller,
    required this.task,
    required this.day,
  });

  final TaskController controller;
  final Task task;
  final LocalDate day;

  @override
  State<TaskTile> createState() => _TaskTileState();
}

class _TaskTileState extends State<TaskTile> {
  bool _open = false;

  TaskController get controller => widget.controller;
  Task get task => widget.task;
  LocalDate get day => widget.day;

  void _toggle() {
    final before = controller.data;
    final nowDone = withGameFeedback(
      context,
      controller,
      () => controller.toggle(task.id, day),
    );
    if (!nowDone) {
      showUndoSnack(
        context,
        '"${task.title}" işareti kaldırıldı.',
        onUndo: () => controller.restore(before),
      );
    }
  }

  void _toggleStep(String stepId) => withGameFeedback(
    context,
    controller,
    () => controller.toggleStep(task.id, day, stepId),
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final style = GameStyle.of(context);
    final game = controller.settings.gameMode;
    final data = controller.data;
    final today = controller.today;
    final status = data.statusOf(task, day, today);
    final done = status == DayStatus.done;
    final future = day.isAfter(today);
    final rule = task.ruleOn(day) ?? task.lastRule;
    final streak = day == today ? data.streakFor(task, today) : 0;
    final stepsDone = data.stepsDone(task.id, day);
    final now = controller.now();
    final late =
        task.time != null &&
        day == today &&
        !done &&
        task.time!.minutes <= now.hour * 60 + now.minute;

    Widget chip(String text, {Key? key, Color? color, IconData? icon}) =>
        Container(
          key: key,
          margin: const EdgeInsets.only(left: 6),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: (color ?? scheme.secondary).withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 14, color: color ?? scheme.secondary),
                const SizedBox(width: 4),
              ],
              Text(
                text,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: color ?? scheme.secondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        );

    final diffColor = switch (task.difficulty) {
      Difficulty.kolay => scheme.primary,
      Difficulty.orta => style.xp,
      Difficulty.zor => scheme.error,
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: Material(
        key: Key('task-tile-${task.id}'),
        color: done
            ? scheme.surfaceContainerLow.withValues(alpha: 0.85)
            : scheme.surface.withValues(alpha: 0.92),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: late
                ? scheme.error.withValues(alpha: 0.7)
                : style.cardBorder,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: future ? null : _toggle,
          onSecondaryTapUp: (d) =>
              showTaskMenuAt(context, controller, task, d.globalPosition),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 4, 8),
            child: Column(
              children: [
                Row(
                  children: [
                    Tooltip(
                      message: future
                          ? 'İleri bir gün işaretlenemez'
                          : (done
                                ? 'İşareti kaldır'
                                : 'Yapıldı olarak işaretle'),
                      child: Transform.scale(
                        scale: 1.2,
                        child: Checkbox(
                          key: Key('task-check-${task.id}'),
                          value: done,
                          shape: const CircleBorder(),
                          onChanged: future ? null : (_) => _toggle(),
                          semanticLabel:
                              '${task.title}: ${StatusStyle.of(status, scheme).label}',
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 180),
                            style: theme.textTheme.titleMedium!.copyWith(
                              decoration: done
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: done
                                  ? scheme.onSurfaceVariant
                                  : scheme.onSurface,
                            ),
                            child: Text(task.title),
                          ),
                          const SizedBox(height: 2),
                          _StatusLine(
                            status: status,
                            rule: rule,
                            note: task.note,
                            doneAt: data.doneAt(task.id, day),
                            day: day,
                          ),
                        ],
                      ),
                    ),
                    if (task.time != null)
                      chip(
                        late
                            ? '${task.time!.format()} geçti'
                            : task.time!.format(),
                        key: Key('task-time-${task.id}'),
                        icon: Icons.schedule,
                        color: late ? scheme.error : scheme.onSurfaceVariant,
                      ),
                    if (task.steps.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: TextButton.icon(
                          key: Key('task-steps-${task.id}'),
                          style: TextButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                          ),
                          onPressed: () => setState(() => _open = !_open),
                          icon: Icon(
                            _open ? Icons.expand_less : Icons.expand_more,
                            size: 18,
                          ),
                          label: Text(
                            '${stepsDone.length}/${task.steps.length} adım',
                          ),
                        ),
                      ),
                    if (game)
                      Tooltip(
                        message:
                            '${task.difficulty.label}: ${task.difficulty.baseXp} XP',
                        child: chip(
                          task.difficulty.label,
                          key: Key('task-diff-${task.id}'),
                          color: diffColor,
                        ),
                      ),
                    if (streak >= 2)
                      Tooltip(
                        message: 'Üst üste $streak gün yapıldı',
                        child: chip(
                          '$streak gün',
                          key: Key('task-streak-${task.id}'),
                          icon: Icons.whatshot,
                          color: scheme.tertiary,
                        ),
                      ),
                    TaskMenu(controller: controller, task: task),
                  ],
                ),
                if (_open && task.steps.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(40, 0, 8, 4),
                    child: Column(
                      children: [
                        for (final st in task.steps)
                          CheckboxListTile(
                            key: Key('step-${task.id}-${st.id}'),
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            controlAffinity: ListTileControlAffinity.leading,
                            value: stepsDone.contains(st.id),
                            onChanged: future
                                ? null
                                : (_) => _toggleStep(st.id),
                            title: Text(
                              st.title,
                              style: TextStyle(
                                decoration: stepsDone.contains(st.id)
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusLine extends StatelessWidget {
  const _StatusLine({
    required this.status,
    required this.rule,
    required this.note,
    required this.doneAt,
    required this.day,
  });

  final DayStatus status;
  final RepeatRule? rule;
  final String note;
  final DateTime? doneAt;
  final LocalDate day;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final small = theme.textTheme.bodySmall?.copyWith(
      color: scheme.onSurfaceVariant,
    );
    final parts = <InlineSpan>[];

    void add(InlineSpan span) {
      if (parts.isNotEmpty) parts.add(TextSpan(text: '  ·  ', style: small));
      parts.add(span);
    }

    switch (status) {
      case DayStatus.done:
        final at = doneAt!;
        final tickDay = LocalDate.of(at);
        add(
          TextSpan(
            text: tickDay == day
                ? '${clockTime(at)} işaretlendi'
                : '${shortDate(tickDay)} ${clockTime(at)} sonradan işaretlendi',
            style: small?.copyWith(
              color: scheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      case DayStatus.missed:
        add(
          TextSpan(
            text: 'Yapılmadı',
            style: small?.copyWith(
              color: scheme.error,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      case DayStatus.upcoming:
        add(TextSpan(text: 'Planlı', style: small));
      case DayStatus.pending:
      case DayStatus.notScheduled:
        break;
    }
    if (rule != null) add(TextSpan(text: describeRule(rule!), style: small));
    if (note.isNotEmpty) add(TextSpan(text: note, style: small));
    if (parts.isEmpty) return const SizedBox.shrink();
    return Text.rich(
      TextSpan(children: parts),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}
