import 'package:flutter/material.dart';

import '../app/task_controller.dart';
import '../domain/repeat_rule.dart';
import '../domain/task.dart';
import '../domain/turkish_dates.dart';
import 'task_actions.dart';

enum _Filter { active, ended, all }

/// Every task: edit, end, restart, delete, reorder.
class TasksPage extends StatefulWidget {
  const TasksPage({super.key, required this.controller});

  final TaskController controller;

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  _Filter _filter = _Filter.active;

  TaskController get controller => widget.controller;

  bool _shown(Task t) {
    final active = t.hasFutureOn(controller.today);
    return switch (_filter) {
      _Filter.active => active,
      _Filter.ended => !active,
      _Filter.all => true,
    };
  }

  void _reorder(List<Task> shown, int oldIndex, int newIndex) {
    final moved = [...shown];
    moved.insert(newIndex, moved.removeAt(oldIndex));
    // Put the moved tasks back into the places the shown tasks held in the
    // full list, so hidden tasks keep their positions.
    final all = [for (final t in controller.data.tasks) t.id];
    final shownIds = {for (final t in shown) t.id};
    var k = 0;
    for (var i = 0; i < all.length; i++) {
      if (shownIds.contains(all[i])) all[i] = moved[k++].id;
    }
    controller.reorder(all);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tasks = [
      for (final t in controller.data.tasks)
        if (_shown(t)) t,
    ];
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Wrap(
                spacing: 16,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text('Tüm görevler', style: theme.textTheme.headlineSmall),
                  SegmentedButton<_Filter>(
                    key: const Key('tasks-filter'),
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(
                        value: _Filter.active,
                        label: Text('Süren'),
                      ),
                      ButtonSegment(value: _Filter.ended, label: Text('Biten')),
                      ButtonSegment(value: _Filter.all, label: Text('Tümü')),
                    ],
                    selected: {_filter},
                    onSelectionChanged: (s) =>
                        setState(() => _filter = s.first),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                'Düzenlemek için göreve tıkla, sırayı soldaki tutamaçtan sürükle. Sonlandırılan görevin geçmişi kalır.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            Expanded(
              child: tasks.isEmpty
                  ? Center(
                      child: Text(switch (_filter) {
                        _Filter.active => 'Süren görev yok.',
                        _Filter.ended => 'Biten görev yok.',
                        _Filter.all => 'Henüz görev yok.',
                      }, style: theme.textTheme.titleMedium),
                    )
                  : ReorderableListView.builder(
                      buildDefaultDragHandles: false,
                      padding: const EdgeInsets.only(bottom: 96),
                      itemCount: tasks.length,
                      onReorderItem: (a, b) => _reorder(tasks, a, b),
                      itemBuilder: (context, i) => _TaskCard(
                        key: ValueKey(tasks[i].id),
                        controller: controller,
                        task: tasks[i],
                        index: i,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({
    super.key,
    required this.controller,
    required this.task,
    required this.index,
  });

  final TaskController controller;
  final Task task;
  final int index;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final today = controller.today;
    final data = controller.data;
    final active = task.hasFutureOn(today);
    final rule = task.ruleOn(today) ?? task.lastRule;
    final stats = data.statsFor(
      task,
      from: today.addDays(-29),
      to: today,
      today: today,
    );
    final small = theme.textTheme.bodySmall?.copyWith(
      color: scheme.onSurfaceVariant,
    );

    final String state;
    if (task.isEndedOn(today)) {
      final end = task.schedule
          .lastWhere((s) => s.rule == null && !s.from.isAfter(today))
          .from;
      state = '${shortDate(end)} gününden beri sonlandırılmış';
    } else if (!active) {
      state = 'Günü geçti';
    } else if (rule is OnceRule) {
      state = rule.date == today ? 'Bugün' : 'Henüz gelmedi';
    } else if (task.startDate.isAfter(today)) {
      state = '${shortDate(task.startDate)} gününde başlayacak';
    } else {
      state =
          '${shortDate(task.startDate)} ${task.startDate.year} gününden beri';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: scheme.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: Key('task-card-${task.id}'),
          onTap: () => editTask(context, controller, task),
          onSecondaryTapUp: (d) =>
              showTaskMenuAt(context, controller, task, d.globalPosition),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
            child: Row(
              children: [
                ReorderableDragStartListener(
                  index: index,
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: MouseRegion(
                      cursor: SystemMouseCursors.grab,
                      child: Icon(Icons.drag_indicator_rounded),
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: active ? null : scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        [
                          if (rule != null) describeRule(rule),
                          state,
                        ].join('  ·  '),
                        style: small,
                      ),
                      if (task.note.isNotEmpty) Text(task.note, style: small),
                      const SizedBox(height: 4),
                      Text(
                        stats.settled == 0
                            ? 'Son 30 gün: henüz sonuçlanan gün yok'
                            : 'Son 30 gün: ${stats.settled} günün ${stats.done} gününde yapıldı'
                                  '${stats.streak > 0 ? '  ·  seri ${stats.streak} gün' : ''}',
                        key: Key('task-stats-${task.id}'),
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
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
