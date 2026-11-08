import 'dart:io';

import '../app/settings.dart';
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

/// Where exported backups go: the person's Downloads folder (the Turkish
/// "İndirilenler" on Linux desktops that use it), else the home folder.
String downloadsDirectory(
  Map<String, String> env,
  String os, {
  bool Function(String path)? exists,
}) {
  final has = exists ?? (String p) => Directory(p).existsSync();
  final override = env['GUNLUK_GOREVLER_DOWNLOADS'];
  if (override != null && override.isNotEmpty) return override;
  if (os == 'windows') {
    final profile = env['USERPROFILE'];
    if (profile == null || profile.isEmpty) {
      throw StateError('USERPROFILE tanımlı değil');
    }
    return '$profile\\Downloads';
  }
  final home = _home(env);
  final xdg = env['XDG_DOWNLOAD_DIR'];
  if (xdg != null && xdg.isNotEmpty && has(xdg)) return xdg;
  for (final name in ['Downloads', 'İndirilenler']) {
    if (has('$home/$name')) return '$home/$name';
  }
  return home;
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
  FileTaskStore(this.directory, {this.keepBackups = 14, this.downloads});

  factory FileTaskStore.forThisDevice() => FileTaskStore(
    defaultDataDirectory(Platform.environment, Platform.operatingSystem),
    downloads: () =>
        downloadsDirectory(Platform.environment, Platform.operatingSystem),
  );

  final String directory;

  /// Folder for exported backups (resolved when needed).
  String Function()? downloads;
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

  File get _settingsFile => File('$directory${_sep}ayarlar.json');

  @override
  Future<AppSettings> loadSettings() async {
    try {
      if (!await _settingsFile.exists()) return const AppSettings();
      return AppSettings.decode(await _settingsFile.readAsString());
    } on FileSystemException {
      return const AppSettings();
    }
  }

  @override
  Future<void> saveSettings(AppSettings settings) async {
    await Directory(directory).create(recursive: true);
    final tmp = File('${_settingsFile.path}.tmp');
    await tmp.writeAsString(settings.encode(), flush: true);
    await tmp.rename(_settingsFile.path);
  }

  static String _stamp(DateTime now) {
    final l = now.toLocal();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${LocalDate.of(l).toIso()}-${two(l.hour)}${two(l.minute)}${two(l.second)}';
  }

  @override
  Future<String?> exportBackup(TaskData data, {required DateTime now}) async {
    final dir = downloads?.call() ?? directory;
    await Directory(dir).create(recursive: true);
    final target = File('$dir${_sep}gunluk-gorevler-yedek-${_stamp(now)}.json');
    await target.writeAsString(encodeTaskData(data, savedAt: now), flush: true);
    return target.path;
  }

  @override
  Future<List<BackupCandidate>> importCandidates() async {
    final dirs = <String>{backups.path, if (downloads != null) downloads!()};
    final found = <BackupCandidate>[];
    for (final dir in dirs) {
      final d = Directory(dir);
      if (!await d.exists()) continue;
      await for (final e in d.list()) {
        if (e is! File) continue;
        final name = e.uri.pathSegments.last;
        if (!name.endsWith('.json') || !name.contains('gorevler')) continue;
        try {
          final stat = await e.stat();
          if (stat.size > 50 * 1024 * 1024) continue;
          final data = decodeTaskData(await e.readAsString());
          found.add(
            BackupCandidate(
              path: e.path,
              name: name,
              modified: stat.modified,
              taskCount: data.tasks.length,
            ),
          );
        } on Object {
          // Not a backup of this app (or unreadable): not offered.
        }
      }
    }
    found.sort((a, b) => b.modified.compareTo(a.modified));
    return found;
  }

  @override
  Future<TaskData> readCandidate(BackupCandidate candidate) async =>
      decodeTaskData(await File(candidate.path).readAsString());

  @override
  Future<String?> keepBeforeImport(
    TaskData data, {
    required DateTime now,
  }) async {
    await backups.create(recursive: true);
    final target = File(
      '${backups.path}${_sep}gorevler-ice-aktarma-oncesi-${_stamp(now)}.json',
    );
    await target.writeAsString(encodeTaskData(data, savedAt: now), flush: true);
    return target.path;
  }

  /// Runs [program] with [arguments]; replaced in tests.
  Future<ProcessResult> Function(String program, List<String> arguments)
  runProcess = Process.run;

  @override
  Future<bool> revealLocation() async {
    try {
      await Directory(directory).create(recursive: true);
      final (program, args) = switch (Platform.operatingSystem) {
        'windows' => ('explorer', [directory]),
        'macos' => ('open', [directory]),
        _ => ('xdg-open', [directory]),
      };
      final result = await runProcess(program, args);
      // explorer.exe reports 1 even when it opened the folder.
      return Platform.isWindows || result.exitCode == 0;
    } on Object {
      return false;
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
