import 'package:flutter/material.dart';

import '../app/task_controller.dart';
import '../domain/local_date.dart';
import '../domain/task.dart';
import '../domain/task_data.dart';
import '../domain/turkish_dates.dart';
import 'status_style.dart';

/// A grid of tasks × days: what was done and what was not.
class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key, required this.controller});

  final TaskController controller;

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  int _span = 7;

  /// How many spans back from today the grid ends (0 = ends today).
  int _back = 0;

  static const double _cell = 30;
  static const double _gap = 4;
  static const double _nameWidth = 200;
  static const double _sumWidth = 92;

  TaskController get controller => widget.controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final today = controller.today;
    final data = controller.data;
    final end = today.addDays(-_span * _back);
    final start = end.addDays(-(_span - 1));
    final days = [for (var i = 0; i < _span; i++) start.addDays(i)];
    final tasks = [
      for (final t in data.tasks)
        if (days.any((d) => t.isScheduledOn(d) || data.isDone(t.id, d))) t,
    ];

    var done = 0;
    var missed = 0;
    var pending = 0;
    for (final t in tasks) {
      final s = data.statsFor(t, from: start, to: end, today: today);
      done += s.done;
      missed += s.missed;
      if (s.todayPending) pending++;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('Kontrol', style: theme.textTheme.headlineSmall),
              SegmentedButton<int>(
                key: const Key('history-span'),
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: 7, label: Text('7 gün')),
                  ButtonSegment(value: 14, label: Text('14 gün')),
                  ButtonSegment(value: 30, label: Text('30 gün')),
                ],
                selected: {_span},
                onSelectionChanged: (s) => setState(() {
                  _span = s.first;
                  _back = 0;
                }),
              ),
              IconButton(
                key: const Key('history-back'),
                tooltip: 'Daha eski',
                icon: const Icon(Icons.chevron_left_rounded),
                onPressed: () => setState(() => _back++),
              ),
              Text('${shortDate(start)} – ${shortDate(end)} ${end.year}'),
              IconButton(
                key: const Key('history-forward'),
                tooltip: 'Daha yeni',
                icon: const Icon(Icons.chevron_right_rounded),
                onPressed: _back == 0 ? null : () => setState(() => _back--),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Text(
            tasks.isEmpty
                ? 'Bu aralıkta görev yok.'
                : 'Bu aralıkta $done kez yapıldı, $missed kez yapılmadı'
                      '${pending > 0 ? ', bugün $pending görev bekliyor' : ''}.',
            key: const Key('history-summary'),
            style: theme.textTheme.titleMedium,
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: _Legend(),
        ),
        const Divider(height: 1),
        Expanded(
          child: tasks.isEmpty
              ? const SizedBox.shrink()
              : Scrollbar(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _headerRow(theme, days, today),
                          for (final t in tasks)
                            _taskRow(theme, t, days, start, end, today),
                          const SizedBox(height: 4),
                          _totalRow(theme, tasks, days, today),
                        ],
                      ),
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _headerRow(ThemeData theme, List<LocalDate> days, LocalDate today) {
    final small = theme.textTheme.labelSmall;
    return Row(
      children: [
        const SizedBox(width: _nameWidth),
        for (final d in days)
          Container(
            width: _cell,
            margin: const EdgeInsets.symmetric(horizontal: _gap / 2),
            alignment: Alignment.center,
            child: Column(
              children: [
                Text(
                  weekdayShort[d.weekday - 1],
                  style: small?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  '${d.day}',
                  style: small?.copyWith(
                    fontWeight: d == today ? FontWeight.w800 : FontWeight.w500,
                    color: d == today ? theme.colorScheme.primary : null,
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(width: _gap),
        SizedBox(
          width: _sumWidth,
          child: Text('Yapıldı', style: small, textAlign: TextAlign.end),
        ),
      ],
    );
  }

  Widget _taskRow(
    ThemeData theme,
    Task task,
    List<LocalDate> days,
    LocalDate start,
    LocalDate end,
    LocalDate today,
  ) {
    final data = controller.data;
    final stats = data.statsFor(task, from: start, to: end, today: today);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: _nameWidth,
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                task.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ),
          for (final d in days)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: _gap / 2),
              child: _cellFor(task, d, today, scheme),
            ),
          const SizedBox(width: _gap),
          SizedBox(
            width: _sumWidth,
            child: Text(
              stats.settled == 0
                  ? '–'
                  : '${stats.done}/${stats.settled}  %${(100 * stats.done / stats.settled).round()}',
              key: Key('history-sum-${task.id}'),
              textAlign: TextAlign.end,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cellFor(Task task, LocalDate d, LocalDate today, ColorScheme scheme) {
    final data = controller.data;
    final status = data.statusOf(task, d, today);
    final at = data.doneAt(task.id, d);
    final label =
        '${task.title} · ${shortDate(d)} ${weekdayName(d)}: '
        '${StatusStyle.of(status, scheme).label}'
        '${at != null ? ' (${clockTime(at)})' : ''}';
    final canToggle =
        !d.isAfter(today) && status != DayStatus.notScheduled ||
        status == DayStatus.done;
    return Tooltip(
      message: canToggle ? '$label\nTıkla: değiştir' : label,
      child: Semantics(
        label: label,
        button: canToggle,
        child: InkWell(
          key: Key('cell-${task.id}-${d.toIso()}'),
          borderRadius: BorderRadius.circular(8),
          onTap: canToggle ? () => controller.toggle(task.id, d) : null,
          child: StatusCell(status: status, size: _cell, highlight: d == today),
        ),
      ),
    );
  }

  Widget _totalRow(
    ThemeData theme,
    List<Task> tasks,
    List<LocalDate> days,
    LocalDate today,
  ) {
    final data = controller.data;
    final small = theme.textTheme.labelSmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return Row(
      children: [
        SizedBox(
          width: _nameWidth,
          child: Text('Gün toplamı', style: small),
        ),
        for (final d in days)
          Builder(
            builder: (_) {
              final expected = [
                for (final t in tasks)
                  if (t.isScheduledOn(d) || data.isDone(t.id, d)) t,
              ];
              final done = expected.where((t) => data.isDone(t.id, d)).length;
              return Container(
                width: _cell,
                margin: const EdgeInsets.symmetric(horizontal: _gap / 2),
                alignment: Alignment.center,
                child: Text(
                  expected.isEmpty || d.isAfter(today)
                      ? ''
                      : '$done/${expected.length}',
                  style: small,
                ),
              );
            },
          ),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 16,
      runSpacing: 6,
      children: [
        for (final s in DayStatus.values)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              StatusCell(status: s, size: 18),
              const SizedBox(width: 6),
              Text(
                StatusStyle.of(s, scheme).label,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
      ],
    );
  }
}
