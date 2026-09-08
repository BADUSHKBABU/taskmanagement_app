import 'package:flutter/foundation.dart';
import 'package:test1/domain/entity/taskentity.dart';

enum TaskStatus { initial, loading, success, error }

enum TaskFilter { all, pending, completed, started }

enum SortBy { dueDate, priority, createdDate }

@immutable
class TaskState {
  final TaskStatus status;
  final List<TaskEntity> tasks;
  final TaskFilter filter;
  final SortBy sortBy;
  final String searchQuery;
  final bool hasMore;
  final int skip;
  final int limit;
  final String? error;

  const TaskState({
    this.status = TaskStatus.initial,
    this.tasks = const [],
    this.filter = TaskFilter.all,
    this.sortBy = SortBy.dueDate,
    this.searchQuery = '',
    this.hasMore = true,
    this.skip = 0,
    this.limit = 20,
    this.error,
  });

  TaskState copyWith({
    TaskStatus? status,
    List<TaskEntity>? tasks,
    TaskFilter? filter,
    SortBy? sortBy,
    String? searchQuery,
    bool? hasMore,
    int? skip,
    int? limit,
    String? error,
  }) {
    return TaskState(
      status: status ?? this.status,
      tasks: tasks ?? this.tasks,
      filter: filter ?? this.filter,
      sortBy: sortBy ?? this.sortBy,
      searchQuery: searchQuery ?? this.searchQuery,
      hasMore: hasMore ?? this.hasMore,
      skip: skip ?? this.skip,
      limit: limit ?? this.limit,
      error: error,
    );
  }

  List<TaskEntity> get visibleTasks {
    List<TaskEntity> result = List.from(tasks);

    // Filter by search query
    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      result = result
          .where(
            (t) =>
                t.title.toLowerCase().contains(q) ||
                (t.description != null &&
                    t.description!.toLowerCase().contains(q)),
          )
          .toList();
    }

    // Filter by completion status
    if (filter == TaskFilter.pending) {
      result = result.where((t) => !t.isCompleted).toList();
    } else if (filter == TaskFilter.completed) {
      result = result.where((t) => t.isCompleted).toList();
    } else if (filter == TaskFilter.started) {
      result = result.where((t) => !t.isCompleted && t.priority == "High").toList();
    }

    // Sort
    result.sort((a, b) {
      if (sortBy == SortBy.dueDate) {
        if (a.dueDate == null && b.dueDate == null) return 0;
        if (a.dueDate == null) return 1;
        if (b.dueDate == null) return -1;
        return a.dueDate!.compareTo(b.dueDate!);
      } else if (sortBy == SortBy.priority) {
        final weight = {"High": 3, "Medium": 2, "Low": 1};
        final pA = weight[a.priority] ?? 0;
        final pB = weight[b.priority] ?? 0;
        return pB.compareTo(pA); // High priority first
      } else if (sortBy == SortBy.createdDate) {
        if (a.createdAt == null && b.createdAt == null) return 0;
        if (a.createdAt == null) return 1;
        if (b.createdAt == null) return -1;
        return b.createdAt!.compareTo(a.createdAt!);
      }
      return 0;
    });

    return result;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskState &&
          runtimeType == other.runtimeType &&
          status == other.status &&
          listEquals(tasks, other.tasks) &&
          filter == other.filter &&
          sortBy == other.sortBy &&
          searchQuery == other.searchQuery &&
          hasMore == other.hasMore &&
          skip == other.skip &&
          limit == other.limit &&
          error == other.error;

  @override
  int get hashCode => Object.hash(
    status,
    Object.hashAll(tasks),
    filter,
    sortBy,
    searchQuery,
    hasMore,
    skip,
    limit,
    error,
  );
}
