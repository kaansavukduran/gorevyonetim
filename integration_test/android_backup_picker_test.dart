import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gunluk_gorevler/src/app/task_controller.dart';
import 'package:gunluk_gorevler/src/domain/codec.dart';
import 'package:gunluk_gorevler/src/domain/repeat_rule.dart';
import 'package:gunluk_gorevler/src/domain/task.dart';
import 'package:gunluk_gorevler/src/storage/android_task_store.dart';
import 'package:gunluk_gorevler/src/storage/default_store.dart';
import 'package:gunluk_gorevler/src/storage/task_store.dart';
import 'package:integration_test/integration_test.dart';

// The host driver taps Android's real DocumentsUI using ADB/UIAutomator.
// No mocked channel, provider, storage permission or app test dependency.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('real Android picker export, cancel, reject and restore', (
    tester,
  ) async {
    const runId = String.fromEnvironment('PICKER_RUN_ID');
    expect(runId, isNotEmpty, reason: 'Run via tool/android_picker_smoke.sh');
    final native = await createDefaultStore() as AndroidTaskStore;
    final marker = File(
      '${File(native.location).parent.path}/picker-e2e-control.json',
    );
    final dir = Directory(
      '${File(native.location).parent.path}/picker-e2e-$runId',
    );
    final store = AndroidTaskStore(
      dir.path,
      channel: const MethodChannel('com.gunlukgorevler/files'),
    );
    final controller = TaskController(store: store);
    await controller.load();
    final task = controller.addTask(
      title: 'Türkçe görev: ışık, çiçek, öğün',
      note: 'Not, saat, adım ve tikler korunur.',
      rule: const DailyRule(),
      start: controller.today,
      time: ClockTime(23, 45),
      steps: ['Birinci adım', 'İkinci adım'],
    );
    controller.toggleStep(task.id, controller.today, task.steps.first.id);
    controller.toggle(task.id, controller.today);
    await controller.saved;
    final original = controller.data;
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Center(child: Text('Android yedekleme testi'))),
      ),
    );
    await tester.pumpAndSettle();

    var sequence = 0;
    Future<void> request(String step, {String? name, bool? passed}) async {
      final temp = File('${marker.path}.tmp');
      await temp.writeAsString(
        jsonEncode({
          'runId': runId,
          'requestId': ++sequence,
          'step': step,
          'fileName': name,
          'allPassed': passed,
        }),
        flush: true,
      );
      await temp.rename(marker.path);
    }

    var passed = false;
    try {
      final now = DateTime.now();
      final name = 'gunluk-gorevler-yedek-${controller.today.toIso()}.json';
      await request('export', name: name);
      expect(await store.exportBackup(original, now: now), name);

      // A different current list makes unintended replacement detectable.
      controller.addTask(
        title: 'Mevcut listede korunacak ikinci görev',
        rule: const DailyRule(),
        start: controller.today,
      );
      await controller.saved;
      final before = await File(store.location).readAsString();
      await request('export-cancel');
      expect(await store.exportBackup(original, now: now), isNull);
      expect(await File(store.location).readAsString(), before);

      await request('import-cancel');
      final cancelled = await store.importCandidates();
      expect(
        cancelled.where((c) => c.path == 'android:selected-document'),
        isEmpty,
      );
      expect(await File(store.location).readAsString(), before);

      await request('import', name: 'gunluk-gorevler-gecersiz.json');
      await expectLater(
        store.importCandidates(),
        throwsA(isA<FormatException>()),
      );
      expect(await File(store.location).readAsString(), before);

      await request('import', name: 'gunluk-gorevler-bozuk-utf8.json');
      await expectLater(
        store.importCandidates(),
        throwsA(isA<PlatformException>()),
      );
      expect(await File(store.location).readAsString(), before);

      await request('import', name: name);
      final candidates = await store.importCandidates();
      final selected = candidates.singleWhere(
        (c) => c.path == 'android:selected-document',
      );
      final restored = await store.readCandidate(selected);
      expect(
        encodeTaskData(restored, savedAt: now),
        encodeTaskData(original, savedAt: now),
      );
      expect(await File(store.location).readAsString(), before);
      expect(await controller.importBackup(restored), isNotNull);
      await controller.saved;
      final reopened = await store.load() as LoadOk;
      expect(
        encodeTaskData(reopened.data, savedAt: now),
        encodeTaskData(original, savedAt: now),
      );
      expect(
        decodeTaskData(await File(store.location).readAsString()).tasks,
        hasLength(1),
      );
      passed = true;
    } finally {
      await request('done', passed: passed);
      controller.dispose();
      if (await dir.exists()) await dir.delete(recursive: true);
    }
  }, skip: !Platform.isAndroid);
}
