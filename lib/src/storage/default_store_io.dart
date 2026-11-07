import 'file_task_store.dart';
import 'task_store.dart';

/// The store a desktop build uses: a file in the user's data folder.
TaskStore createDefaultStore() => FileTaskStore.forThisDevice();
