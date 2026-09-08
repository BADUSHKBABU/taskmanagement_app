import 'package:hive_flutter/hive_flutter.dart';
import 'package:test1/data/model/task_model.dart';

/// Represents a pending offline action (create, update, or delete) to be synchronized with backend API.
class PendingTaskItem {
  final String action; // 'create' | 'update' | 'delete'
  final int taskId;
  final TaskModel? task;

  PendingTaskItem({
    required this.action,
    required this.taskId,
    this.task,
  });

  Map<String, dynamic> toJson() => {
        'action': action,
        'task_id': taskId,
        'task': task?.toJson(),
      };

  factory PendingTaskItem.fromJson(Map<String, dynamic> json) {
    // Standard PendingTaskItem format
    if (json.containsKey('action')) {
      return PendingTaskItem(
        action: json['action'] ?? 'create',
        taskId: json['task_id'] is int
            ? json['task_id'] as int
            : int.tryParse(json['task_id'].toString()) ?? 0,
        task: json['task'] != null
            ? TaskModel.fromJson(Map<String, dynamic>.from(json['task']))
            : null,
      );
    }

    // Backward compatibility for raw TaskModel JSON stored in older versions of Hive box
    final task = TaskModel.fromJson(json);
    return PendingTaskItem(
      action: 'create',
      taskId: task.id ?? 0,
      task: task,
    );
  }
}

/// Abstract interface for local task storage and offline synchronization queue.
abstract class TaskLocalDataSource {
  /// Save a list of tasks into Hive local database
  Future<void> cacheTasks(List<TaskModel> tasks);

  /// Retrieve all cached tasks from Hive local database
  List<TaskModel> getCachedTasks();

  /// Save or update a single task in Hive
  Future<void> cacheSingleTask(TaskModel task);

  /// Save a task locally when offline and queue it for server sync
  Future<TaskModel> saveOfflineTask(TaskModel task, {bool isUpdate = false});

  /// Queue a task deletion when offline
  Future<void> saveOfflineDelete(int taskId);

  /// Get all pending sync items (creates, updates, deletes)
  List<PendingTaskItem> getPendingSyncItems();

  /// Get all pending tasks created/updated while offline that need server sync (legacy fallback)
  List<TaskModel> getPendingUnsyncedTasks();

  /// Remove a task from the pending sync queue after it successfully syncs with the server
  Future<void> removePendingTask(dynamic key);

  /// Remove a single task from Hive by its ID
  Future<void> deleteCachedTask(int taskId);

  /// Clear all cached tasks (e.g. when user signs out)
  Future<void> clearCache();
}

/// Beginner-friendly implementation of TaskLocalDataSource using Hive.
class TaskLocalDataSourceImpl implements TaskLocalDataSource {
  /// Name of the main Hive box for displaying cached tasks
  static const String boxName = 'tasks_box';

  /// Name of the Hive box for storing offline pending tasks to be synced
  static const String pendingBoxName = 'pending_tasks_box';

  /// Main Hive Box instance for UI task list
  final Box tasksBox;

  /// Hive Box instance for offline pending sync queue
  final Box pendingTasksBox;

  TaskLocalDataSourceImpl({
    required this.tasksBox,
    required this.pendingTasksBox,
  });

  @override
  Future<void> cacheTasks(List<TaskModel> tasks) async {
    // Save each server task into Hive using string representation of its ID as key
    for (var task in tasks) {
      if (task.id != null) {
        await tasksBox.put(task.id.toString(), task.toJson());
      }
    }
  }

  @override
  List<TaskModel> getCachedTasks() {
    final List<TaskModel> tasks = [];

    // Retrieve all tasks stored in the main Hive box
    for (var key in tasksBox.keys) {
      final item = tasksBox.get(key);
      if (item != null) {
        final Map<String, dynamic> map = Map<String, dynamic>.from(item);
        tasks.add(TaskModel.fromJson(map));
      }
    }

    return tasks;
  }

  @override
  Future<void> cacheSingleTask(TaskModel task) async {
    if (task.id != null) {
      await tasksBox.put(task.id.toString(), task.toJson());
    }
  }

  @override
  Future<TaskModel> saveOfflineTask(TaskModel task, {bool isUpdate = false}) async {
    // 1. If task has no server ID, generate a positive local ID bounded within 32-bit int range (0 - 2147483647)
    final int tempId = task.id ?? (DateTime.now().millisecondsSinceEpoch % 2147483647);

    // Create updated model with local temp ID
    final localTask = TaskModel(
      id: tempId,
      title: task.title,
      description: task.description,
      priority: task.priority,
      category: task.category,
      dueDate: task.dueDate,
      isCompleted: task.isCompleted,
      createdAt: task.createdAt ?? DateTime.now(),
      updatedAt: task.updatedAt ?? DateTime.now(),
    );

    final taskJson = localTask.toJson();

    // 2. Save in main tasks box so UI shows the updated task immediately offline
    await tasksBox.put(tempId.toString(), taskJson);

    // 3. Determine pending action ('create' vs 'update')
    String action = isUpdate ? 'update' : 'create';
    final existingPendingRaw = pendingTasksBox.get(tempId.toString());
    if (existingPendingRaw != null) {
      final existingPending = PendingTaskItem.fromJson(
        Map<String, dynamic>.from(existingPendingRaw),
      );
      // If a newly created offline task is updated before it ever reaches the server, keep action as 'create'
      if (existingPending.action == 'create') {
        action = 'create';
      }
    }

    final pendingItem = PendingTaskItem(
      action: action,
      taskId: tempId,
      task: localTask,
    );

    // 4. Save in pending tasks box for auto-sync when internet returns
    await pendingTasksBox.put(tempId.toString(), pendingItem.toJson());

    return localTask;
  }

  @override
  Future<void> saveOfflineDelete(int taskId) async {
    // Remove from UI cache immediately
    await tasksBox.delete(taskId.toString());

    final existingPendingRaw = pendingTasksBox.get(taskId.toString());
    if (existingPendingRaw != null) {
      final existingPending = PendingTaskItem.fromJson(
        Map<String, dynamic>.from(existingPendingRaw),
      );
      // If task was created offline and deleted before syncing to server, simply cancel pending creation
      if (existingPending.action == 'create') {
        await pendingTasksBox.delete(taskId.toString());
        return;
      }
    }

    final pendingItem = PendingTaskItem(
      action: 'delete',
      taskId: taskId,
    );
    await pendingTasksBox.put(taskId.toString(), pendingItem.toJson());
  }

  @override
  List<PendingTaskItem> getPendingSyncItems() {
    final List<PendingTaskItem> items = [];

    // Loop through pendingTasksBox to find unsynced operations
    for (var key in pendingTasksBox.keys) {
      final rawItem = pendingTasksBox.get(key);
      if (rawItem != null) {
        final Map<String, dynamic> map = Map<String, dynamic>.from(rawItem);
        items.add(PendingTaskItem.fromJson(map));
      }
    }

    return items;
  }

  @override
  List<TaskModel> getPendingUnsyncedTasks() {
    return getPendingSyncItems()
        .where((item) => item.task != null && item.action != 'delete')
        .map((item) => item.task!)
        .toList();
  }

  @override
  Future<void> removePendingTask(dynamic key) async {
    if (key != null) {
      await pendingTasksBox.delete(key.toString());
    }
  }

  @override
  Future<void> deleteCachedTask(int taskId) async {
    await tasksBox.delete(taskId.toString());
    await pendingTasksBox.delete(taskId.toString());
  }

  @override
  Future<void> clearCache() async {
    await tasksBox.clear();
    await pendingTasksBox.clear();
  }
}
