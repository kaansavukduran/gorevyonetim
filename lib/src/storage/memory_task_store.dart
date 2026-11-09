import '../app/settings.dart';
import '../domain/codec.dart';
import '../domain/task_data.dart';
import 'task_store.dart';

/// Keeps the data in memory only: used by tests and by the browser preview,
/// which says on screen that nothing is saved.
class MemoryTaskStore implements TaskStore {
  MemoryTaskStore({this.saved, this.failWith});

  /// The last saved file text, or null.
  String? saved;

  /// When set, every save throws this (to test the error path).
  Object? failWith;

  int saveCount = 0;

  AppSettings settings = const AppSettings();

  /// Backups offered for import in tests: name → file text.
  final Map<String, String> backups = {};

  /// Exported file texts, in order.
  final List<String> exported = [];

  @override
  Future<AppSettings> loadSettings() async => settings;

  @override
  Future<void> saveSettings(AppSettings settings) async =>
      this.settings = settings;

  @override
  Future<String?> exportBackup(TaskData data, {required DateTime now}) async {
    exported.add(encodeTaskData(data, savedAt: now));
    return null;
  }

  @override
  Future<List<BackupCandidate>> importCandidates() async => [
    for (final e in backups.entries)
      BackupCandidate(
        path: e.key,
        name: e.key,
        modified: DateTime.utc(2026),
        taskCount: decodeTaskData(e.value).tasks.length,
      ),
  ];

  @override
  Future<TaskData> readCandidate(BackupCandidate candidate) async =>
      decodeTaskData(backups[candidate.path]!);

  @override
  Future<String?> keepBeforeImport(
    TaskData data, {
    required DateTime now,
  }) async => null;

  @override
  String get location => 'Bu tarayıcı sekmesinin belleği (kaydedilmez)';

  @override
  String? get backupLocation => null;

  @override
  bool get persistent => false;

  @override
  bool get canRevealLocation => false;

  @override
  bool get usesSystemFilePicker => false;

  @override
  Future<LoadResult> load() async {
    final text = saved;
    if (text == null) return const LoadMissing();
    try {
      return LoadOk(decodeTaskData(text));
    } on NewerSchemaException catch (e) {
      return LoadUnreadable(e.toString());
    } on FormatException catch (e) {
      return LoadUnreadable('Dosya bozuk: ${e.message}');
    }
  }

  @override
  Future<void> save(TaskData data, {required DateTime now}) async {
    final error = failWith;
    if (error != null) throw error;
    saved = encodeTaskData(data, savedAt: now);
    saveCount++;
  }

  @override
  Future<bool> revealLocation() async => false;

  @override
  Future<String> setAsideUnreadable({required DateTime now}) async {
    saved = null;
    return 'bellek';
  }
}
