import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gunluk_gorevler/src/app/settings.dart';
import 'package:gunluk_gorevler/src/app/task_controller.dart';
import 'package:gunluk_gorevler/src/domain/repeat_rule.dart';
import 'package:gunluk_gorevler/src/storage/default_store.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  if (!Platform.isAndroid) return;
  testWidgets('Android native directory keeps tasks and settings on reopen', (
    tester,
  ) async {
    final store = await createDefaultStore();
    expect(store.location, contains('/files/'));
    expect(store.location, isNot(contains('/sdcard/')));
    final first = TaskController(store: store);
    await first.load();
    final task = first.addTask(
      title: 'Android yeniden açılış',
      rule: const DailyRule(),
      start: first.today,
    );
    first.toggle(task.id, first.today);
    await first.saved;
    await first.updateSettings(
      const AppSettings(uiScale: 1.5, charClass: 'buyucu'),
    );
    final second = TaskController(store: await createDefaultStore());
    await second.load();
    expect(second.data.taskById(task.id)?.title, 'Android yeniden açılış');
    expect(second.data.isDone(task.id, second.today), isTrue);
    expect(second.settings.uiScale, 1.5);
    expect(second.settings.charClass, 'buyucu');
    first.dispose();
    second.dispose();
  });
}
