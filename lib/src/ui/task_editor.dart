import 'package:flutter/material.dart';

import '../domain/local_date.dart';
import '../domain/repeat_rule.dart';
import '../domain/task.dart';
import '../domain/turkish_dates.dart';

/// What the editor returns.
class TaskDraft {
  const TaskDraft({
    required this.title,
    required this.note,
    required this.rule,
    required this.start,
    this.difficulty = Difficulty.orta,
    this.time,
    this.steps = const [],
  });

  final String title;
  final String note;
  final RepeatRule rule;
  final Difficulty difficulty;
  final ClockTime? time;

  /// Step titles in order (empty lines dropped).
  final List<String> steps;

  /// First day (new tasks only; a one-off starts on its own date).
  final LocalDate start;
}

enum _Kind { daily, weekly, once }

Future<LocalDate?> pickDate(
  BuildContext context, {
  required LocalDate initial,
  String? help,
}) async {
  final picked = await showDatePicker(
    context: context,
    initialDate: DateTime(initial.year, initial.month, initial.day),
    firstDate: DateTime(2000),
    lastDate: DateTime(2100, 12, 31),
    helpText: help,
    cancelText: 'İptal',
    confirmText: 'Seç',
  );
  if (picked == null) return null;
  return LocalDate(picked.year, picked.month, picked.day);
}

/// Opens the add/edit dialog. [existing] null means a new task.
Future<TaskDraft?> showTaskEditor(
  BuildContext context, {
  Task? existing,
  required LocalDate defaultStart,
  required LocalDate today,
  String initialTitle = '',
  RepeatRule? initialRule,
  LocalDate? effectiveFrom,
  String? heading,
}) => showDialog<TaskDraft>(
  context: context,
  builder: (_) => _TaskEditor(
    existing: existing,
    defaultStart: defaultStart,
    today: today,
    initialTitle: initialTitle,
    initialRule: initialRule,
    effectiveFrom: effectiveFrom,
    heading: heading,
  ),
);

class _TaskEditor extends StatefulWidget {
  const _TaskEditor({
    required this.existing,
    required this.defaultStart,
    required this.today,
    required this.initialTitle,
    required this.initialRule,
    required this.effectiveFrom,
    required this.heading,
  });

  final Task? existing;
  final LocalDate defaultStart;
  final LocalDate today;
  final String initialTitle;
  final RepeatRule? initialRule;
  final LocalDate? effectiveFrom;
  final String? heading;

  @override
  State<_TaskEditor> createState() => _TaskEditorState();
}

class _TaskEditorState extends State<_TaskEditor> {
  late final TextEditingController _title;
  late final TextEditingController _note;
  late _Kind _kind;
  late Set<int> _weekdays;
  late LocalDate _onceDate;
  late LocalDate _start;
  late Difficulty _difficulty;
  ClockTime? _time;
  late final TextEditingController _steps;
  String? _error;

  bool get _isNew => widget.existing == null;

