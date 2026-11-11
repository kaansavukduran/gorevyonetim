import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gunluk_gorevler/src/app/settings.dart';
import 'package:gunluk_gorevler/src/domain/repeat_rule.dart';
import 'package:gunluk_gorevler/src/storage/memory_task_store.dart';
import 'package:gunluk_gorevler/src/ui/themes.dart';

import 'app_test.dart' show pumpApp;

Future<void> reveal(WidgetTester tester, Key key) async {
  await tester.dragUntilVisible(
    find.byKey(key),
    find.byKey(const Key('settings-list')),
    const Offset(0, -250),
  );
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.byKey(key));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('exact zoom value persists; invalid value keeps the last scale', (
    tester,
  ) async {
    final h = await pumpApp(tester, size: const Size(1600, 1200));
    await tester.tap(find.text('Ayarlar'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('scale-value')), '137');
    await tester.pump();
    expect(find.text('Örnek yazı · %137'), findsOneWidget);
    expect(h.controller.settings.uiScale, 1.0);
    await tester.ensureVisible(find.byKey(const Key('scale-apply')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('scale-apply')));
    await tester.pumpAndSettle();
    expect(h.store.settings.uiScale, 1.37);
    await tester.enterText(find.byKey(const Key('scale-value')), '999');
    await tester.tap(find.byKey(const Key('scale-apply')));
    await tester.pumpAndSettle();
    expect(h.controller.settings.uiScale, 1.37);
    expect(find.text('80–200 arası'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('scale-value')), '100');
    await tester.tap(find.byKey(const Key('scale-apply')));
    await tester.pumpAndSettle();
    final slider = tester.widget<Slider>(find.byKey(const Key('scale-slider')));
    slider.onChangeStart!(100);
    slider.onChanged!(143);
    await tester.pump();
    expect(find.text('Örnek yazı · %143'), findsOneWidget);
    slider.onChangeEnd!(143);
    await tester.pumpAndSettle();
    expect(h.store.settings.uiScale, 1.43);
  });

  testWidgets(
    'color picker applies HEX, cancels safely and presets can be restored',
    (tester) async {
      final h = await pumpApp(tester, size: const Size(1600, 1200));
      await tester.tap(find.text('Ayarlar'));
      await tester.pumpAndSettle();
      await reveal(tester, const Key('custom-color-primary'));
      await tester.tap(find.byKey(const Key('custom-color-primary')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('color-hex')), '12');
      await tester.pump();
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('color-confirm')))
            .onPressed,
        isNull,
      );
      await tester.enterText(find.byKey(const Key('color-hex')), '#00AACC');
      await tester.pump();
      await tester.tap(find.byKey(const Key('color-confirm')));
      await tester.pumpAndSettle();
      expect(h.store.settings.customTheme.enabled, isTrue);
      expect(h.store.settings.customTheme.primary, 0x00AACC);
      expect(
        Theme.of(tester.element(find.byKey(const Key('theme-customization'))))
            .colorScheme
            .primary,
        const Color(0xFF00AACC),
      );
      await tester.tap(find.byKey(const Key('custom-color-primary')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('color-hex')), 'FF0000');
      await tester.tap(find.byKey(const Key('color-cancel')));
      await tester.pumpAndSettle();
      expect(h.store.settings.customTheme.primary, 0x00AACC);
      await reveal(tester, const Key('custom-theme-reset'));
      await tester.tap(find.byKey(const Key('custom-theme-reset')));
      await tester.pumpAndSettle();
      expect(h.store.settings.customTheme.enabled, isFalse);
      expect(h.store.settings.customTheme.primary, isNull);
      expect(h.store.settings.themeId, 'diyar');
    },
  );

  testWidgets('custom radius is exact and color dialog fits a phone', (
    tester,
  ) async {
    final h = await pumpApp(tester, size: const Size(390, 1000));
    await tester.tap(find.text('Ayarlar'));
    await tester.pumpAndSettle();
    await reveal(tester, const Key('theme-radius-value'));
    await tester.enterText(find.byKey(const Key('theme-radius-value')), '23');
    await tester.tap(find.byKey(const Key('theme-radius-apply')));
    await tester.pumpAndSettle();
    expect(h.store.settings.customTheme.radius, 23);
    expect(
      GameStyle.of(tester.element(find.byKey(const Key('theme-customization'))))
          .radius,
      23,
    );
    await reveal(tester, const Key('custom-color-surface'));
    await tester.tap(find.byKey(const Key('custom-color-surface')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('color-plane')), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.enterText(find.byKey(const Key('color-hex')), 'FFFFFF');
    await tester.tap(find.byKey(const Key('color-confirm')));
    await tester.pumpAndSettle();
    expect(h.store.settings.customTheme.surface, 0xFFFFFF);
    expect(
      Theme.of(tester.element(find.byKey(const Key('theme-customization'))))
          .colorScheme
          .onSurface,
      Colors.black,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'daily goal celebrates real completion and setting a goal grants no XP',
    (tester) async {
      final h = await pumpApp(
        tester,
        store: MemoryTaskStore()..settings = const AppSettings(dailyGoal: 1),
        seed: (c) {
          for (final title in ['A', 'B']) {
            c.addTask(title: title, rule: const DailyRule(), start: c.today);
          }
        },
      );
      expect(find.text('Günlük hedef: 0 / 1'), findsOneWidget);
      final id = h.controller.data.tasks.first.id;
      await tester.tap(find.byKey(Key('task-check-$id')));
      await tester.pump();
      expect(find.text('Günlük hedef tamam! 1 / 1'), findsOneWidget);
      expect(find.byKey(const Key('confetti')), findsOneWidget);
      expect(h.controller.profile.totalXp, 25);
      await tester.pumpAndSettle();
      final xp = h.controller.profile.totalXp;
      await h.controller.updateSettings(
        h.controller.settings.copyWith(dailyGoal: 2),
      );
      await tester.pumpAndSettle();
      expect(h.controller.profile.totalXp, xp);
      expect(find.text('Günlük hedef: 1 / 2'), findsOneWidget);
    },
  );

  testWidgets(
    'effects can be disabled while progress and XP remain available',
    (tester) async {
      final h = await pumpApp(
        tester,
        store: MemoryTaskStore()
          ..settings = const AppSettings(
            dailyGoal: 1,
            celebrationEffects: false,
          ),
        seed: (c) =>
            c.addTask(title: 'A', rule: const DailyRule(), start: c.today),
      );
      await tester.tap(
        find.byKey(Key('task-check-${h.controller.data.tasks.single.id}')),
      );
      await tester.pump();
      expect(find.byKey(const Key('confetti')), findsNothing);
      expect(find.text('Günlük hedef tamam! 1 / 1'), findsOneWidget);
      expect(h.controller.profile.totalXp, greaterThan(0));
      await tester.pumpAndSettle();
    },
  );
  testWidgets('system reduced motion suppresses confetti without hiding XP', (
    tester,
  ) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(reduceMotion: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    final h = await pumpApp(
      tester,
      store: MemoryTaskStore()..settings = const AppSettings(dailyGoal: 1),
      seed: (c) =>
          c.addTask(title: 'A', rule: const DailyRule(), start: c.today),
    );
    await tester.tap(
      find.byKey(Key('task-check-${h.controller.data.tasks.single.id}')),
    );
    await tester.pump();
    expect(find.byKey(const Key('confetti')), findsNothing);
    expect(h.controller.profile.totalXp, greaterThan(0));
    await tester.pumpAndSettle();
  });
}
