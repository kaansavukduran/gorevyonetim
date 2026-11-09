import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gunluk_gorevler/src/domain/repeat_rule.dart';
import 'package:gunluk_gorevler/src/storage/memory_task_store.dart';

import 'app_test.dart' show pumpApp;
import 'customization_test.dart' show reveal;

class PrivateStore extends MemoryTaskStore {
  @override
  bool get persistent => true;

  @override
  bool get usesSystemFilePicker => true;

  @override
  String get location => '/private/internal/path/gorevler.json';
}

void main() {
  testWidgets('private storage explains backups without an unusable folder', (
    tester,
  ) async {
    final store = PrivateStore();
    await pumpApp(tester, store: store, size: const Size(390, 900));
    await tester.tap(find.text('Ayarlar'));
    await tester.pumpAndSettle();
    await reveal(tester, const Key('private-storage-help'));
    expect(find.textContaining('kaldırmadan önce'), findsOneWidget);
    expect(find.text(store.location), findsNothing);
    expect(find.byKey(const Key('about-open-folder')), findsNothing);
    expect(find.byKey(const Key('about-location')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'cancelled empty document picker dismisses without a false error',
    (tester) async {
      final h = await pumpApp(
        tester,
        store: PrivateStore(),
        seed: (c) => c.addTask(
          title: 'Korunan görev',
          rule: const DailyRule(),
          start: c.today,
        ),
      );
      await h.controller.saved;
      final before = h.store.saved;
      await tester.tap(find.text('Ayarlar'));
      await tester.pumpAndSettle();
      await reveal(tester, const Key('import'));
      await tester.tap(find.byKey(const Key('import')));
      await tester.pumpAndSettle();
      expect(find.text('Yedek seç'), findsNothing);
      expect(find.textContaining('bulunamadı'), findsNothing);
      expect(h.store.saved, before);
      expect(h.controller.data.tasks.single.title, 'Korunan görev');
    },
  );

  testWidgets('browser preview accurately says that closing loses its data', (
    tester,
  ) async {
    await pumpApp(tester);
    await tester.tap(find.text('Ayarlar'));
    await tester.pumpAndSettle();
    await reveal(tester, const Key('export'));
    await tester.drag(
      find.byKey(const Key('settings-list')),
      const Offset(0, -200),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('sekme kapatılınca kaybolur'), findsOneWidget);
    expect(find.byKey(const Key('about-open-folder')), findsNothing);
  });
}
