import 'package:flutter/services.dart';

import '../domain/codec.dart';
import '../domain/local_date.dart';
import '../domain/task_data.dart';
import 'file_task_store.dart';
import 'task_store.dart';

/// Private app storage and Android's document picker; no storage permission.
class AndroidTaskStore extends FileTaskStore {
  AndroidTaskStore(super.directory, {required this.channel});

  final MethodChannel channel;
  TaskData? _picked;

  @override
  bool get canRevealLocation => false;

  @override
  bool get usesSystemFilePicker => true;

  @override
  Future<String?> exportBackup(TaskData data, {required DateTime now}) =>
      channel.invokeMethod<String>('exportBackup', {
        'name': 'gunluk-gorevler-yedek-${LocalDate.of(now).toIso()}.json',
        'text': encodeTaskData(data, savedAt: now),
      });

  @override
  Future<List<BackupCandidate>> importCandidates() async {
    _picked = null;
    final result = await channel.invokeMapMethod<String, String>('pickBackup');
    final candidates = await super.importCandidates();
    if (result != null) {
      _picked = decodeTaskData(result['text']!);
      candidates.insert(
        0,
        BackupCandidate(
          path: 'android:selected-document',
          name: result['name'] ?? 'Seçilen yedek',
          modified: DateTime.now(),
          taskCount: _picked!.tasks.length,
        ),
      );
    }
    return candidates;
  }

  @override
  Future<TaskData> readCandidate(BackupCandidate candidate) async {
    if (candidate.path == 'android:selected-document' && _picked != null) {
      return _picked!;
    }
    return super.readCandidate(candidate);
  }

  @override
  Future<bool> revealLocation() async => false;
}
