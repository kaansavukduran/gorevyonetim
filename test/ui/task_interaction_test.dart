import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gunluk_gorevler/src/app/settings.dart';
import 'package:gunluk_gorevler/src/app/task_controller.dart';
import 'package:gunluk_gorevler/src/domain/repeat_rule.dart';
import 'package:gunluk_gorevler/src/domain/task.dart';
import 'package:gunluk_gorevler/src/storage/memory_task_store.dart';

import 'app_test.dart' show pumpApp, quickAdd;

Future<void> enterTime(WidgetTester tester, String hour, String minute) async {
  final fields = find.descendant(
    of: find.byType(TimePickerDialog),
    matching: find.byType(TextField),
  );
  expect(fields, findsNWidgets(2));
  await tester.enterText(fields.at(0), hour);
  await tester.enterText(fields.at(1), minute);
  await tester.tap(find.text('Kaydet'));
  await tester.pumpAndSettle();
}

Future<void> mouseDrag(
  WidgetTester tester,
  String from,
  String to, {
  bool below = false,
}) async {
  final source = find.byKey(Key('task-drag-$from'));
  final destination = find.byKey(Key('task-drag-$to'));
  final end = tester.getCenter(destination) + Offset(0, below ? 42 : -42);
  final gesture = await tester.startGesture(
    tester.getCenter(source),
    kind: PointerDeviceKind.mouse,
  );
  await tester.pump();
  final start = tester.getCenter(source);
  for (var i = 1; i <= 12; i++) {
    await gesture.moveTo(Offset.lerp(start, end, i / 12)!);
    await tester.pump(const Duration(milliseconds: 80));
  }
  await tester.pump(const Duration(milliseconds: 400));
  await gesture.moveBy(Offset(0, below ? 3 : -3));
  await tester.pump(const Duration(milliseconds: 100));
  await gesture.up();
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'mouse drags tasks up and down without changing hidden tasks or ticks',
    (tester) async {
      final store = MemoryTaskStore()
        ..settings = const AppSettings(gameMode: false);
      final ids = <String>[];
      final h = await pumpApp(
        tester,
        store: store,
        size: const Size(1500, 1200),
        seed: (c) {
          ids.add(
            c
                .addTask(
                  title: 'A',
                  rule: const DailyRule(),
                  start: c.today,
                  time: ClockTime(18, 0),
                )
                .id,
          );
          ids.add(
            c
                .addTask(
                  title: 'Gizli',
                  rule: OnceRule(c.today.addDays(1)),
                  start: c.today.addDays(1),
                )
                .id,
          );
          ids.add(
            c
                .addTask(
                  title: 'B',
                  rule: const DailyRule(),
                  start: c.today,
                  time: ClockTime(9, 0),
                )
                .id,
          );
          ids.add(
            c
                .addTask(
                  title: 'C',
                  rule: const DailyRule(),
                  start: c.today,
                  time: ClockTime(12, 0),
                )
                .id,
          );
          final done = c.addTask(
            title: 'Bitmiş',
            rule: const DailyRule(),
            start: c.today,
          );
          c.toggle(done.id, c.today);
          ids.add(done.id);
        },
      );
      final ticks = h.controller.data.completions;
      await mouseDrag(tester, ids[3], ids[0]);
      expect(h.controller.data.tasks.map((t) => t.id), [
        ids[3],
        ids[1],
        ids[0],
        ids[2],
        ids[4],
      ]);
      expect(h.controller.data.completions, ticks);
      await mouseDrag(tester, ids[3], ids[2], below: true);
      expect(h.controller.data.tasks.map((t) => t.id), ids);
      await h.controller.saved;
      final reopened = TaskController(
        store: store,
        clock: () => DateTime(2026, 11, 7, 10),
      );
      await reopened.load();
      expect(reopened.data.tasks.map((t) => t.id), ids);
      expect(reopened.data.completions, ticks);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'dragging a time sorted list switches to persistent manual order',
    (tester) async {
      final store = MemoryTaskStore()
        ..settings = const AppSettings(gameMode: false, sortByTime: true);
      final ids = <String>[];
      final h = await pumpApp(
        tester,
        store: store,
        size: const Size(1500, 1200),
        seed: (c) {
          for (final hour in [18, 9, 12]) {
            ids.add(
              c
                  .addTask(
                    title: '$hour',
                    rule: const DailyRule(),
                    start: c.today,
                    time: ClockTime(hour, 0),
                  )
                  .id,
            );
          }
        },
      );
      expect(
        tester.getTopLeft(find.byKey(Key('task-drag-${ids[1]}'))).dy,
        lessThan(tester.getTopLeft(find.byKey(Key('task-drag-${ids[0]}'))).dy),
      );
      await mouseDrag(tester, ids[2], ids[1]);
      expect(h.controller.settings.sortByTime, isFalse);
      expect(store.settings.sortByTime, isFalse);
      expect(h.controller.data.tasks.map((t) => t.id), [
        ids[2],
        ids[1],
        ids[0],
      ]);
    },
  );

  testWidgets(
    'quick add accepts typed 24 hour time, card edits and clears it',
    (tester) async {
      final store = MemoryTaskStore()
        ..settings = const AppSettings(gameMode: false);
      final h = await pumpApp(tester, store: store);
      await tester.tap(find.byKey(const Key('quick-time')));
      await tester.pumpAndSettle();
      await enterTime(tester, '21', '45');
      expect(find.text('Görev saati: 21:45'), findsOneWidget);
      await quickAdd(tester, 'Saatli görev');
      final id = h.controller.data.tasks.single.id;
      expect(h.controller.data.tasks.single.time, ClockTime(21, 45));
      await tester.tap(find.byKey(Key('task-time-$id')));
      await tester.pumpAndSettle();
      await enterTime(tester, '08', '15');
      expect(h.controller.data.tasks.single.time, ClockTime(8, 15));
      expect(find.text('08:15 geçti'), findsOneWidget);
      await tester.tap(find.byTooltip('Saati kaldır'));
      await tester.pumpAndSettle();
      expect(h.controller.data.tasks.single.time, isNull);
      expect(find.text('Saat ekle'), findsOneWidget);
    },
  );

  testWidgets('invalid and cancelled time entry leaves task unchanged', (
    tester,
  ) async {
    final h = await pumpApp(
      tester,
      store: MemoryTaskStore()..settings = const AppSettings(gameMode: false),
      seed: (c) {
        c.addTask(
          title: 'Saat',
          note: 'Notumu koru',
          rule: const DailyRule(),
          start: c.today,
          time: ClockTime(14, 0),
          steps: ['Adım'],
        );
      },
    );
    final task = h.controller.data.tasks.single;
    await tester.tap(find.byKey(Key('task-time-${task.id}')));
    await tester.pumpAndSettle();
    await enterTime(tester, '25', '99');
    expect(find.byType(TimePickerDialog), findsOneWidget);
    expect(h.controller.data.tasks.single.time, ClockTime(14, 0));
    await tester.tap(find.text('Vazgeç'));
    await tester.pumpAndSettle();
    expect(h.controller.data.tasks.single.note, 'Notumu koru');
    expect(h.controller.data.tasks.single.steps.single.title, 'Adım');
  });
}
