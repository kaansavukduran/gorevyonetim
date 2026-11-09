import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gunluk_gorevler/src/app/task_controller.dart';
import 'package:gunluk_gorevler/src/app/settings.dart';
import 'package:gunluk_gorevler/src/app/theme_customization.dart';
import 'package:gunluk_gorevler/src/domain/local_date.dart';
import 'package:gunluk_gorevler/src/storage/file_task_store.dart';
import 'package:gunluk_gorevler/src/ui/app.dart';
import 'package:integration_test/integration_test.dart';

/// Runs the real app on the desktop with a real data file: add, tick, then
/// start a new app instance on the same folder and see the same state.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('a task and its tick survive a restart', (tester) async {
    final dir = await Directory.systemTemp.createTemp('gunluk_gorevler_it');
    addTearDown(() => dir.delete(recursive: true));

    Future<TaskController> start() async {
      final c = TaskController(store: FileTaskStore(dir.path));
      await c.load();
      await tester.pumpWidget(
        GunlukGorevlerApp(key: UniqueKey(), controller: c),
      );
      await tester.pumpAndSettle();
      return c;
    }

    final first = await start();
    await tester.enterText(
      find.byKey(const Key('quick-add-field')),
      'Çiçekleri sula',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    final id = first.data.tasks.single.id;
    await tester.dragUntilVisible(
      find.byKey(Key('task-check-$id')),
      find.byType(CustomScrollView),
      const Offset(0, -150),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(Key('task-check-$id')));
    await tester.pumpAndSettle();
    await first.saved;

    final file = File('${dir.path}${Platform.pathSeparator}gorevler.json');
    expect(await file.exists(), isTrue);
    expect(await file.readAsString(), contains('Çiçekleri sula'));

    await first.updateSettings(
      const AppSettings(
        uiScale: 1.37,
        sortByTime: true,
        dailyGoal: 5,
        customTheme: ThemeCustomization(
          enabled: true,
          primary: 0x10B981,
          radius: 23,
        ),
      ),
    );
    final second = await start();
    expect(second.settings.uiScale, 1.37);
    expect(second.settings.sortByTime, isTrue);
    expect(second.settings.dailyGoal, 5);
    expect(second.settings.customTheme.primary, 0x10B981);
    expect(second.settings.customTheme.radius, 23);
    expect(second.data.tasks.single.title, 'Çiçekleri sula');
    expect(second.data.isDone(id, LocalDate.of(DateTime.now())), isTrue);
    expect(find.text('Bugünün hepsi tamam: 1 / 1'), findsOneWidget);
  });
}