  @override
  void initState() {
    super.initState();
    final t = widget.existing;
    _title = TextEditingController(text: t?.title ?? widget.initialTitle);
    _note = TextEditingController(text: t?.note ?? '');
    _difficulty = t?.difficulty ?? Difficulty.orta;
    _time = t?.time;
    _steps = TextEditingController(
      text: t?.steps.map((s) => s.title).join('\n') ?? '',
    );
    final rule =
        widget.initialRule ??
        (t == null
            ? const DailyRule()
            : (t.ruleOn(widget.today) ?? t.lastRule)) ??
        const DailyRule();
    _start = widget.defaultStart;
    _weekdays = {1, 2, 3, 4, 5};
    _onceDate = widget.defaultStart;
    switch (rule) {
      case DailyRule():
        _kind = _Kind.daily;
      case WeeklyRule(:final weekdays):
        _kind = _Kind.weekly;
        _weekdays = {...weekdays};
      case OnceRule(:final date):
        _kind = _Kind.once;
        _onceDate = date;
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _note.dispose();
    _steps.dispose();
    super.dispose();
  }

  RepeatRule? _rule() => switch (_kind) {
    _Kind.daily => const DailyRule(),
    _Kind.weekly => _weekdays.isEmpty ? null : WeeklyRule(_weekdays),
    _Kind.once => OnceRule(_onceDate),
  };

  void _submit() {
    final title = _title.text.trim();
    if (title.isEmpty) {
      setState(() => _error = 'Görev adı yaz.');
      return;
    }
    final rule = _rule();
    if (rule == null) {
      setState(() => _error = 'En az bir gün seç.');
      return;
    }
    Navigator.of(context).pop(
      TaskDraft(
        title: title,
        note: _note.text.trim(),
        rule: rule,
        start: _start,
        difficulty: _difficulty,
        time: _time,
        steps: [
          for (final l in _steps.text.split('\n'))
            if (l.trim().isNotEmpty) l.trim(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text(widget.heading ?? (_isNew ? 'Yeni görev' : 'Görevi düzenle')),
      scrollable: true,
      content: SizedBox(
        width: 460,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              key: const Key('editor-title'),
              controller: _title,
              autofocus: true,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              decoration: const InputDecoration(
                labelText: 'Görev adı',
                hintText: 'Örneğin: 2 litre su iç',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('editor-note'),
              controller: _note,
              minLines: 1,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Not (isteğe bağlı)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Text('Zorluk', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            SegmentedButton<Difficulty>(
              key: const Key('editor-difficulty'),
              showSelectedIcon: false,
              segments: [
                for (final d in Difficulty.values)
                  ButtonSegment(
                    value: d,
                    label: Text('${d.label} · ${d.baseXp} XP'),
                  ),
              ],
              selected: {_difficulty},
              onSelectionChanged: (v) => setState(() => _difficulty = v.first),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const SizedBox(width: 90, child: Text('Hatırlatma')),
                OutlinedButton.icon(
                  key: const Key('editor-time'),
                  icon: const Icon(Icons.schedule, size: 18),
                  label: Text(_time?.format() ?? 'Saat yok'),
                  onPressed: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay(
                        hour: _time?.hour ?? 9,
                        minute: _time?.minute ?? 0,
                      ),
                      cancelText: 'İptal',
                      confirmText: 'Seç',
                      helpText: 'Hatırlatma saati',
                    );
                    if (picked != null) {
                      setState(
                        () => _time = ClockTime(picked.hour, picked.minute),
                      );
                    }
                  },
                ),
                if (_time != null)
                  IconButton(
                    key: const Key('editor-time-clear'),
                    tooltip: 'Saati kaldır',
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() => _time = null),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('editor-steps'),
              controller: _steps,
              minLines: 1,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: 'Adımlar (isteğe bağlı, her satıra bir adım)',
                hintText: 'Isın\nKoş\nEsne',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            Text('Ne zaman?', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            SegmentedButton<_Kind>(
              key: const Key('editor-kind'),
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(
                  value: _Kind.daily,
                  label: Text('Her gün'),
                  icon: Icon(Icons.repeat_rounded),
                ),
                ButtonSegment(
                  value: _Kind.weekly,
                  label: Text('Belirli günler'),
                  icon: Icon(Icons.date_range_rounded),
                ),
                ButtonSegment(
                  value: _Kind.once,
                  label: Text('Tek sefer'),
                  icon: Icon(Icons.event_rounded),
                ),
              ],
              selected: {_kind},
              onSelectionChanged: (s) => setState(() {
                _kind = s.first;
                _error = null;
              }),
            ),
            const SizedBox(height: 12),
            if (_kind == _Kind.weekly) _weekdayPicker(theme),
            if (_kind == _Kind.once)
              _dateRow(
                key: const Key('editor-once-date'),
                label: 'Gün',
                date: _onceDate,
                onPick: (d) => setState(() => _onceDate = d),
              ),
            if (_isNew && _kind != _Kind.once)
              _dateRow(
                key: const Key('editor-start-date'),
                label: 'Başlangıç',
                date: _start,
                onPick: (d) => setState(() => _start = d),
              ),
            if (!_isNew && widget.effectiveFrom != null && _kind != _Kind.once)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Tekrar değişirse yeni kural ${shortDate(widget.effectiveFrom!)} '
                  'gününden itibaren geçerli olur; önceki günler eski kurala göre kalır.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  _error!,
                  key: const Key('editor-error'),
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('İptal'),
        ),
        FilledButton(
          key: const Key('editor-save'),
          onPressed: _submit,
          child: Text(_isNew ? 'Ekle' : 'Kaydet'),
        ),
      ],
    );
  }

  Widget _weekdayPicker(ThemeData theme) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (var d = 1; d <= 7; d++)
            FilterChip(
              key: Key('editor-weekday-$d'),
              label: Text(weekdayShort[d - 1]),
              tooltip: weekdayNames[d - 1],
              selected: _weekdays.contains(d),
              onSelected: (on) => setState(() {
                on ? _weekdays.add(d) : _weekdays.remove(d);
                _error = null;
              }),
            ),
        ],
      ),
      const SizedBox(height: 6),
      Wrap(
        spacing: 4,
        children: [
          TextButton(
            onPressed: () => setState(() => _weekdays = {1, 2, 3, 4, 5}),
            child: const Text('Hafta içi'),
          ),
          TextButton(
            onPressed: () => setState(() => _weekdays = {6, 7}),
            child: const Text('Hafta sonu'),
          ),
        ],
      ),
      const SizedBox(height: 4),
    ],
  );

  Widget _dateRow({
    required Key key,
    required String label,
    required LocalDate date,
    required ValueChanged<LocalDate> onPick,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        SizedBox(width: 90, child: Text(label)),
        Flexible(
          child: OutlinedButton.icon(
            key: key,
            icon: const Icon(Icons.calendar_today_rounded, size: 18),
            label: Text(
              '${longDate(date)}, ${weekdayName(date)}',
              overflow: TextOverflow.ellipsis,
            ),
            onPressed: () async {
              final picked = await pickDate(
                context,
                initial: date,
                help: label,
              );
              if (picked != null) onPick(picked);
            },
          ),
        ),
      ],
    ),
  );
}
