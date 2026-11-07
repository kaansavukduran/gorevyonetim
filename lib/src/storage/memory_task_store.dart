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

  @override
  String get location => 'Bu tarayıcı sekmesinin belleği (kaydedilmez)';

  @override
  String? get backupLocation => null;

  @override
  bool get persistent => false;

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
  Future<String> setAsideUnreadable({required DateTime now}) async {
    saved = null;
    return 'bellek';
  }
}
