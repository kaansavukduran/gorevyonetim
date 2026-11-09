import '../app/settings.dart';
import '../domain/task_data.dart';

/// The outcome of reading the saved tasks.
sealed class LoadResult {
  const LoadResult();
}

/// Nothing saved yet (first start).
class LoadMissing extends LoadResult {
  const LoadMissing();
}

class LoadOk extends LoadResult {
  const LoadOk(this.data);
  final TaskData data;
}

/// A file exists but cannot be used. It is left untouched, and nothing is
/// written over it until the user decides.
class LoadUnreadable extends LoadResult {
  const LoadUnreadable(this.message);
  final String message;
}

abstract class TaskStore {
  /// Where the data lives, in words a person can find it by.
  String get location;

  /// Where earlier copies are kept, or null when there are none.
  String? get backupLocation;

  /// Whether the data survives a restart of the app.
  bool get persistent;

  /// Whether the system file manager can show this store's folder.
  bool get canRevealLocation;

  /// Import/export opens a native document picker rather than scanning Downloads.
  bool get usesSystemFilePicker;

  Future<LoadResult> load();

  /// Replaces the saved data with [data]. Throws when it cannot be written;
  /// the previous file then stays as it was.
  Future<void> save(TaskData data, {required DateTime now});

  /// Moves an unreadable file aside (never deletes it) so a new list can be
  /// started. Returns where it was moved to.
  Future<String> setAsideUnreadable({required DateTime now});

  Future<AppSettings> loadSettings();

  Future<void> saveSettings(AppSettings settings);

  /// Writes a copy of [data] where the person can find it (Downloads) and
  /// returns its path, or null when this store cannot export.
  Future<String?> exportBackup(TaskData data, {required DateTime now});

  /// Backup files this store can offer to import, newest first.
  Future<List<BackupCandidate>> importCandidates();

  /// Reads one candidate. Throws [FormatException] when it is not usable.
  Future<TaskData> readCandidate(BackupCandidate candidate);

  /// Keeps the current data aside before an import replaces it; returns
  /// where it went (null when this store keeps no files).
  Future<String?> keepBeforeImport(TaskData data, {required DateTime now});

  /// Opens the folder that holds the data in the system's file manager.
  /// Returns false when that is not possible here.
  Future<bool> revealLocation();
}

/// A file that looks like a backup of this app.
class BackupCandidate {
  const BackupCandidate({
    required this.path,
    required this.name,
    required this.modified,
    required this.taskCount,
  });

  final String path;
  final String name;
  final DateTime modified;
  final int taskCount;
}
