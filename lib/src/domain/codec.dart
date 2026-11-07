import 'dart:convert';

import 'local_date.dart';
import 'task.dart';
import 'task_data.dart';

/// Version of the file format this code writes and reads.
const int schemaVersion = 1;

/// The file holds a newer format than this app understands. The file is
/// left untouched.
class NewerSchemaException implements Exception {
  NewerSchemaException(this.found);
  final int found;

  @override
  String toString() =>
      'Veri dosyası daha yeni bir sürümle yazılmış (biçim $found, '
      'bu uygulama $schemaVersion biçimini okur).';
}

String encodeTaskData(TaskData data, {required DateTime savedAt}) {
  final completions = <Map<String, Object?>>[];
  for (final t in data.completions.entries) {
    final days = t.value.keys.toList()..sort();
    for (final d in days) {
      completions.add({
        'task_id': t.key,
        'date': d.toIso(),
        'done_at': t.value[d]!.toUtc().toIso8601String(),
      });
    }
  }
  return const JsonEncoder.withIndent('  ').convert({
    'app': 'gunluk_gorevler',
    'schema_version': schemaVersion,
    'saved_at': savedAt.toUtc().toIso8601String(),
    'tasks': [for (final t in data.tasks) t.toJson()],
    'completions': completions,
  });
}

/// Reads a file written by [encodeTaskData]. Throws [FormatException] for a
/// malformed file and [NewerSchemaException] for a newer format.
TaskData decodeTaskData(String text) {
  final Object? root;
  try {
    root = jsonDecode(text);
  } on FormatException catch (e) {
    throw FormatException('Veri dosyası JSON değil: ${e.message}');
  }
  if (root is! Map<String, Object?>) {
    throw const FormatException('Veri dosyası bir nesne olmalı');
  }
  if (root['app'] != 'gunluk_gorevler') {
    throw const FormatException('Bu dosya Günlük Görevler dosyası değil');
  }
  final version = root['schema_version'];
  if (version is! int || version < 1) {
    throw const FormatException('Dosya biçim sürümü okunamadı');
  }
  if (version > schemaVersion) throw NewerSchemaException(version);

  final rawTasks = root['tasks'];
  final rawCompletions = root['completions'];
  if (rawTasks is! List<Object?>) {
    throw const FormatException('Görev listesi yok');
  }
  if (rawCompletions is! List<Object?>) {
    throw const FormatException('Tamamlama listesi yok');
  }
  final tasks = <Task>[];
  final ids = <String>{};
  for (final raw in rawTasks) {
    final task = Task.fromJson(raw);
    if (!ids.add(task.id)) {
      throw FormatException('Aynı kimlikle iki görev var', task.id);
    }
    tasks.add(task);
  }
  final completions = <String, Map<LocalDate, DateTime>>{};
  for (final raw in rawCompletions) {
    if (raw is! Map<String, Object?>) {
      throw const FormatException('Tamamlama kaydı bir nesne olmalı');
    }
    final id = raw['task_id'];
    final date = raw['date'];
    final at = raw['done_at'];
    if (id is! String || date is! String || at is! String) {
      throw const FormatException('Tamamlama kaydı eksik');
    }
    if (!ids.contains(id)) {
      throw FormatException('Tamamlama kaydı olmayan bir göreve ait', id);
    }
    completions.putIfAbsent(id, () => {})[LocalDate.parse(
      date,
    )] = DateTime.parse(at)
        .toUtc();
  }
  return TaskData(tasks: tasks, completions: completions);
}
