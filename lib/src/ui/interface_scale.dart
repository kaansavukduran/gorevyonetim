import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Relayout before scaling, so hit targets, dialogs and text all grow together.
/// Keep at least 360 logical pixels available on narrow windows and phones.
class InterfaceScale extends StatelessWidget {
  const InterfaceScale({super.key, required this.scale, required this.child});

  final double scale;
  final Widget child;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final effective = math.min(
        scale,
        math.max(1.0, constraints.maxWidth / 360),
      );
      final size = Size(
        constraints.maxWidth / effective,
        constraints.maxHeight / effective,
      );
      final media = MediaQuery.of(context);
      return ClipRect(
        child: FittedBox(
          fit: BoxFit.fill,
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: size.width,
            height: size.height,
            child: MediaQuery(
              data: media.copyWith(
                size: size,
                padding: media.padding / effective,
                viewPadding: media.viewPadding / effective,
                viewInsets: media.viewInsets / effective,
              ),
              child: child,
            ),
          ),
        ),
      );
    },
  );
}
