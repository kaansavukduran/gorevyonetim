import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../app/task_controller.dart';
import 'home_shell.dart';
import 'interface_scale.dart';
import 'l10n.dart';
import 'themes.dart';

class GunlukGorevlerApp extends StatelessWidget {
  const GunlukGorevlerApp({
    super.key,
    required this.controller,
    this.version = '',
  });

  final TaskController controller;
  final String version;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      final settings = controller.settings;
      final custom = customizedTheme(
        themeById(settings.themeId),
        settings.customTheme,
      );
      final spec = settings.highContrast ? highContrastOf(custom) : custom;
      final english = L10n.resolveEnglish(
        settings.language,
        WidgetsBinding.instance.platformDispatcher.locale,
      );
      return MaterialApp(
        title: english ? 'Daily Tasks' : 'Günlük Görevler',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(
          spec,
          fontFamily: fontFamilyFor(settings.fontChoice),
          highContrast: settings.highContrast,
        ),
        locale: english ? const Locale('en', 'US') : const Locale('tr', 'TR'),
        supportedLocales: const [Locale('tr', 'TR'), Locale('en', 'US')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        builder: (context, child) => DecoratedBox(
          key: const Key('app-background'),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: spec.gradient.length == 1
                  ? [spec.gradient.first, spec.gradient.first]
                  : spec.gradient,
            ),
          ),
          child: L10n(
            english: english,
            child: InterfaceScale(
              scale: settings.safeScale,
              child: Builder(
                // Text size on top of the OS text size, independent of the
                // interface scale.
                builder: (context) {
                  final mq = MediaQuery.of(context);
                  return MediaQuery(
                    data: mq.copyWith(
                      textScaler: TextScaler.linear(
                        mq.textScaler.scale(1) * settings.safeTextScale,
                      ),
                    ),
                    child: child ?? const SizedBox.shrink(),
                  );
                },
              ),
            ),
          ),
        ),
        home: HomeShell(controller: controller, version: version),
      );
    },
  );
}
