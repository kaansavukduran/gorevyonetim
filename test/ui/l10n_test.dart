import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gunluk_gorevler/src/app/settings.dart';
import 'package:gunluk_gorevler/src/app/task_controller.dart';
import 'package:gunluk_gorevler/src/domain/local_date.dart';
import 'package:gunluk_gorevler/src/domain/repeat_rule.dart';
import 'package:gunluk_gorevler/src/domain/turkish_dates.dart';
import 'package:gunluk_gorevler/src/storage/memory_task_store.dart';
import 'package:gunluk_gorevler/src/ui/app.dart';
import 'package:gunluk_gorevler/src/ui/l10n.dart';
import 'package:gunluk_gorevler/src/ui/l10n_en.dart';

/// Every text wrapped with context.t(...) in the UI code.
Set<String> wrappedTexts() {
  final keys = <String>{};
  for (final f in Directory('lib/src/ui').listSync().whereType<File>()) {
    if (!f.path.endsWith('.dart')) continue;
    // Adjacent literals are one string in Dart.
    final src = f.readAsStringSync().replaceAll(RegExp(r"'\s*\n\s*'"), '');
    for (final m in RegExp(
      r"context\.t\(\s*'((?:[^'\\]|\\.)*)'",
    ).allMatches(src)) {
      keys.add(m.group(1)!);
    }
  }
  return keys;
}

String unescape(String s) =>
    s.replaceAll(r"\'", "'").replaceAll(r'\n', '\n').replaceAll(r'\$', r'$');

Set<String> placeholders(String s) =>
    RegExp(r'\{p\d\}').allMatches(s).map((m) => m.group(0)!).toSet();

Future<TaskController> pump(WidgetTester tester, AppSettings settings) async {
  tester.view.physicalSize = const Size(1200, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final store = MemoryTaskStore()..settings = settings;
  final c = TaskController(
    store: store,
    clock: () => DateTime(2026, 11, 7, 10),
  );
  await c.load();
  c.addTask(
    title: 'Su iç',
    rule: const DailyRule(),
    start: LocalDate(2026, 11, 1),
  );
  await tester.pumpWidget(GunlukGorevlerApp(controller: c));
  await tester.pumpAndSettle();
  return c;
}

void main() {
  test(
    'every wrapped text has an English entry with the same placeholders',
    () {
      final keys = wrappedTexts();
      expect(keys.length, greaterThan(200));
      final missing = [
        for (final k in keys)
          if (!enStrings.containsKey(unescape(k))) k,
      ];
      expect(missing, isEmpty);
      for (final e in enStrings.entries) {
        expect(placeholders(e.value), placeholders(e.key), reason: e.key);
      }
    },
  );

  test('system language: English only for an English device', () {
    expect(L10n.resolveEnglish('system', const Locale('en', 'GB')), isTrue);
    expect(L10n.resolveEnglish('system', const Locale('de')), isFalse);
    expect(L10n.resolveEnglish('system', const Locale('tr')), isFalse);
    expect(L10n.resolveEnglish('en', const Locale('tr')), isTrue);
    expect(L10n.resolveEnglish('tr', const Locale('en')), isFalse);
  });

  test('English dates and rules', () {
    final d = LocalDate(2026, 11, 7);
    expect(longDate(d, en: true), 'November 7, 2026');
    expect(weekdayName(d, en: true), 'Saturday');
    expect(relativeDay(d, d, en: true), 'Today');
    expect(describeRule(WeeklyRule({1, 3, 5}), en: true), 'Mon, Wed, Fri');
    expect(describeRule(OnceRule(d), en: true), 'Once: November 7');
    expect(longDate(d), '7 Kasım 2026');
  });

  test('new settings round-trip and bad values fall back', () {
    const s = AppSettings(
      language: 'en',
      fontChoice: 'dyslexic',
      textScale: 1.35,
      highContrast: true,
    );
    final back = AppSettings.decode(s.encode());
    expect(back.language, 'en');
    expect(back.fontChoice, 'dyslexic');
    expect(back.textScale, 1.35);
    expect(back.highContrast, isTrue);
    final bad = AppSettings.decode(
      '{"language": "fr", "font": "comic", "text_scale": 9, "high_contrast": 1}',
    );
    expect(bad.language, 'system');
    expect(bad.fontChoice, 'system');
    expect(bad.textScale, 2.0);
    expect(bad.highContrast, isFalse);
  });

  testWidgets('English interface: navigation, day title, date and tasks', (
    tester,
  ) async {
    await pump(tester, const AppSettings(language: 'en'));
    expect(find.text('Today'), findsOneWidget);
    expect(find.textContaining('November 7, 2026'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Day'), findsOneWidget);
    expect(find.text('Gün'), findsNothing);
    expect(find.text('Su iç'), findsOneWidget); // the user's own text stays
  });

  testWidgets('switching the language in Settings applies at once and is '
      'saved', (tester) async {
    final c = await pump(tester, const AppSettings(language: 'tr'));
    await tester.tap(find.text('Ayarlar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Language'), findsOneWidget);
    expect((c.store as MemoryTaskStore).settings.language, 'en');
  });

  testWidgets('font, text size and contrast apply on their own', (
    tester,
  ) async {
    await pump(
      tester,
      const AppSettings(
        fontChoice: 'dyslexic',
        textScale: 1.5,
        highContrast: true,
        uiScale: 1.0,
      ),
    );
    final ctx = tester.element(find.text('Su iç'));
    expect(Theme.of(ctx).textTheme.bodyMedium?.fontFamily, 'OpenDyslexic');
    expect(MediaQuery.textScalerOf(ctx).scale(10), closeTo(15, 0.01));
    final bg = tester.widget<DecoratedBox>(
      find.byKey(const Key('app-background')),
    );
    final colors =
        ((bg.decoration as BoxDecoration).gradient! as LinearGradient).colors;
    expect(colors.toSet().length, 1, reason: 'plain background');
    final surface = Theme.of(ctx).colorScheme.surface;
    expect(
      surface == Colors.black || surface == Colors.white,
      isTrue,
      reason: '$surface',
    );
  });

  testWidgets('text size presets and reset in Settings', (tester) async {
    final c = await pump(tester, const AppSettings(language: 'tr'));
    await tester.tap(find.text('Ayarlar'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('font-dyslexic')));
    await tester.tap(find.byKey(const Key('font-dyslexic')));
    await tester.pumpAndSettle();
    expect(c.settings.fontChoice, 'dyslexic');
    await tester.ensureVisible(find.byKey(const Key('text-scale-150')));
    await tester.tap(find.byKey(const Key('text-scale-150')));
    await tester.pumpAndSettle();
    expect(c.settings.textScale, 1.5);
    expect(c.settings.uiScale, 1.0); // the interface scale is untouched
    await tester.ensureVisible(find.byKey(const Key('text-scale-reset')));
    await tester.tap(find.byKey(const Key('text-scale-reset')));
    await tester.pumpAndSettle();
    expect(c.settings.textScale, 1.0);
  });
}
