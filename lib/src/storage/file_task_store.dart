import 'dart:io';

import '../domain/codec.dart';
import '../domain/local_date.dart';
import '../domain/task_data.dart';
import 'task_store.dart';

/// The folder the app keeps its file in.
///
/// [env] and [os] are passed in so that every platform's rule can be tested
/// on any machine. `GUNLUK_GOREVLER_DIR` overrides the default.
String defaultDataDirectory(Map<String, String> env, String os) {
  final override = env['GUNLUK_GOREVLER_DIR'];
  if (override != null && override.isNotEmpty) return override;
  switch (os) {
    case 'windows':
      final appData = env['APPDATA'];
      if (appData != null && appData.isNotEmpty) {
        return '$appData\\GunlukGorevler';
      }
      final profile = env['USERPROFILE'];
      if (profile != null && profile.isNotEmpty) {
        return '$profile\\AppData\\Roaming\\GunlukGorevler';
      }
      throw StateError('APPDATA ve USERPROFILE tanımlı değil');
    case 'macos':
      return '${_home(env)}/Library/Application Support/GunlukGorevler';
    default:
      final xdg = env['XDG_DATA_HOME'];
      if (xdg != null && xdg.isNotEmpty) return '$xdg/gunluk_gorevler';
      return '${_home(env)}/.local/share/gunluk_gorevler';
  }
}

String _home(Map<String, String> env) {
  final home = env['HOME'];
  if (home == null || home.isEmpty) throw StateError('HOME tanımlı değil');
  return home;
}

/// Saves everything as one JSON file, written whole to a temporary file and
/// then renamed over the old one, so a crash mid-write leaves the previous
/// file intact. Once a day the file as it was is copied to `yedekler/`
/// (the last [keepBackups] days are kept).
class FileTaskStore implements TaskStore {
  FileTaskStore(this.directory, {this.keepBackups = 14});

  factory FileTaskStore.forThisDevice() => FileTaskStore(
    defaultDataDirectory(Platform.environment, Platform.operatingSystem),
  );

  final String directory;
  final int keepBackups;

  /// Writes are queued so two saves never interleave.
  Future<void> _queue = Future.value();

  String get _sep => Platform.pathSeparator;
  File get file => File('$directory${_sep}gorevler.json');
  File get _temp => File('$directory${_sep}gorevler.json.tmp');
  Directory get backups => Directory('$directory${_sep}yedekler');

  @override
  String get location => file.path;

  @override
  String? get backupLocation => backups.path;

  @override
  bool get persistent => true;

  @override
  Future<LoadResult> load() async {
    if (!await file.exists()) return const LoadMissing();
    final String text;
    try {
      text = await file.readAsString();
    } on FileSystemException catch (e) {
      return LoadUnreadable('Dosya okunamadı: ${e.message}');
    } on FormatException {
      return const LoadUnreadable('Dosya UTF-8 metni değil');
    }
    try {
      return LoadOk(decodeTaskData(text));
    } on NewerSchemaException catch (e) {
      return LoadUnreadable(e.toString());
    } on FormatException catch (e) {
      final where = e.source is String ? ' (${e.source})' : '';
      return LoadUnreadable('Dosya bozuk: ${e.message}$where');
    }
  }

  @override
  Future<void> save(TaskData data, {required DateTime now}) {
    final next = _queue.then((_) => _write(data, now));
    // A failed write must not block the ones after it.
    _queue = next.catchError((Object _) {});
    return next;
  }

  Future<void> _write(TaskData data, DateTime now) async {
    await Directory(directory).create(recursive: true);
    await _backupOncePerDay(now);
    final text = encodeTaskData(data, savedAt: now);
    await _temp.writeAsString(text, flush: true);
    await _temp.rename(file.path);
  }

  Future<void> _backupOncePerDay(DateTime now) async {
    if (!await file.exists()) return;
    final day = LocalDate.of(now).toIso();
    final target = File('${backups.path}${_sep}gorevler-$day.json');
    if (await target.exists()) return;
    await backups.create(recursive: true);
    await file.copy(target.path);
    await _pruneBackups();
  }

  Future<void> _pruneBackups() async {
    final names = <File>[];
    await for (final e in backups.list()) {
      final name = e.uri.pathSegments.last;
      if (e is File &&
          RegExp(r'^gorevler-\d{4}-\d{2}-\d{2}\.json$').hasMatch(name)) {
        names.add(e);
      }
    }
    names.sort((a, b) => a.path.compareTo(b.path));
    while (names.length > keepBackups) {
      await names.removeAt(0).delete();
    }
  }

  @override
  Future<String> setAsideUnreadable({required DateTime now}) async {
    final stamp = now
        .toLocal()
        .toIso8601String()
        .replaceAll(':', '-')
        .split('.')
        .first;
    var target = File('$directory${_sep}gorevler.okunamayan-$stamp.json');
    var n = 1;
    while (await target.exists()) {
      target = File('$directory${_sep}gorevler.okunamayan-$stamp-$n.json');
      n++;
    }
    await file.rename(target.path);
    return target.path;
  }
}
