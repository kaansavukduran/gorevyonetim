import 'package:flutter/material.dart';

import '../app/task_controller.dart';
import '../domain/local_date.dart';
import '../domain/repeat_rule.dart';
import '../domain/task.dart';
import '../domain/task_data.dart';
import '../domain/turkish_dates.dart';
import 'status_style.dart';
import 'task_actions.dart';
import 'task_editor.dart';

/// One day's list: tick what is done, add tasks, move between days.
class DayPage extends StatelessWidget {
  const DayPage({
    super.key,
    required this.controller,
    required this.day,
    required this.onDayChanged,
  });

  final TaskController controller;
  final LocalDate day;
  final ValueChanged<LocalDate> onDayChanged;

  @override
  Widget build(BuildContext context) {
    final data = controller.data;
    final today = controller.today;
    final tasks = data.tasksOn(day);
    final open = [
      for (final t in tasks)
        if (!data.isDone(t.id, day)) t,
    ];
    final done = [
      for (final t in tasks)
        if (data.isDone(t.id, day)) t,
    ];

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820),
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              sliver: SliverList.list(
                children: [
                  _DayHeader(
                    day: day,
                    today: today,
                    onDayChanged: onDayChanged,
                  ),
                  const SizedBox(height: 12),
                  _DaySummary(
                    day: day,
                    today: today,
                    total: tasks.length,
                    done: done.length,
                  ),
                  const SizedBox(height: 16),
                  _QuickAdd(controller: controller, day: day),
                  const SizedBox(height: 8),
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
            const SliverToBoxAdapter(child: SizedBox(height: 96)),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String text) => SliverPadding(
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
    sliver: SliverToBoxAdapter(
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          letterSpacing: 0.4,
        ),
      ),
    ),
  );
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({
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
    final isToday = day == today;
    return Row(
      children: [
        IconButton.outlined(
          key: const Key('day-prev'),
          tooltip: 'Önceki gün (Alt + ←)',
          icon: const Icon(Icons.chevron_left_rounded),
          onPressed: () => onDayChanged(day.addDays(-1)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: InkWell(
            key: const Key('day-title'),
            borderRadius: BorderRadius.circular(12),
            onTap: () async {
              final picked = await pickDate(
                context,
                initial: day,
                help: 'Gün seç',
              );
              if (picked != null) onDayChanged(picked);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    relativeDay(day, today),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${longDate(day)}, ${weekdayName(day)}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (!isToday)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton.icon(
              key: const Key('day-today'),
              icon: const Icon(Icons.today_rounded),
              label: const Text('Bugün'),
              onPressed: () => onDayChanged(today),
            ),
          ),
        IconButton.outlined(
          key: const Key('day-next'),
          tooltip: 'Sonraki gün (Alt + →)',
          icon: const Icon(Icons.chevron_right_rounded),
          onPressed: () => onDayChanged(day.addDays(1)),
        ),
      ],
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
    final String text;
    if (day.isAfter(today)) {
      text = '$total görev planlı';
    } else if (done == total) {
      text = 'Hepsi tamam: $total / $total';
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
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: day.isAfter(today) ? 0 : done / total,
            minHeight: 8,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
          ),
        ),
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

  void _add() {
    final title = _text.text.trim();
    if (title.isEmpty) return;
    widget.controller.addTask(title: title, rule: _rule, start: widget.day);
    _text.clear();
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    key: const Key('quick-add-field'),
                    controller: _text,
                    focusNode: _focus,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _add(),
                    decoration: const InputDecoration(
                      hintText: 'Yeni görev yaz, Enter ile ekle',
                      prefixIcon: Icon(Icons.add_task_rounded),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                IconButton(
                  key: const Key('quick-add-details'),
                  tooltip: 'Ayrıntılı ekle (not, belirli günler, başlangıç)',
                  icon: const Icon(Icons.tune_rounded),
                  onPressed: () async {
                    await addTaskWithEditor(
                      context,
                      widget.controller,
                      start: widget.day,
                      initialTitle: _text.text.trim(),
                      initialRule: _rule,
                    );
                    _text.clear();
                  },
                ),
                const SizedBox(width: 4),
                FilledButton(
                  key: const Key('quick-add-button'),
                  onPressed: _add,
                  child: const Text('Ekle'),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text('Tekrar:', style: theme.textTheme.bodySmall),
                for (final r in _QuickRepeat.values)
                  ChoiceChip(
                    key: Key('quick-repeat-${r.name}'),
                    label: Text(switch (r) {
                      _QuickRepeat.daily => 'Her gün',
                      _QuickRepeat.weekdays => 'Hafta içi',
                      _QuickRepeat.once => 'Sadece ${shortDate(widget.day)}',
                    }),
                    selected: _repeat == r,
                    onSelected: (_) => setState(() => _repeat = r),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
          ],
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
            size: 56,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(height: 12),
          Text(
            isPast ? 'Bu gün için görev yoktu.' : 'Bu gün için görev yok.',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Yukarıya yazıp Enter\'a bas: görev her gün listende olur.',
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

/// One task on one day.
class TaskTile extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final data = controller.data;
    final today = controller.today;
    final status = data.statusOf(task, day, today);
    final done = status == DayStatus.done;
    final future = day.isAfter(today);
    final rule = task.ruleOn(day) ?? task.lastRule;

    void toggle() {
      final before = controller.data;
      final nowDone = controller.toggle(task.id, day);
      if (!nowDone) {
        showUndoSnack(
          context,
          '"${task.title}" işareti kaldırıldı.',
          onUndo: () => controller.restore(before),
        );
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: Card(
        key: Key('task-tile-${task.id}'),
        elevation: 0,
        margin: EdgeInsets.zero,
        color: done ? scheme.surfaceContainerLow : scheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: scheme.outlineVariant),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: future ? null : toggle,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(6, 6, 4, 6),
            child: Row(
              children: [
                Tooltip(
                  message: future
                      ? 'İleri bir gün işaretlenemez'
                      : (done ? 'İşareti kaldır' : 'Yapıldı olarak işaretle'),
                  child: Transform.scale(
                    scale: 1.25,
                    child: Checkbox(
                      key: Key('task-check-${task.id}'),
                      value: done,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                      onChanged: future ? null : (_) => toggle(),
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
                      Text(
                        task.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          decoration: done ? TextDecoration.lineThrough : null,
                          color: done
                              ? scheme.onSurfaceVariant
                              : scheme.onSurface,
                        ),
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
                if (MediaQuery.sizeOf(context).width >= 700)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: WeekStrip(
                      controller: controller,
                      task: task,
                      endingAt: day,
                    ),
                  ),
                TaskMenu(controller: controller, task: task),
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

/// The seven days ending at [endingAt], oldest first.
class WeekStrip extends StatelessWidget {
  const WeekStrip({
    super.key,
    required this.controller,
    required this.task,
    required this.endingAt,
  });

  final TaskController controller;
  final Task task;
  final LocalDate endingAt;

  @override
  Widget build(BuildContext context) {
    final data = controller.data;
    final today = controller.today;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 6; i >= 0; i--)
          Builder(
            builder: (context) {
              final d = endingAt.addDays(-i);
              final status = data.statusOf(task, d, today);
              return Tooltip(
                message:
                    '${shortDate(d)} ${weekdayName(d)}: '
                    '${StatusStyle.of(status, Theme.of(context).colorScheme).label}',
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1.5),
                  child: StatusCell(
                    status: status,
                    size: 16,
                    highlight: d == today,
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}
