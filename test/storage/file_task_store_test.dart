import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gunluk_gorevler/src/domain/local_date.dart';
import 'package:gunluk_gorevler/src/domain/repeat_rule.dart';
import 'package:gunluk_gorevler/src/domain/task.dart';
import 'package:gunluk_gorevler/src/domain/task_data.dart';
import 'package:gunluk_gorevler/src/storage/file_task_store.dart';
import 'package:gunluk_gorevler/src/storage/task_store.dart';

TaskData sample(String title) => TaskData(
  tasks: [
    Task(
      id: 'a',
      title: title,
      note: '',
      schedule: [ScheduleSegment(LocalDate(2026, 11, 1), const DailyRule())],
      createdAt: DateTime.utc(2026, 11, 1),
      order: 0,
    ),
  ],
).withTick('a', LocalDate(2026, 11, 7), DateTime.utc(2026, 11, 7, 9));

void main() {
  group('defaultDataDirectory', () {
    test('Windows uses %APPDATA%', () {
      expect(
        defaultDataDirectory({
          'APPDATA': r'C:\Users\kullanici\AppData\Roaming',
        }, 'windows'),
        r'C:\Users\kullanici\AppData\Roaming\GunlukGorevler',
      );
      expect(
        defaultDataDirectory({'USERPROFILE': r'C:\Users\kullanici'}, 'windows'),
        r'C:\Users\kullanici\AppData\Roaming\GunlukGorevler',
      );
      expect(() => defaultDataDirectory({}, 'windows'), throwsStateError);
    });

    test('Linux follows XDG, macOS uses Application Support', () {
      expect(
        defaultDataDirectory({
          'HOME': '/home/k',
          'XDG_DATA_HOME': '/x',
        }, 'linux'),
        '/x/gunluk_gorevler',
      );
      expect(
        defaultDataDirectory({'HOME': '/home/k'}, 'linux'),
        '/home/k/.local/share/gunluk_gorevler',
      );
      expect(
        defaultDataDirectory({'HOME': '/Users/k'}, 'macos'),
        '/Users/k/Library/Application Support/GunlukGorevler',
      );
    });

    test('GUNLUK_GOREVLER_DIR overrides every platform', () {
      expect(
        defaultDataDirectory({
          'GUNLUK_GOREVLER_DIR': '/tmp/g',
          'APPDATA': 'C:',
        }, 'windows'),
        '/tmp/g',
      );
    });
  });

  group('FileTaskStore', () {
    late Directory dir;
    late FileTaskStore store;

    setUp(() async {
      dir = await Directory.systemTemp.createTemp('gunluk_gorevler_test');
      store = FileTaskStore('${dir.path}${Platform.pathSeparator}veri');
    });

    tearDown(() => dir.delete(recursive: true));

    test('nothing saved yet reads as missing and creates nothing', () async {
      expect(await store.load(), isA<LoadMissing>());
      expect(await Directory(store.directory).exists(), isFalse);
    });

    test('saves, replaces and reads back', () async {
      final now = DateTime(2026, 11, 7, 10);
      await store.save(sample('Su iç'), now: now);
      await store.save(sample('Kitap oku'), now: now);
      final loaded = await store.load();
      expect(loaded, isA<LoadOk>());
      final data = (loaded as LoadOk).data;
      expect(data.tasks.single.title, 'Kitap oku');
      expect(data.isDone('a', LocalDate(2026, 11, 7)), isTrue);
      expect(await File('${store.file.path}.tmp').exists(), isFalse);
    });

    test('backs up the previous file once a day and keeps the newest', () async {
      final keepTwo = FileTaskStore(store.directory, keepBackups: 2);
      await keepTwo.save(sample('1'), now: DateTime(2026, 11, 1, 10));
      // First write of a day copies the file as it was before the write.
      await keepTwo.save(sample('2'), now: DateTime(2026, 11, 2, 10));
      await keepTwo.save(sample('3'), now: DateTime(2026, 11, 2, 11));
      await keepTwo.save(sample('4'), now: DateTime(2026, 11, 3, 10));
      await keepTwo.save(sample('5'), now: DateTime(2026, 11, 4, 10));
      final names =
          keepTwo.backups
              .listSync()
              .map((e) => e.uri.pathSegments.last)
              .toList()
            ..sort();
      expect(names, ['gorevler-2026-11-03.json', 'gorevler-2026-11-04.json']);
      final backup = File(
        '${keepTwo.backups.path}${Platform.pathSeparator}gorevler-2026-11-04.json',
      );
      expect(await backup.readAsString(), contains('"title": "4"'));
    });

    test(
      'an unreadable file is reported, not overwritten, and can be set aside',
      () async {
        await Directory(store.directory).create(recursive: true);
        await store.file.writeAsString('{ yarım kalmış');
        final loaded = await store.load();
        expect(loaded, isA<LoadUnreadable>());
        expect(await store.file.readAsString(), '{ yarım kalmış');

        final movedTo = await store.setAsideUnreadable(
          now: DateTime(2026, 11, 7, 10, 30),
        );
        expect(await File(movedTo).readAsString(), '{ yarım kalmış');
        expect(await store.file.exists(), isFalse);
        expect(await store.load(), isA<LoadMissing>());
      },
    );

    test('a file from a newer version is reported as such', () async {
      await Directory(store.directory).create(recursive: true);
      await store.file.writeAsString(
        '{"app": "gunluk_gorevler", "schema_version": 9, "tasks": [], "completions": []}',
      );
      final loaded = await store.load();
      expect(loaded, isA<LoadUnreadable>());
      expect((loaded as LoadUnreadable).message, contains('daha yeni'));
    });

    test('a failed write leaves the previous file intact', () async {
      await store.save(sample('Önceki'), now: DateTime(2026, 11, 7, 10));
      // A directory where the temporary file should go makes the write fail.
      await Directory('${store.file.path}.tmp').create();
      await expectLater(
        store.save(sample('Yeni'), now: DateTime(2026, 11, 7, 11)),
        throwsA(isA<FileSystemException>()),
      );
      final loaded = await store.load() as LoadOk;
      expect(loaded.data.tasks.single.title, 'Önceki');
      // Later writes are not blocked by the failed one.
      await Directory('${store.file.path}.tmp').delete();
      await store.save(sample('Sonraki'), now: DateTime(2026, 11, 7, 12));
      expect(
        ((await store.load()) as LoadOk).data.tasks.single.title,
        'Sonraki',
      );
    });
  });

  test(
    'revealLocation opens the data folder with the system program',
    () async {
      final dir = await Directory.systemTemp.createTemp(
        'gunluk_gorevler_reveal',
      );
      addTearDown(() => dir.delete(recursive: true));
      final store = FileTaskStore('${dir.path}${Platform.pathSeparator}veri');
      final calls = <List<String>>[];
      store.runProcess = (program, args) async {
        calls.add([program, ...args]);
        return ProcessResult(0, 0, '', '');
      };
      expect(await store.revealLocation(), isTrue);
      expect(calls.single.last, store.directory);
      expect(calls.single.first, switch (Platform.operatingSystem) {
        'windows' => 'explorer',
        'macos' => 'open',
        _ => 'xdg-open',
      });
      expect(await Directory(store.directory).exists(), isTrue);

      store.runProcess = (_, _) async => throw const ProcessException('x', []);
      expect(await store.revealLocation(), isFalse);
    },
  );
}
