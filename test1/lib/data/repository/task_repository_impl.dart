import 'dart:io';

import 'package:test1/core/errors/exceptions.dart';
import 'package:test1/data/localdatasorce/task_local_datasource.dart';
import 'package:test1/data/model/task_model.dart';
import 'package:test1/data/remotedatasorce/task_remote_datasource.dart';
import 'package:test1/domain/entity/taskentity.dart';
import 'package:test1/domain/repository/task_repository.dart';

class TaskRepositoryImpl implements TaskRepository {
  final TaskRemoteDataSource remoteDataSource;
  final TaskLocalDataSource localDataSource;

  TaskRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  /// Automatically syncs any pending offline operations (create, update, delete) to the backend API server
  Future<void> syncPendingTasks(String userId) async {
    final pendingItems = localDataSource.getPendingSyncItems();
    if (pendingItems.isEmpty) return;

    print("Syncing ${pendingItems.length} pending offline operation(s) to server...");

    for (var item in pendingItems) {
      try {
        if (item.action == 'create' && item.task != null) {
          // 1. Post new task to backend API
          final createdServerTask = await remoteDataSource.addTask(userId, item.task!);

          // 2. Remove temporary pending task item & temp cached task
          await localDataSource.removePendingTask(item.taskId);
          await localDataSource.deleteCachedTask(item.taskId);

          // 3. Cache confirmed server task into local Hive box
          await localDataSource.cacheSingleTask(createdServerTask);
          print("Successfully synced newly created task '${item.task?.title}' to server!");
        } else if (item.action == 'update' && item.task != null) {
          // 1. Update existing task on backend API
          final updatedServerTask = await remoteDataSource.updateTask(
            userId,
            item.taskId,
            item.task!.toJson(),
          );

          // 2. Remove pending task item
          await localDataSource.removePendingTask(item.taskId);

          // 3. Cache updated task into local Hive box
          await localDataSource.cacheSingleTask(updatedServerTask);
          print("Successfully synced updated task '${item.task?.title}' to server!");
        } else if (item.action == 'delete') {
          // 1. Delete task on backend API
          await remoteDataSource.deleteTask(userId, item.taskId);

          // 2. Remove pending item and local cached task
          await localDataSource.removePendingTask(item.taskId);
          await localDataSource.deleteCachedTask(item.taskId);
          print("Successfully synced deleted task ID ${item.taskId} on server!");
        }
      } catch (e) {
        print("Could not sync pending action '${item.action}' for task ID ${item.taskId}: $e");
      }
    }
  }

  @override
  Future<List<TaskEntity>> getTasks(
    String userId, {
    int skip = 0,
    int limit = 20,
  }) async {
    try {
      // 1. Sync any pending offline tasks first before getting fresh list
      await syncPendingTasks(userId);

      // 2. Fetch fresh tasks from remote API server
      final result = await remoteDataSource.getTasks(userId, skip: skip, limit: limit);

      // 3. Cache fresh tasks to Hive database
      await localDataSource.cacheTasks(result.tasks);

      return result.tasks;
    } catch (e) {
      // 4. OFFLINE FALLBACK: Load cached tasks from Hive database
      final cachedTasks = localDataSource.getCachedTasks();
      if (cachedTasks.isNotEmpty) {
        return cachedTasks;
      }
      rethrow;
    }
  }

  @override
  Future<TaskEntity> getTask(String userId, int taskId) async {
    try {
      final task = await remoteDataSource.getTask(userId, taskId);
      await localDataSource.cacheSingleTask(task);
      return task;
    } catch (e) {
      final cachedTasks = localDataSource.getCachedTasks();
      return cachedTasks.firstWhere(
        (t) => t.id == taskId,
        orElse: () => throw e,
      );
    }
  }

  @override
  Future<TaskEntity> addTask(String userId, TaskEntity task) async {
    final taskModel = TaskModel.fromEntity(task);
    try {
      // Try posting task to remote API server
      final createdTask = await remoteDataSource.addTask(userId, taskModel);
      await localDataSource.cacheSingleTask(createdTask);
      return createdTask;
    } on SocketException catch (_) {
      // OFFLINE HANDLER: Save locally to Hive & queue for auto-sync when internet returns
      print("No internet connection. Saving task locally in Hive for auto-sync!");
      return await localDataSource.saveOfflineTask(taskModel, isUpdate: false);
    } catch (e) {
      if (e is NetworkException) {
        print("Network exception. Saving task locally in Hive for auto-sync!");
        return await localDataSource.saveOfflineTask(taskModel, isUpdate: false);
      }
      rethrow;
    }
  }

  @override
  Future<TaskEntity> updateTask(
    String userId,
    int taskId,
    Map<String, dynamic> changes,
  ) async {
    try {
      final updatedTask = await remoteDataSource.updateTask(userId, taskId, changes);
      await localDataSource.cacheSingleTask(updatedTask);
      return updatedTask;
    } on SocketException catch (_) {
      return await _handleOfflineUpdate(taskId, changes);
    } catch (e) {
      if (e is NetworkException) {
        return await _handleOfflineUpdate(taskId, changes);
      }
      rethrow;
    }
  }

  Future<TaskModel> _handleOfflineUpdate(int taskId, Map<String, dynamic> changes) async {
    print("No internet connection. Saving updated task locally in Hive for auto-sync!");
    final cachedTasks = localDataSource.getCachedTasks();
    TaskModel existingTask;
    try {
      existingTask = cachedTasks.firstWhere((t) => t.id == taskId);
    } catch (_) {
      existingTask = TaskModel(
        id: taskId,
        title: changes['title'] ?? 'Updated Task',
        priority: changes['priority'] ?? 'Medium',
        category: changes['category'] ?? 'Work',
      );
    }

    final updatedTask = TaskModel(
      id: taskId,
      title: changes['title'] ?? existingTask.title,
      description: changes['description'] ?? existingTask.description,
      priority: changes['priority'] ?? existingTask.priority,
      category: changes['category'] ?? existingTask.category,
      dueDate: changes['due_date'] != null
          ? DateTime.tryParse(changes['due_date'].toString())
          : existingTask.dueDate,
      isCompleted: changes['is_completed'] ?? existingTask.isCompleted,
      createdAt: existingTask.createdAt,
      updatedAt: DateTime.now(),
    );

    return await localDataSource.saveOfflineTask(updatedTask, isUpdate: true);
  }

  @override
  Future<TaskEntity> toggleTask(String userId, TaskEntity task) async {
    if (task.id == null) {
      throw Exception("Cannot toggle task without a valid task ID.");
    }
    final newStatus = !task.isCompleted;
    return await updateTask(userId, task.id!, {
      "is_completed": newStatus,
    });
  }

  @override
  Future<void> deleteTask(String userId, int taskId) async {
    try {
      await remoteDataSource.deleteTask(userId, taskId);
      await localDataSource.deleteCachedTask(taskId);
    } catch (e) {
      // If offline, save deletion request to pending queue & remove from local Hive box
      await localDataSource.saveOfflineDelete(taskId);
    }
  }
}