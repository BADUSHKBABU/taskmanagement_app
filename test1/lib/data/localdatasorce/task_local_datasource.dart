import 'package:hive_flutter/hive_flutter.dart';
import 'package:test1/data/model/task_model.dart';

class PendingTaskItem {
  final String action;
  final int taskId;
  final TaskModel? task;

  PendingTaskItem({required this.action, required this.taskId, this.task});

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

    final task = TaskModel.fromJson(json);
    return PendingTaskItem(action: 'create', taskId: task.id ?? 0, task: task);
  }
}

abstract class TaskLocalDataSource {
  /// Save a list of tasks into Hive local database
  Future<void> cacheTasks(List<TaskModel> tasks);

  /// Retrieve all cached tasks from Hive local database
  List<TaskModel> getCachedTasks();

  /// Save or update a single task in Hive
  Future<void> cacheSingleTask(TaskModel task);

  /// Save a task locally
  Future<TaskModel> saveOfflineTask(TaskModel task, {bool isUpdate = false});

  /// Queue a tsk
  Future<void> saveOfflineDelete(int taskId);

  /// (creates, updates, deletes)
  List<PendingTaskItem> getPendingSyncItems();

  List<TaskModel> getPendingUnsyncedTasks();

  Future<void> removePendingTask(dynamic key);

  Future<void> deleteCachedTask(int taskId);

  Future<void> clearCache();
}

class TaskLocalDataSourceImpl implements TaskLocalDataSource {
  static const String boxName = 'tasks_box';

  static const String pendingBoxName = 'pending_tasks_box';

  final Box tasksBox;

  final Box pendingTasksBox;

  TaskLocalDataSourceImpl({
    required this.tasksBox,
    required this.pendingTasksBox,
  });

  @override
  Future<void> cacheTasks(List<TaskModel> tasks) async {
    for (var task in tasks) {
      if (task.id != null) {
        await tasksBox.put(task.id.toString(), task.toJson());
      }
    }
  }

  @override
  List<TaskModel> getCachedTasks() {
    final List<TaskModel> tasks = [];

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
  Future<TaskModel> saveOfflineTask(
    TaskModel task, {
    bool isUpdate = false,
  }) async {
    final int tempId =
        task.id ?? (DateTime.now().millisecondsSinceEpoch % 2147483647);

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

    await tasksBox.put(tempId.toString(), taskJson);

    String action = isUpdate ? 'update' : 'create';
    final existingPendingRaw = pendingTasksBox.get(tempId.toString());
    if (existingPendingRaw != null) {
      final existingPending = PendingTaskItem.fromJson(
        Map<String, dynamic>.from(existingPendingRaw),
      );
      if (existingPending.action == 'create') {
        action = 'create';
      }
    }

    final pendingItem = PendingTaskItem(
      action: action,
      taskId: tempId,
      task: localTask,
    );

    await pendingTasksBox.put(tempId.toString(), pendingItem.toJson());

    return localTask;
  }

  @override
  Future<void> saveOfflineDelete(int taskId) async {
    await tasksBox.delete(taskId.toString());

    final existingPendingRaw = pendingTasksBox.get(taskId.toString());
    if (existingPendingRaw != null) {
      final existingPending = PendingTaskItem.fromJson(
        Map<String, dynamic>.from(existingPendingRaw),
      );
      if (existingPending.action == 'create') {
        await pendingTasksBox.delete(taskId.toString());
        return;
      }
    }

    final pendingItem = PendingTaskItem(action: 'delete', taskId: taskId);
    await pendingTasksBox.put(taskId.toString(), pendingItem.toJson());
  }

  @override
  List<PendingTaskItem> getPendingSyncItems() {
    final List<PendingTaskItem> items = [];

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
