import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gunluk_gorevler/src/domain/codec.dart';
import 'package:gunluk_gorevler/src/domain/local_date.dart';
import 'package:gunluk_gorevler/src/domain/repeat_rule.dart';
import 'package:gunluk_gorevler/src/domain/task.dart';
import 'package:gunluk_gorevler/src/domain/task_data.dart';
import 'package:gunluk_gorevler/src/storage/android_task_store.dart';
import 'package:gunluk_gorevler/src/storage/task_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('com.gunlukgorevler/files');
  late Directory dir;
  setUp(() async {
    dir = await Directory.systemTemp.createTemp('gg-android');
  });
  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    await dir.delete(recursive: true);
  });

  test(
    'document export carries the real backup; picker cancellation is safe',
    () async {
      final calls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            calls.add(call);
            return call.method == 'exportBackup' ? 'yedek.json' : null;
          });
      final store = AndroidTaskStore(dir.path, channel: channel);
      expect(store.canRevealLocation, isFalse);
      expect(store.usesSystemFilePicker, isTrue);
      expect(
        await store.exportBackup(TaskData.empty, now: DateTime(2026, 11, 9)),
        'yedek.json',
      );
      final args = calls.single.arguments as Map;
      expect(decodeTaskData(args['text'] as String).tasks, isEmpty);
      expect(args['name'], 'gunluk-gorevler-yedek-2026-11-09.json');
      expect(await store.importCandidates(), isEmpty);
      expect(await File('${dir.path}/gorevler.json').exists(), isFalse);
    },
  );

  test('picked backups are validated before they can replace tasks', () async {
    var text = encodeTaskData(TaskData.empty, savedAt: DateTime.utc(2026));
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          channel,
          (_) async => {'name': 'seçilen.json', 'text': text},
        );
    final store = AndroidTaskStore(dir.path, channel: channel);
    final candidate = (await store.importCandidates()).single;
    expect(candidate.name, 'seçilen.json');
    expect((await store.readCandidate(candidate)).tasks, isEmpty);
    text = '{"schema_version":999}';
    await expectLater(
      store.importCandidates(),
      throwsA(isA<FormatException>()),
    );
    expect(await File('${dir.path}/gorevler.json').exists(), isFalse);
  });

  test(
    'cancel, bad content and provider failure preserve a saved task',
    () async {
      final store = AndroidTaskStore(dir.path, channel: channel);
      final now = DateTime.utc(2026, 11, 9, 10);
      final data = TaskData(
        tasks: [
          Task(
            id: 'protected',
            title: 'Korunan görev',
            note: 'Silinmemeli',
            schedule: [ScheduleSegment(LocalDate.of(now), const DailyRule())],
            createdAt: now,
            order: 0,
          ),
        ],
      );
      await store.save(data, now: now);
      final before = await File(store.location).readAsString();
      Object? result;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (_) async {
            if (result is PlatformException) throw result;
            return result;
          });
      expect(await store.exportBackup(data, now: now), isNull);
      expect(await store.importCandidates(), isEmpty);
      result = {'name': 'bozuk.json', 'text': '{bozuk'};
      await expectLater(
        store.importCandidates(),
        throwsA(isA<FormatException>()),
      );
      result = PlatformException(code: 'DOCUMENT', message: 'Dosya okunamadı');
      await expectLater(
        store.importCandidates(),
        throwsA(isA<PlatformException>()),
      );
      expect(await File(store.location).readAsString(), before);
      expect(
        (await store.load() as LoadOk).data.tasks.single.title,
        'Korunan görev',
      );
    },
  );
}
