import 'package:flutter/material.dart';

import '../domain/task_data.dart';

/// How a [DayStatus] looks: every status has its own icon and word, so
/// colour is never the only signal.
class StatusStyle {
  const StatusStyle(this.icon, this.label, this.color, {this.filled = false});

  final IconData icon;
  final String label;
  final Color color;
  final bool filled;

  static StatusStyle of(DayStatus status, ColorScheme scheme) =>
      switch (status) {
        DayStatus.done => StatusStyle(
          Icons.check_rounded,
          'Yapıldı',
          scheme.primary,
          filled: true,
        ),
        DayStatus.missed => StatusStyle(
          Icons.close_rounded,
          'Yapılmadı',
          scheme.error,
        ),
        DayStatus.pending => StatusStyle(
          Icons.radio_button_unchecked_rounded,
          'Bekliyor',
          scheme.onSurfaceVariant,
        ),
        DayStatus.upcoming => StatusStyle(
          Icons.schedule_rounded,
          'Planlı',
          scheme.outline,
        ),
        DayStatus.notScheduled => StatusStyle(
          Icons.remove_rounded,
          'Bu gün yok',
          scheme.outlineVariant,
        ),
      };
}

/// A small square showing one day's status.
class StatusCell extends StatelessWidget {
  const StatusCell({
    super.key,
    required this.status,
    this.size = 28,
    this.highlight = false,
  });

  final DayStatus status;
  final double size;

  /// Draws a ring (used for today).
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final style = StatusStyle.of(status, scheme);
    final background = switch (status) {
      DayStatus.done => scheme.primary,
      DayStatus.missed => scheme.errorContainer,
      _ => Colors.transparent,
    };
    final foreground = switch (status) {
      DayStatus.done => scheme.onPrimary,
      DayStatus.missed => scheme.onErrorContainer,
      _ => style.color,
    };
    final border = switch (status) {
      DayStatus.done || DayStatus.missed => null,
      DayStatus.notScheduled => null,
      _ => Border.all(color: style.color.withValues(alpha: 0.6)),
    };
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(size * 0.28),
        border: highlight
            ? Border.all(color: scheme.primary, width: 2)
            : border,
      ),
      alignment: Alignment.center,
      child: Icon(style.icon, size: size * 0.62, color: foreground),
    );
  }
}
