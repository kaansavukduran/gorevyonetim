import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gunluk_gorevler/src/app/task_controller.dart';
import 'package:gunluk_gorevler/src/app/settings.dart';
import 'package:gunluk_gorevler/src/domain/codec.dart';
import 'package:gunluk_gorevler/src/domain/local_date.dart';
import 'package:gunluk_gorevler/src/domain/repeat_rule.dart';
import 'package:gunluk_gorevler/src/domain/task.dart';
import 'package:gunluk_gorevler/src/domain/task_data.dart';
import 'package:gunluk_gorevler/src/storage/memory_task_store.dart';
import 'package:gunluk_gorevler/src/ui/app.dart';

LocalDate d(String iso) => LocalDate.parse(iso);

class Clock {
  DateTime now = DateTime(2026, 11, 7, 10); // Saturday
}

class FolderStore extends MemoryTaskStore {
  @override
  bool get canRevealLocation => true;
}

class Harness {
  Harness(this.controller, this.store, this.clock);
  final TaskController controller;
  final MemoryTaskStore store;
  final Clock clock;

  set now(DateTime value) => clock.now = value;
}

Future<Harness> pumpApp(
  WidgetTester tester, {
  MemoryTaskStore? store,
  Size size = const Size(1200, 900),
  void Function(TaskController c)? seed,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  final s = store ?? MemoryTaskStore();
  final clock = Clock();
  final c = TaskController(store: s, clock: () => clock.now);
  await c.load();
  if (c.state == LoadState.ready) seed?.call(c);
  await tester.pumpWidget(GunlukGorevlerApp(controller: c, version: 'test'));
  await tester.pumpAndSettle();
  return Harness(c, s, clock);
}

Finder checkOf(String id) => find.byKey(Key('task-check-$id'));

Future<void> quickAdd(WidgetTester tester, String title) async {
  await tester.enterText(find.byKey(const Key('quick-add-field')), title);
  await tester.testTextInput.receiveAction(TextInputAction.done);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('scale presets resize hit targets, save and reset', (
    tester,
  ) async {
    final h = await pumpApp(tester, size: const Size(1600, 1200));
    await quickAdd(tester, 'Ölçek testi');
    final id = h.controller.data.tasks.single.id;
    final before =
        tester.getBottomRight(checkOf(id)).dx -
        tester.getTopLeft(checkOf(id)).dx;
    await tester.tap(find.text('Ayarlar'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('scale-150')),
      200,
      scrollable: find
          .descendant(
            of: find.byKey(const Key('settings-list')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('scale-150')));
    await tester.pumpAndSettle();
    expect(h.controller.settings.uiScale, 1.5);
    expect(h.store.settings.uiScale, 1.5);
    await tester.tap(find.text('Gün'));
    await tester.pumpAndSettle();
    final after =
        tester.getBottomRight(checkOf(id)).dx -
        tester.getTopLeft(checkOf(id)).dx;
    expect(after, closeTo(before * 1.5, 0.1));
    await tester.tap(checkOf(id));
    await tester.pumpAndSettle();
    expect(h.controller.data.isDone(id, h.controller.today), isTrue);
    await tester.tap(find.text('Ayarlar'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('scale-reset')),
      200,
      scrollable: find
          .descendant(
            of: find.byKey(const Key('settings-list')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('scale-reset')));
    await tester.pumpAndSettle();
    expect(h.store.settings.uiScale, 1.0);
    expect(tester.takeException(), isNull);
  });

  for (final width in [360.0, 390.0, 600.0, 1200.0]) {
    testWidgets('phone and zoomed layout at $width stays usable', (
      tester,
    ) async {
      final originalHandler = FlutterError.onError;
      FlutterError.onError = (details) {
        debugPrint(details.toString());
        originalHandler?.call(details);
      };
      addTearDown(() => FlutterError.onError = originalHandler);
      final store = MemoryTaskStore()
        ..settings = const AppSettings(uiScale: 2.0);
      final h = await pumpApp(
        tester,
        store: store,
        size: Size(width, 1000),
        seed: (c) {
          c.addTask(
            title: 'Uzun görev başlığı ile telefon ekranını kontrol et',
            rule: const DailyRule(),
            start: c.today,
            time: ClockTime(9, 0),
            steps: ['Birinci adım', 'İkinci adım'],
          );
        },
      );
      final layoutError = tester.takeException();
      expect(
        layoutError,
        isNull,
        reason: layoutError is FlutterError ? layoutError.toStringDeep() : null,
      );
      final id = h.controller.data.tasks.single.id;
      await tester.dragUntilVisible(
        checkOf(id),
        find.byType(CustomScrollView),
        const Offset(0, -200),
      );
      await Scrollable.ensureVisible(
        tester.element(checkOf(id)),
        alignment: 0.5,
      );
      await tester.pumpAndSettle();
      await tester.tap(checkOf(id));
      await tester.pumpAndSettle();
      expect(h.controller.data.isDone(id, h.controller.today), isTrue);
      expect(tester.takeException(), isNull);
      for (final tab in ['Görevler', 'Kontrol', 'Karakter', 'Ayarlar']) {
        await tester.tap(find.text(tab).last);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: tab);
      }
      await tester.tap(find.text('Görevler').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('new-task-fab')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('editor-title')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('opens on today with an empty list', (tester) async {
    await pumpApp(tester);
    expect(find.text('Bugün'), findsWidgets);
    expect(find.text('7 Kasım 2026, Cumartesi'), findsOneWidget);
    expect(find.text('Bu gün için görev yok.'), findsOneWidget);
  });

  testWidgets('quick add, tick, untick and undo', (tester) async {
    final h = await pumpApp(tester);
    await quickAdd(tester, 'Su iç');
    final id = h.controller.data.tasks.single.id;
    expect(find.text('Su iç'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(Key('task-tile-$id')),
        matching: find.text('Her gün'),
      ),
      findsOneWidget,
    );
    expect(find.text('1 görevden 0 tanesi tamamlandı'), findsOneWidget);

    await tester.tap(checkOf(id));
    await tester.pumpAndSettle();
    expect(find.text('Bugünün hepsi tamam: 1 / 1'), findsOneWidget);
    expect(find.byKey(const Key('day-all-done')), findsOneWidget);
    expect(find.text('Tamamlananlar (1)'), findsOneWidget);
    expect(find.textContaining('10:00 işaretlendi'), findsOneWidget);
    await h.controller.saved;
    expect(decodeTaskData(h.store.saved!).isDone(id, d('2026-11-07')), isTrue);

    await tester.tap(checkOf(id));
    await tester.pumpAndSettle();
    expect(find.text('Yapılacaklar (1)'), findsOneWidget);
    expect(find.text('"Su iç" işareti kaldırıldı.'), findsOneWidget);
    await tester.tap(find.text('Geri al'));
    await tester.pumpAndSettle();
    expect(h.controller.data.isDone(id, d('2026-11-07')), isTrue);
  });

  testWidgets('quick add as "only this day" makes a one-off', (tester) async {
    final h = await pumpApp(tester);
    await tester.tap(find.byKey(const Key('quick-repeat')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('quick-repeat-once')));
    await tester.pumpAndSettle();
    await tester.pump();
    await quickAdd(tester, 'Fatura öde');
    final t = h.controller.data.tasks.single;
    expect(t.lastRule, OnceRule(d('2026-11-07')));
    expect(find.text('Tek sefer: 7 Kasım'), findsOneWidget);
  });

  testWidgets('a past day shows what was not done and can be ticked later', (
    tester,
  ) async {
    final h = await pumpApp(
      tester,
      seed: (c) => c.addTask(
        title: 'Kitap oku',
        rule: const DailyRule(),
        start: d('2026-11-01'),
      ),
    );
    final id = h.controller.data.tasks.single.id;
    await tester.tap(find.byKey(const Key('week-day-2026-11-06')));
    await tester.pumpAndSettle();
    expect(find.text('Dün'), findsOneWidget);
    expect(find.textContaining('Yapılmadı'), findsOneWidget);
    expect(find.text('Yapılmayanlar (1)'), findsOneWidget);

    await tester.tap(checkOf(id));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('7 Kasım 10:00 sonradan işaretlendi'),
      findsOneWidget,
    );
    expect(h.controller.data.isDone(id, d('2026-11-06')), isTrue);

    await tester.tap(find.byKey(const Key('day-today')));
    await tester.pumpAndSettle();
    expect(find.text('7 Kasım 2026, Cumartesi'), findsOneWidget);
  });

  testWidgets('a later day cannot be ticked', (tester) async {
    final h = await pumpApp(
      tester,
      seed: (c) => c.addTask(
        title: 'Kitap oku',
        rule: const DailyRule(),
        start: d('2026-11-01'),
      ),
    );
    final id = h.controller.data.tasks.single.id;
    await tester.tap(find.byKey(const Key('week-day-2026-11-08')));
    await tester.pumpAndSettle();
    expect(find.text('Yarın'), findsOneWidget);
    expect(tester.widget<Checkbox>(checkOf(id)).onChanged, isNull);
    await tester.tap(find.text('Kitap oku'));
    await tester.pumpAndSettle();
    expect(h.controller.data.completions, isEmpty);
  });

  testWidgets(
    'the editor adds a task on chosen weekdays and checks its input',
    (tester) async {
      final h = await pumpApp(tester);
      await tester.tap(find.byKey(const Key('quick-repeat')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('quick-details')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('editor-save')));
      await tester.pumpAndSettle();
      expect(find.text('Görev adı yaz.'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('editor-title')),
        'Antrenman',
      );
      await tester.enterText(
        find.byKey(const Key('editor-note')),
        'Bacak günü',
      );
      await tester.tap(find.text('Belirli günler'));
      await tester.pumpAndSettle();
      // Weekdays are preselected; clear them and check the empty refusal.
      for (var w = 1; w <= 5; w++) {
        await tester.tap(find.byKey(Key('editor-weekday-$w')));
      }
      await tester.pump();
      await tester.tap(find.byKey(const Key('editor-save')));
      await tester.pumpAndSettle();
      expect(find.text('En az bir gün seç.'), findsOneWidget);

      for (final w in [1, 3, 5]) {
        await tester.tap(find.byKey(Key('editor-weekday-$w')));
      }
      await tester.pump();
      await tester.tap(find.byKey(const Key('editor-save')));
      await tester.pumpAndSettle();

      final t = h.controller.data.tasks.single;
      expect(t.title, 'Antrenman');
      expect(t.note, 'Bacak günü');
      expect(t.lastRule, WeeklyRule({1, 3, 5}));
      // Saturday: not one of its days.
      expect(find.text('Antrenman'), findsNothing);
      await tester.tap(find.text('Görevler'));
      await tester.pumpAndSettle();
      expect(find.text('Antrenman'), findsOneWidget);
      expect(find.textContaining('Pzt, Çar, Cum'), findsOneWidget);
    },
  );

  testWidgets('delete asks, removes everything, and can be undone', (
    tester,
  ) async {
    final h = await pumpApp(
      tester,
      seed: (c) {
        final t = c.addTask(
          title: 'Su iç',
          rule: const DailyRule(),
          start: d('2026-11-01'),
        );
        c.toggle(t.id, d('2026-11-07'));
      },
    );
    final id = h.controller.data.tasks.single.id;
    await tester.tap(find.byKey(Key('task-menu-$id')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sil'));
    await tester.pumpAndSettle();
    expect(find.textContaining('1 günlük işareti'), findsOneWidget);
    await tester.tap(find.byKey(const Key('confirm-delete')));
    await tester.pumpAndSettle();
    expect(h.controller.data.tasks, isEmpty);
    expect(find.text('Bu gün için görev yok.'), findsOneWidget);

    await tester.tap(find.text('Geri al'));
    await tester.pumpAndSettle();
    expect(h.controller.data.isDone(id, d('2026-11-07')), isTrue);
  });

  testWidgets('end hides the task from today on and keeps its history', (
    tester,
  ) async {
    final h = await pumpApp(
      tester,
      seed: (c) {
        final t = c.addTask(
          title: 'Su iç',
          rule: const DailyRule(),
          start: d('2026-11-01'),
        );
        c.toggle(t.id, d('2026-11-03'));
      },
    );
    final id = h.controller.data.tasks.single.id;
    await tester.tap(find.byKey(Key('task-menu-$id')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sonlandır'));
    await tester.pumpAndSettle();
    expect(find.text('Su iç'), findsNothing);
    expect(h.controller.data.isDone(id, d('2026-11-03')), isTrue);

    await tester.tap(find.text('Görevler'));
    await tester.pumpAndSettle();
    expect(find.text('Süren görev yok.'), findsOneWidget);
    await tester.tap(find.text('Biten'));
    await tester.pumpAndSettle();
    expect(find.text('Su iç'), findsOneWidget);
    expect(find.textContaining('sonlandırılmış'), findsOneWidget);
  });

  testWidgets(
    'Kontrol shows done and missed days and fixes a day with a click',
    (tester) async {
      final h = await pumpApp(
        tester,
        seed: (c) {
          final t = c.addTask(
            title: 'Su iç',
            rule: const DailyRule(),
            start: d('2026-11-04'),
          );
          c.toggle(t.id, d('2026-11-04'));
          c.toggle(t.id, d('2026-11-06'));
        },
      );
      final id = h.controller.data.tasks.single.id;
      await tester.tap(find.text('Kontrol'));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Bu aralıkta 2 kez yapıldı, 1 kez yapılmadı, bugün 1 görev bekliyor.',
        ),
        findsOneWidget,
      );
      expect(find.text('2/3  %67'), findsOneWidget);

      await tester.tap(find.byKey(Key('cell-$id-2026-11-05')));
      await tester.pumpAndSettle();
      expect(h.controller.data.isDone(id, d('2026-11-05')), isTrue);
      expect(find.text('3/3  %100'), findsOneWidget);

      // A day before the start is not a miss and cannot be ticked.
      await tester.tap(find.byKey(Key('cell-$id-2026-11-02')));
      await tester.pumpAndSettle();
      expect(h.controller.data.isDone(id, d('2026-11-02')), isFalse);
    },
  );

  testWidgets('an unreadable file shows what happened and touches nothing', (
    tester,
  ) async {
    final store = MemoryTaskStore(saved: '{ bozuk');
    final h = await pumpApp(tester, store: store);
    expect(find.text('Kayıtlı görevler açılamadı'), findsOneWidget);
    expect(store.saved, '{ bozuk');
    await tester.tap(find.byKey(const Key('start-over')));
    await tester.pumpAndSettle();
    expect(h.controller.state, LoadState.ready);
    expect(find.text('Bu gün için görev yok.'), findsOneWidget);
  });

  testWidgets('a failed save is shown on screen', (tester) async {
    final store = MemoryTaskStore()..failWith = Exception('disk dolu');
    await pumpApp(tester, store: store);
    await quickAdd(tester, 'Su iç');
    await tester.pumpAndSettle();
    expect(find.textContaining('Kaydedilemedi'), findsOneWidget);
    expect(find.text('Su iç'), findsOneWidget);
  });

  testWidgets('Alt + arrows move between days; Alt + B returns', (
    tester,
  ) async {
    await pumpApp(tester);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
    await tester.pumpAndSettle();
    expect(find.text('6 Kasım 2026, Cuma'), findsOneWidget);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyB);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
    await tester.pumpAndSettle();
    expect(find.text('7 Kasım 2026, Cumartesi'), findsOneWidget);
  });

  testWidgets('after midnight "today" moves on by itself', (tester) async {
    final h = await pumpApp(tester);
    h.now = DateTime(2026, 11, 8, 0, 0, 30);
    await tester.pump(const Duration(seconds: 31));
    await tester.pumpAndSettle();
    expect(find.text('8 Kasım 2026, Pazar'), findsOneWidget);
  });

  testWidgets('a narrow window uses a bottom bar and does not overflow', (
    tester,
  ) async {
    await pumpApp(
      tester,
      size: const Size(420, 800),
      seed: (c) {
        c.addTask(
          title: 'Çok uzun bir görev adı: sabah kalkınca iki bardak su, sonra kısa yürüyüş',
          note: 'Not satırı da uzun olabilir ve iki satıra taşabilir',
          rule: WeeklyRule({1, 2, 3, 4, 5, 6}),
          start: d('2026-11-01'),
        );
      },
    );
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
    await tester.tap(find.text('Kontrol'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('30 gün'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Görevler'));
    await tester.pumpAndSettle();
    for (final tab in ['Karakter', 'Ayarlar', 'Gün']) {
      await tester.tap(find.text(tab).last);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: tab);
    }
  });

  testWidgets('the week strip opens a day and moves by a week', (tester) async {
    final h = await pumpApp(
      tester,
      seed: (c) {
        final t = c.addTask(
          title: 'Su iç',
          rule: const DailyRule(),
          start: d('2026-11-02'),
        );
        c.toggle(t.id, d('2026-11-02'));
      },
    );
    // Monday 2 November .. Sunday 8 November are shown.
    expect(find.byKey(const Key('week-day-2026-11-02')), findsOneWidget);
    expect(find.byKey(const Key('week-day-2026-11-08')), findsOneWidget);
    expect(
      find.byTooltip('2 Kasım: 1 görevden 1 tanesi yapıldı'),
      findsOneWidget,
    );
    expect(
      find.byTooltip('3 Kasım: 1 görevden 0 tanesi yapıldı'),
      findsOneWidget,
    );
    expect(find.byTooltip('8 Kasım: 1 görev planlı'), findsOneWidget);

    await tester.tap(find.byKey(const Key('week-day-2026-11-03')));
    await tester.pumpAndSettle();
    expect(find.text('3 Kasım 2026, Salı'), findsOneWidget);

    await tester.tap(find.byKey(const Key('week-prev')));
    await tester.pumpAndSettle();
    expect(find.text('27 Ekim 2026, Salı'), findsOneWidget);
    expect(find.byKey(const Key('week-day-2026-10-26')), findsOneWidget);
    expect(h.controller.today, d('2026-11-07'));

    await tester.tap(find.byKey(const Key('day-today')));
    await tester.pumpAndSettle();
    expect(find.text('7 Kasım 2026, Cumartesi'), findsOneWidget);
  });

  testWidgets('Ekle is off until something is typed', (tester) async {
    await pumpApp(tester);
    final button = find.byKey(const Key('quick-add-button'));
    expect(tester.widget<FilledButton>(button).onPressed, isNull);
    await tester.enterText(find.byKey(const Key('quick-add-field')), 'Yürü');
    await tester.pump();
    expect(tester.widget<FilledButton>(button).onPressed, isNotNull);
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(find.text('Yürü'), findsOneWidget);
    expect(tester.widget<FilledButton>(button).onPressed, isNull);
  });

  testWidgets('right-click on a task opens its menu', (tester) async {
    final h = await pumpApp(
      tester,
      seed: (c) => c.addTask(
        title: 'Su iç',
        rule: const DailyRule(),
        start: d('2026-11-01'),
      ),
    );
    final id = h.controller.data.tasks.single.id;
    await tester.tap(
      find.byKey(Key('task-tile-$id')),
      buttons: kSecondaryMouseButton,
    );
    await tester.pumpAndSettle();
    expect(find.text('Düzenle'), findsOneWidget);
    expect(find.text('Sonlandır'), findsOneWidget);
    expect(h.controller.data.completions, isEmpty); // a right-click never ticks
    await tester.tap(find.text('Düzenle'));
    await tester.pumpAndSettle();
    expect(find.text('Görevi düzenle'), findsOneWidget);
  });

  testWidgets('a streak of two or more days is shown on today', (tester) async {
    final h = await pumpApp(
      tester,
      seed: (c) {
        final t = c.addTask(
          title: 'Su iç',
          rule: const DailyRule(),
          start: d('2026-11-01'),
        );
        c.toggle(t.id, d('2026-11-05'));
        c.toggle(t.id, d('2026-11-06'));
      },
    );
    final id = h.controller.data.tasks.single.id;
    expect(find.byKey(Key('task-streak-$id')), findsOneWidget);
    expect(find.text('2 gün'), findsOneWidget);
    await tester.tap(find.byKey(const Key('week-day-2026-11-06')));
    await tester.pumpAndSettle();
    expect(find.byKey(Key('task-streak-$id')), findsNothing);
  });

  testWidgets('"Yeni görev" lives on Görevler; a card click edits', (
    tester,
  ) async {
    final h = await pumpApp(
      tester,
      seed: (c) => c.addTask(
        title: 'Su iç',
        rule: const DailyRule(),
        start: d('2026-11-01'),
      ),
    );
    expect(find.byKey(const Key('new-task-fab')), findsNothing);
    await tester.tap(find.text('Görevler'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('new-task-fab')), findsOneWidget);
    final id = h.controller.data.tasks.single.id;
    await tester.tap(find.byKey(Key('task-card-$id')));
    await tester.pumpAndSettle();
    expect(find.text('Görevi düzenle'), findsOneWidget);
  });

  testWidgets('the info window says when the folder cannot be opened', (
    tester,
  ) async {
    await pumpApp(tester, store: FolderStore());
    await tester.tap(find.text('Ayarlar'));
    await tester.pumpAndSettle();
    await tester.dragUntilVisible(
      find.byKey(const Key('about-open-folder')),
      find.byType(ListView).first,
      const Offset(0, -300),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('about-open-folder')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Klasör açılamadı'), findsOneWidget);
  });

  group('game', () {
    testWidgets('a tick shows the XP it earned and the hero strip moves', (
      tester,
    ) async {
      final h = await pumpApp(
        tester,
        seed: (c) => c.addTask(
          title: 'Su iç',
          rule: const DailyRule(),
          start: d('2026-11-07'),
        ),
      );
      expect(find.byKey(const Key('hero-strip')), findsOneWidget);
      expect(find.text('+0'), findsOneWidget);
      await tester.tap(checkOf(h.controller.data.tasks.single.id));
      await tester.pumpAndSettle();
      expect(find.textContaining('+50 XP'), findsOneWidget);
      expect(find.textContaining('Mükemmel gün! +1 İrade'), findsOneWidget);
      expect(find.textContaining('Yeni rozet: İlk Adım'), findsOneWidget);
      expect(find.text('+50'), findsOneWidget);
      expect(find.text('50 / 100 XP'), findsOneWidget);
    });

    testWidgets('crossing a level opens the level-up window', (tester) async {
      final h = await pumpApp(
        tester,
        seed: (c) {
          final t = c.addTask(
            title: 'Ağırlık',
            rule: const DailyRule(),
            start: d('2026-11-06'),
            difficulty: Difficulty.zor,
          );
          c.toggle(t.id, d('2026-11-06')); // late: 35 + 25 perfect
        },
      );
      expect(h.controller.profile.level, 1);
      await tester.tap(checkOf(h.controller.data.tasks.single.id));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('level-up')), findsOneWidget);
      expect(find.text('Seviye atladın!'), findsOneWidget);
      expect(find.text('Seviye 2: Çaylak'), findsOneWidget);
      await tester.tap(find.text('Devam'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('level-up')), findsNothing);
    });

    testWidgets('the character page shows title, stats and badges', (
      tester,
    ) async {
      await pumpApp(
        tester,
        seed: (c) {
          final t = c.addTask(
            title: 'Su iç',
            rule: const DailyRule(),
            start: d('2026-11-07'),
          );
          c.toggle(t.id, d('2026-11-07'));
        },
      );
      await tester.tap(find.byKey(const Key('hero-strip')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('character-title')), findsOneWidget);
      expect(find.text('Çaylak'), findsWidgets);
      expect(find.byKey(const Key('stat-İrade')), findsOneWidget);
      expect(
        tester.widget<Text>(find.byKey(const Key('stat-İrade'))).data,
        '1',
      );
      expect(
        tester.widget<Text>(find.byKey(const Key('stat-Toplam başarı'))).data,
        '1',
      );
      await tester.dragUntilVisible(
        find.byKey(const Key('badge-ilk-adim')),
        find.byType(ListView).first,
        const Offset(0, -300),
      );
      expect(find.byKey(const Key('badge-ilk-adim')), findsOneWidget);
    });

    testWidgets('themes switch and are saved', (tester) async {
      final h = await pumpApp(tester);
      await tester.tap(find.text('Ayarlar'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const Key('theme-neon')),
        200,
        scrollable: find
            .descendant(
              of: find.byKey(const Key('settings-list')),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('theme-neon')));
      await tester.pumpAndSettle();
      expect(h.controller.settings.themeId, 'neon');
      expect(h.store.settings.themeId, 'neon');
      final ctx = tester.element(find.byKey(const Key('theme-neon')));
      expect(Theme.of(ctx).colorScheme.primary, const Color(0xFF25E2F2));
      await tester.scrollUntilVisible(
        find.byKey(const Key('theme-sade')),
        200,
        scrollable: find
            .descendant(
              of: find.byKey(const Key('settings-list')),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('theme-sade')));
      await tester.pumpAndSettle();
      expect(Theme.of(ctx).brightness, Brightness.light);
    });

    testWidgets('game mode off hides XP, levels and the Karakter tab', (
      tester,
    ) async {
      final h = await pumpApp(
        tester,
        seed: (c) => c.addTask(
          title: 'Su iç',
          rule: const DailyRule(),
          start: d('2026-11-07'),
        ),
      );
      expect(find.text('Karakter'), findsOneWidget);
      await tester.tap(find.text('Ayarlar'));
      await tester.pumpAndSettle();
      await tester.dragUntilVisible(
        find.byKey(const Key('game-mode')),
        find.byKey(const Key('settings-list')),
        const Offset(0, -300),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('game-mode')));
      await tester.pumpAndSettle();
      expect(find.text('Karakter'), findsNothing);
      await tester.tap(find.text('Gün'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('hero-strip')), findsNothing);
      final id = h.controller.data.tasks.single.id;
      expect(find.byKey(Key('task-diff-$id')), findsNothing);
      await tester.tap(checkOf(id));
      await tester.pumpAndSettle();
      expect(find.textContaining('XP'), findsNothing);
    });
  });

  testWidgets('steps open, tick, and the last step ticks the task', (
    tester,
  ) async {
    final h = await pumpApp(
      tester,
      seed: (c) => c.addTask(
        title: 'Spor',
        rule: const DailyRule(),
        start: d('2026-11-07'),
        steps: ['Isın', 'Koş'],
      ),
    );
    final t = h.controller.data.tasks.single;
    expect(find.text('0/2 adım'), findsOneWidget);
    await tester.tap(find.byKey(Key('task-steps-${t.id}')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(Key('step-${t.id}-${t.steps[0].id}')));
    await tester.pumpAndSettle();
    expect(find.text('1/2 adım'), findsOneWidget);
    expect(h.controller.data.isDone(t.id, d('2026-11-07')), isFalse);
    await tester.tap(find.byKey(Key('step-${t.id}-${t.steps[1].id}')));
    await tester.pumpAndSettle();
    expect(h.controller.data.isDone(t.id, d('2026-11-07')), isTrue);
    expect(find.text('Tamamlananlar (1)'), findsOneWidget);
  });

  testWidgets('a passed reminder time is shown and announced once', (
    tester,
  ) async {
    final h = await pumpApp(
      tester,
      seed: (c) => c.addTask(
        title: 'İlaç zamanı değil, su',
        rule: const DailyRule(),
        start: d('2026-11-07'),
        time: ClockTime(9, 30),
      ),
    );
    final id = h.controller.data.tasks.single.id;
    expect(find.text('09:30 geçti'), findsOneWidget);
    await tester.pump(const Duration(seconds: 31));
    await tester.pump();
    expect(find.byKey(const Key('reminder')), findsOneWidget);
    expect(find.textContaining('Hatırlatma: 09:30'), findsOneWidget);
    ScaffoldMessenger.of(tester.element(find.byKey(Key('task-tile-$id'))))
        .removeCurrentSnackBar();
    await tester.pump(const Duration(seconds: 31));
    await tester.pump();
    expect(find.byKey(const Key('reminder')), findsNothing);
  });

  testWidgets('a backup is exported and another one imported', (tester) async {
    final store = MemoryTaskStore();
    store.backups['eski-gorevler.json'] = encodeTaskData(
      TaskData(
        tasks: [
          Task(
            id: 'x',
            title: 'Yedekteki görev',
            note: '',
            schedule: [ScheduleSegment(d('2026-11-01'), const DailyRule())],
            createdAt: DateTime.utc(2026),
            order: 0,
          ),
        ],
      ),
      savedAt: DateTime.utc(2026),
    );
    final h = await pumpApp(
      tester,
      store: store,
      seed: (c) => c.addTask(
        title: 'Şimdiki',
        rule: const DailyRule(),
        start: d('2026-11-07'),
      ),
    );
    await tester.tap(find.text('Ayarlar'));
    await tester.pumpAndSettle();
    await tester.dragUntilVisible(
      find.byKey(const Key('import')),
      find.byType(ListView).first,
      const Offset(0, -300),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('export')));
    await tester.pumpAndSettle();
    expect(store.exported.single, contains('Şimdiki'));
    await tester.tap(find.byKey(const Key('import')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('candidate-eski-gorevler.json')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm-import')));
    await tester.pumpAndSettle();
    expect(h.controller.data.tasks.single.title, 'Yedekteki görev');
    await tester.tap(find.text('Geri al'));
    await tester.pumpAndSettle();
    expect(h.controller.data.tasks.single.title, 'Şimdiki');
  });

  testWidgets('a task already done is not reminded', (tester) async {
    await pumpApp(
      tester,
      seed: (c) {
        final t = c.addTask(
          title: 'Su',
          rule: const DailyRule(),
          start: d('2026-11-07'),
          time: ClockTime(9, 0),
        );
        c.toggle(t.id, d('2026-11-07'));
      },
    );
    expect(find.text('09:00 geçti'), findsNothing);
    await tester.pump(const Duration(seconds: 31));
    await tester.pump();
    expect(find.byKey(const Key('reminder')), findsNothing);
  });

  group('quests', () {
    testWidgets('the quest board shows today and the week; a perfect day '
        'throws confetti', (tester) async {
      final h = await pumpApp(
        tester,
        seed: (c) => c.addTask(
          title: 'Su',
          rule: const DailyRule(),
          start: d('2026-11-07'),
        ),
      );
      expect(find.byKey(const Key('quest-card')), findsOneWidget);
      expect(find.byKey(const Key('quest-today')), findsOneWidget);
      expect(
        find.textContaining('Haftalık: Bu hafta 5 mükemmel gün'),
        findsOneWidget,
      );
      await tester.tap(checkOf(h.controller.data.tasks.single.id));
      await tester.pump();
      expect(find.byKey(const Key('confetti')), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('confetti')), findsNothing);
    });

    testWidgets('the class changes the emblem and is saved', (tester) async {
      final h = await pumpApp(tester);
      await tester.tap(find.text('Karakter'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Savaşçı ·'), findsOneWidget);
      await tester.dragUntilVisible(
        find.byKey(const Key('class-buyucu')),
        find.byType(ListView).first,
        const Offset(0, -200),
      );
      await tester.tap(find.byKey(const Key('class-buyucu')));
      await tester.pumpAndSettle();
      expect(h.store.settings.charClass, 'buyucu');
      expect(find.byKey(const Key('heatmap')), findsOneWidget);
    });
  });
}
