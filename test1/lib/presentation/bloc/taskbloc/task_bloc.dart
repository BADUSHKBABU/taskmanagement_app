import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:test1/core/errors/taskerrormessage.dart';
import 'package:test1/domain/entity/taskentity.dart';
import 'package:test1/domain/usecase/task_usecase.dart';
import 'package:test1/presentation/bloc/taskbloc/task_event.dart';
import 'package:test1/presentation/bloc/taskbloc/task_state.dart';

class TaskBloc extends Bloc<TaskEvent, TaskState> {
  final GetTasksUseCase getTasksUseCase;
  final AddTaskUseCase addTaskUseCase;
  final UpdateTaskUseCase updateTaskUseCase;
  final ToggleTaskStatusUseCase toggleTaskStatusUseCase;
  final DeleteTaskUseCase deleteTaskUseCase;

  TaskBloc({
    required this.getTasksUseCase,
    required this.addTaskUseCase,
    required this.updateTaskUseCase,
    required this.toggleTaskStatusUseCase,
    required this.deleteTaskUseCase,
  }) : super(const TaskState()) {
    on<FetchTasksEvent>(_onFetchTasks);
    on<LoadMoreTasksEvent>(_onLoadMoreTasks);
    on<SearchTasksEvent>(_onSearchTasks);
    on<ChangeFilterEvent>(_onChangeFilter);
    on<ChangeSortEvent>(_onChangeSort);
    on<AddTaskEvent>(_onAddTask);
    on<UpdateTaskEvent>(_onUpdateTask);
    on<ToggleTaskEvent>(_onToggleTask);
    on<DeleteTaskEvent>(_onDeleteTask);
  }

  Future<void> _onFetchTasks(
    FetchTasksEvent event,
    Emitter<TaskState> emit,
  ) async {
    emit(state.copyWith(status: TaskStatus.loading, error: null));
    try {
      final fetchedTasks = await getTasksUseCase(
        event.userId,
        skip: 0,
        limit: state.limit,
      );
      emit(state.copyWith(
        status: TaskStatus.success,
        tasks: fetchedTasks,
        skip: fetchedTasks.length,
        hasMore: fetchedTasks.length >= state.limit,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: TaskStatus.error,
        error: getTaskErrorMessage(e),
      ));
    }
  }

  Future<void> _onLoadMoreTasks(
    LoadMoreTasksEvent event,
    Emitter<TaskState> emit,
  ) async {
    if (!state.hasMore || state.status == TaskStatus.loading) return;

    try {
      final newTasks = await getTasksUseCase(
        event.userId,
        skip: state.skip,
        limit: state.limit,
      );
      if (newTasks.isEmpty) {
        emit(state.copyWith(hasMore: false));
      } else {
        final updatedTasks = List<TaskEntity>.from(state.tasks)..addAll(newTasks);
        emit(state.copyWith(
          tasks: updatedTasks,
          skip: state.skip + newTasks.length,
          hasMore: newTasks.length >= state.limit,
        ));
      }
    } catch (e) {
      emit(state.copyWith(error: getTaskErrorMessage(e)));
    }
  }

  void _onSearchTasks(SearchTasksEvent event, Emitter<TaskState> emit) {
    emit(state.copyWith(searchQuery: event.query));
  }

  void _onChangeFilter(ChangeFilterEvent event, Emitter<TaskState> emit) {
    emit(state.copyWith(filter: event.filter));
  }

  void _onChangeSort(ChangeSortEvent event, Emitter<TaskState> emit) {
    emit(state.copyWith(sortBy: event.sortBy));
  }

  Future<void> _onAddTask(
    AddTaskEvent event,
    Emitter<TaskState> emit,
  ) async {
    try {
      final newTask = await addTaskUseCase(event.userId, event.task);
      final updatedTasks = [newTask, ...state.tasks];
      emit(state.copyWith(
        status: TaskStatus.success,
        tasks: updatedTasks,
        error: null,
      ));
    } catch (e) {
      emit(state.copyWith(error: getTaskErrorMessage(e)));
    }
  }

  Future<void> _onUpdateTask(
    UpdateTaskEvent event,
    Emitter<TaskState> emit,
  ) async {
    try {
      final updatedTask = await updateTaskUseCase(
        event.userId,
        event.taskId,
        event.changes,
      );
      final updatedList = state.tasks.map((t) {
        return (t.id == event.taskId) ? updatedTask : t;
      }).toList();

      emit(state.copyWith(
        status: TaskStatus.success,
        tasks: updatedList,
        error: null,
      ));
    } catch (e) {
      emit(state.copyWith(error: getTaskErrorMessage(e)));
    }
  }

  Future<void> _onToggleTask(
    ToggleTaskEvent event,
    Emitter<TaskState> emit,
  ) async {
    final originalTasks = List<TaskEntity>.from(state.tasks);

    // Optimistic UI update
    final optimisticList = state.tasks.map((t) {
      if (t.id == event.task.id) {
        return t.copyWith(isCompleted: !t.isCompleted);
      }
      return t;
    }).toList();

    emit(state.copyWith(tasks: optimisticList, error: null));

    try {
      final updatedTask = await toggleTaskStatusUseCase(event.userId, event.task);
      final confirmedList = state.tasks.map((t) {
        return (t.id == updatedTask.id) ? updatedTask : t;
      }).toList();
      emit(state.copyWith(tasks: confirmedList));
    } catch (e) {
      // Revert optimistic update on failure
      emit(state.copyWith(
        tasks: originalTasks,
        error: getTaskErrorMessage(e),
      ));
    }
  }

  Future<void> _onDeleteTask(
    DeleteTaskEvent event,
    Emitter<TaskState> emit,
  ) async {
    final originalTasks = List<TaskEntity>.from(state.tasks);

    // Optimistic UI delete
    final optimisticList = state.tasks.where((t) => t.id != event.taskId).toList();
    emit(state.copyWith(tasks: optimisticList, error: null));

    try {
      await deleteTaskUseCase(event.userId, event.taskId);
    } catch (e) {
      // Revert on failure
      emit(state.copyWith(
        tasks: originalTasks,
        error: getTaskErrorMessage(e),
      ));
    }
  }
}
