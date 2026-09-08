import 'package:test1/domain/entity/taskentity.dart';

abstract class TaskRepository {
  Future<List<TaskEntity>> getTasks(
    String userId, {
    int skip = 0,
    int limit = 20,
  });

  Future<TaskEntity> getTask(String userId, int taskId);

  Future<TaskEntity> addTask(String userId, TaskEntity task);

  Future<TaskEntity> updateTask(
    String userId,
    int taskId,
    Map<String, dynamic> changes,
  );

  Future<TaskEntity> toggleTask(String userId, TaskEntity task);

  Future<void> deleteTask(String userId, int taskId);
}
