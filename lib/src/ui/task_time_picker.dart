import 'package:flutter/material.dart';

import 'l10n.dart';

import '../domain/task.dart';

/// Start in keyboard entry and always use the unambiguous 24-hour clock.
Future<ClockTime?> pickTaskTime(
  BuildContext context, {
  ClockTime? initial,
}) async {
  final picked = await showTimePicker(
    context: context,
    initialTime: TimeOfDay(
      hour: initial?.hour ?? 9,
      minute: initial?.minute ?? 0,
    ),
    initialEntryMode: TimePickerEntryMode.input,
    helpText: context.t('Görev saati'),
    errorInvalidText: context.t('Geçersiz'),
    hourLabelText: context.t('Saat'),
    minuteLabelText: context.t('Dakika'),
    cancelText: context.t('Vazgeç'),
    confirmText: context.t('Kaydet'),
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
      child: child!,
    ),
  );
  return picked == null ? null : ClockTime(picked.hour, picked.minute);
}
