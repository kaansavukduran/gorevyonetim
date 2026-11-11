import 'dart:async';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

/// Tests run as on a Turkish device unless a test chooses English itself
/// (the default language setting follows the device).
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    binding.platformDispatcher.localeTestValue = const Locale('tr', 'TR');
    binding.platformDispatcher.localesTestValue = const [Locale('tr', 'TR')];
  });
  tearDown(() {
    binding.platformDispatcher.clearLocaleTestValue();
    binding.platformDispatcher.clearLocalesTestValue();
  });
  await testMain();
}
