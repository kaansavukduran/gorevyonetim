import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../app/task_controller.dart';
import 'home_shell.dart';
import 'interface_scale.dart';
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
      final spec = themeById(controller.settings.themeId);
      return MaterialApp(
        title: 'Günlük Görevler',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(spec),
        locale: const Locale('tr', 'TR'),
        supportedLocales: const [Locale('tr', 'TR')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        builder: (context, child) => DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: spec.gradient.length == 1
                  ? [spec.gradient.first, spec.gradient.first]
                  : spec.gradient,
            ),
          ),
          child: InterfaceScale(
            scale: controller.settings.safeScale,
            child: child ?? const SizedBox.shrink(),
          ),
        ),
        home: HomeShell(controller: controller, version: version),
      );
    },
  );
}
