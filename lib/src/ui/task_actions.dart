import 'package:flutter/material.dart';

import '../app/task_controller.dart';
import '../domain/local_date.dart';
import '../domain/repeat_rule.dart';
import '../domain/task.dart';
import '../domain/turkish_dates.dart';
import 'task_editor.dart';

void showUndoSnack(
  BuildContext context,
  String message, {
  VoidCallback? onUndo,
}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
      width: MediaQuery.sizeOf(context).width > 560 ? 520 : null,
      duration: const Duration(seconds: 6),
      action: onUndo == null
          ? null
          : SnackBarAction(label: 'Geri al', onPressed: onUndo),
    ),
  );
}

Future<void> addTaskWithEditor(
  BuildContext context,
  TaskController controller, {
  required LocalDate start,
  String initialTitle = '',
  RepeatRule? initialRule,
  ClockTime? initialTime,
}) async {
  final draft = await showTaskEditor(
    context,
    defaultStart: start,
    today: controller.today,
    initialTitle: initialTitle,
    initialRule: initialRule,
    initialTime: initialTime,
  );
  if (draft == null) return;
  controller.addTask(
    title: draft.title,
    note: draft.note,
    rule: draft.rule,
    start: draft.start,
    difficulty: draft.difficulty,
    time: draft.time,
    steps: draft.steps,
  );
}

Future<void> editTask(
  BuildContext context,
  TaskController controller,
  Task task,
) async {
  final draft = await showTaskEditor(
    context,
    existing: task,
    defaultStart: task.startDate,
    today: controller.today,
    effectiveFrom: controller.effectiveFrom(task, const DailyRule()),
  );
  if (draft == null) return;
  controller.updateTask(
    task.id,
    title: draft.title,
    note: draft.note,
    rule: draft.rule,
    difficulty: draft.difficulty,
    time: () => draft.time,
    steps: draft.steps,
  );
}

void endTask(BuildContext context, TaskController controller, Task task) {
  final before = controller.data;
  controller.endTask(task.id);
  showUndoSnack(
    context,
    '"${task.title}" sonlandırıldı. Geçmiş kayıtları duruyor.',
    onUndo: () => controller.restore(before),
  );
}

Future<void> restartTask(
  BuildContext context,
  TaskController controller,
  Task task,
) async {
  final draft = await showTaskEditor(
    context,
    existing: task,
    defaultStart: controller.today,
    today: controller.today,
    initialRule: task.lastRule ?? const DailyRule(),
    heading: 'Yeniden başlat',
  );
  if (draft == null) return;
  controller.restartTask(task.id, draft.rule);
  controller.updateTask(
    task.id,
    title: draft.title,
    note: draft.note,
    difficulty: draft.difficulty,
    time: () => draft.time,
    steps: draft.steps,
  );
}

Future<void> deleteTask(
  BuildContext context,
  TaskController controller,
  Task task,
) async {
  final ticks = controller.data.completions[task.id]?.length ?? 0;
  final sure = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Görev silinsin mi?'),
      content: Text(
        '"${task.title}" ve ${ticks == 0 ? 'hiç işareti yok' : '$ticks günlük işareti'} '
        'kalıcı olarak silinir.\n\n'
        'Geçmişi saklamak istersen "Sonlandır" seç: görev bugünden sonra '
        'görünmez, eski günler kalır.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Vazgeç'),
        ),
        FilledButton.tonal(
          key: const Key('confirm-delete'),
          style: FilledButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.error,
          ),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Kalıcı olarak sil'),
        ),
      ],
    ),
  );
  if (sure != true || !context.mounted) return;
  final before = controller.data;
  controller.deleteTask(task.id);
  showUndoSnack(
    context,
    '"${task.title}" silindi.',
    onUndo: () => controller.restore(before),
  );
}

/// What the task menu offers (the ⋮ button and a right-click show the same).
List<PopupMenuEntry<String>> taskMenuItems(
  TaskController controller,
  Task task,
) {
  final ended = task.isEndedOn(controller.today);
  return [
    const PopupMenuItem(
      value: 'edit',
      child: ListTile(
        leading: Icon(Icons.edit_rounded),
        title: Text('Düzenle'),
      ),
    ),
    if (ended)
      const PopupMenuItem(
        value: 'restart',
        child: ListTile(
          leading: Icon(Icons.play_arrow_rounded),
          title: Text('Yeniden başlat'),
        ),
      )
    else
      PopupMenuItem(
        value: 'end',
        child: ListTile(
          leading: const Icon(Icons.stop_circle_outlined),
          title: const Text('Sonlandır'),
          subtitle: Text(
            '${shortDate(controller.today)} ve sonrasında görünmez',
          ),
        ),
      ),
    const PopupMenuItem(
      value: 'delete',
      child: ListTile(
        leading: Icon(Icons.delete_outline_rounded),
        title: Text('Sil'),
      ),
    ),
  ];
}

void runTaskMenu(
  BuildContext context,
  TaskController controller,
  Task task,
  String? value,
) {
  switch (value) {
    case 'edit':
      editTask(context, controller, task);
    case 'end':
      endTask(context, controller, task);
    case 'restart':
      restartTask(context, controller, task);
    case 'delete':
      deleteTask(context, controller, task);
  }
}

/// Opens the task menu where the mouse was right-clicked.
Future<void> showTaskMenuAt(
  BuildContext context,
  TaskController controller,
  Task task,
  Offset globalPosition,
) async {
  final overlay = Overlay.of(context).context.findRenderObject()! as RenderBox;
  final value = await showMenu<String>(
    context: context,
    position: RelativeRect.fromRect(
      globalPosition & const Size(1, 1),
      Offset.zero & overlay.size,
    ),
    items: taskMenuItems(controller, task),
  );
  if (context.mounted) runTaskMenu(context, controller, task, value);
}

/// The ⋮ menu of a task.
class TaskMenu extends StatelessWidget {
  const TaskMenu({super.key, required this.controller, required this.task});

  final TaskController controller;
  final Task task;

  @override
  Widget build(BuildContext context) => PopupMenuButton<String>(
    key: Key('task-menu-${task.id}'),
    tooltip: 'Görev seçenekleri (sağ tık da açar)',
    icon: const Icon(Icons.more_vert_rounded),
    onSelected: (value) => runTaskMenu(context, controller, task, value),
    itemBuilder: (context) => taskMenuItems(controller, task),
  );
}
