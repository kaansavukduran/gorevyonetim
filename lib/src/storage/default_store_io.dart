import 'dart:io';

import 'package:flutter/services.dart';

import 'android_task_store.dart';
import 'file_task_store.dart';
import 'task_store.dart';

/// The store a desktop build uses: a file in the user's data folder.
Future<TaskStore> createDefaultStore() async {
  if (Platform.isAndroid) {
    const channel = MethodChannel('com.gunlukgorevler/files');
    final directory = await channel.invokeMethod<String>('dataDirectory');
    if (directory == null || directory.isEmpty) {
      throw StateError('Uygulama veri klasörü bulunamadı');
    }
    return AndroidTaskStore(directory, channel: channel);
  }
  return FileTaskStore.forThisDevice();
}
