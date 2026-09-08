import 'package:test1/domain/entity/taskentity.dart';
import 'package:test1/domain/repository/task_repository.dart';

class GetTasksUseCase {
  final TaskRepository repository;
  GetTasksUseCase(this.repository);

  Future<List<TaskEntity>> call(String userId, {int skip = 0, int limit = 20}) {
    return repository.getTasks(userId, skip: skip, limit: limit);
  }
}

class GetTaskUseCase {
  final TaskRepository repository;
  GetTaskUseCase(this.repository);

  Future<TaskEntity> call(String userId, int taskId) {
    return repository.getTask(userId, taskId);
  }
}

class AddTaskUseCase {
  final TaskRepository repository;
  AddTaskUseCase(this.repository);

  Future<TaskEntity> call(String userId, TaskEntity task) {
    return repository.addTask(userId, task);
  }
}

class UpdateTaskUseCase {
  final TaskRepository repository;
  UpdateTaskUseCase(this.repository);

  Future<TaskEntity> call(String userId, int taskId, Map<String, dynamic> changes) {
    return repository.updateTask(userId, taskId, changes);
  }
}

class ToggleTaskStatusUseCase {
  final TaskRepository repository;
  ToggleTaskStatusUseCase(this.repository);

  Future<TaskEntity> call(String userId, TaskEntity task) {
    return repository.toggleTask(userId, task);
  }
}

class DeleteTaskUseCase {
  final TaskRepository repository;
  DeleteTaskUseCase(this.repository);

  Future<void> call(String userId, int taskId) {
    return repository.deleteTask(userId, taskId);
  }
}