import 'package:flutter/material.dart';

import 'src/app/task_controller.dart';
import 'src/storage/default_store.dart';
import 'src/ui/app.dart';

const String appVersion = String.fromEnvironment(
  'APP_VERSION',
  defaultValue: '1.0.0',
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final controller = TaskController(store: createDefaultStore());
  runApp(GunlukGorevlerApp(controller: controller, version: appVersion));
  await controller.load();
}
