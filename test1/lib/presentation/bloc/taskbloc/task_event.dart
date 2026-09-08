import 'package:flutter/foundation.dart';
import 'package:test1/domain/entity/taskentity.dart';
import 'package:test1/presentation/bloc/taskbloc/task_state.dart';

@immutable
abstract class TaskEvent {
  const TaskEvent();
}

class FetchTasksEvent extends TaskEvent {
  final String userId;
  final bool refresh;

  const FetchTasksEvent({required this.userId, this.refresh = false});
}

class LoadMoreTasksEvent extends TaskEvent {
  final String userId;

  const LoadMoreTasksEvent({required this.userId});
}

class SearchTasksEvent extends TaskEvent {
  final String query;

  const SearchTasksEvent(this.query);
}

class ChangeFilterEvent extends TaskEvent {
  final TaskFilter filter;

  const ChangeFilterEvent(this.filter);
}

class ChangeSortEvent extends TaskEvent {
  final SortBy sortBy;

  const ChangeSortEvent(this.sortBy);
}

class AddTaskEvent extends TaskEvent {
  final String userId;
  final TaskEntity task;

  const AddTaskEvent({required this.userId, required this.task});
}

class UpdateTaskEvent extends TaskEvent {
  final String userId;
  final int taskId;
  final Map<String, dynamic> changes;

  const UpdateTaskEvent({
    required this.userId,
    required this.taskId,
    required this.changes,
  });
}

class ToggleTaskEvent extends TaskEvent {
  final String userId;
  final TaskEntity task;

  const ToggleTaskEvent({required this.userId, required this.task});
}

class DeleteTaskEvent extends TaskEvent {
  final String userId;
  final int taskId;

  const DeleteTaskEvent({required this.userId, required this.taskId});
}
