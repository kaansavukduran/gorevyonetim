import 'memory_task_store.dart';
import 'task_store.dart';

/// The browser preview keeps nothing (the app is made for Windows).
TaskStore createDefaultStore() => MemoryTaskStore();
