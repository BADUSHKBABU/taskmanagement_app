import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:test1/presentation/bloc/authbloc/auth_bloc.dart';
import 'package:test1/presentation/bloc/authbloc/auth_event.dart';
import 'package:test1/presentation/bloc/taskbloc/task_bloc.dart';
import 'package:test1/presentation/bloc/taskbloc/task_event.dart';
import 'package:test1/presentation/bloc/taskbloc/task_state.dart';
import 'package:test1/presentation/bloc/themebloc/theme_cubit.dart';
import 'package:test1/presentation/pages/taskpages/addtaskpage.dart';
import 'package:test1/presentation/pages/taskpages/task_tile.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  Timer? _debounce;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (uid.isNotEmpty) {
      context.read<TaskBloc>().add(FetchTasksEvent(userId: uid, refresh: true));
    }

    // Auto-sync offline tasks when internet connection is restored
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      results,
    ) {
      final isOnline =
          !results.contains(ConnectivityResult.none) && results.isNotEmpty;
      if (isOnline) {
        final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
        if (currentUid.isNotEmpty) {
          context.read<TaskBloc>().add(
            FetchTasksEvent(userId: currentUid, refresh: true),
          );
        }
      }
    });

    _scrollController.addListener(() {
      final nearBottom =
          _scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200;
      if (nearBottom) {
        final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
        if (currentUid.isNotEmpty) {
          context.read<TaskBloc>().add(LoadMoreTasksEvent(userId: currentUid));
        }
      }
    });
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      context.read<TaskBloc>().add(SearchTasksEvent(query));
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("My tasks"),
        actions: [
          BlocBuilder<ThemeCubit, ThemeMode>(
            builder: (context, themeMode) {
              return IconButton(
                icon: Icon(
                  themeMode == ThemeMode.dark
                      ? Icons.light_mode
                      : Icons.dark_mode,
                ),
                tooltip: "Toggle Theme",
                onPressed: () {
                  context.read<ThemeCubit>().toggleTheme(uid);
                },
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "Logout",
            onPressed: () {
              context.read<AuthBloc>().add(const SignOutEvent());
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddTaskScreen()),
        ),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          // Offline banner
          StreamBuilder<List<ConnectivityResult>>(
            stream: Connectivity().onConnectivityChanged,
            builder: (context, snapshot) {
              final results = snapshot.data ?? [];
              final offline =
                  results.contains(ConnectivityResult.none) ||
                  results.isEmpty &&
                      snapshot.connectionState == ConnectionState.active;
              if (!offline) return const SizedBox.shrink();
              return Container(
                width: double.infinity,
                color: Colors.amber.shade700.withValues(alpha: 0.2),
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 12,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.wifi_off_rounded,
                      size: 16,
                      color: Colors.amber.shade700,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "You're offline.",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // Search Box
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: "Search by title",
              ),
            ),
          ),

          // Filter chips + sort
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: BlocBuilder<TaskBloc, TaskState>(
              // buildWhen: (p, c) => p.filter != c.filter || p.sortBy != c.sortBy,
              builder: (context, state) {
                return Row(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            ChoiceChip(
                              label: Text(
                                "All",
                                style: TextStyle(
                                  color: state.filter == TaskFilter.all
                                      ? colorScheme.onPrimary
                                      : colorScheme.onSurface,
                                ),
                              ),
                              selected: state.filter == TaskFilter.all,
                              onSelected: (_) => context.read<TaskBloc>().add(
                                const ChangeFilterEvent(TaskFilter.all),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ChoiceChip(
                              label: Text(
                                "Pending",
                                style: TextStyle(
                                  color: state.filter == TaskFilter.pending
                                      ? colorScheme.onPrimary
                                      : colorScheme.onSurface,
                                ),
                              ),
                              selected: state.filter == TaskFilter.pending,
                              onSelected: (_) => context.read<TaskBloc>().add(
                                const ChangeFilterEvent(TaskFilter.pending),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ChoiceChip(
                              label: Text(
                                "Completed",
                                style: TextStyle(
                                  color: state.filter == TaskFilter.completed
                                      ? colorScheme.onPrimary
                                      : colorScheme.onSurface,
                                ),
                              ),
                              selected: state.filter == TaskFilter.completed,
                              onSelected: (_) => context.read<TaskBloc>().add(
                                const ChangeFilterEvent(TaskFilter.completed),
                              ),
                            ),
                             const SizedBox(width: 8),
                             ChoiceChip(
                              label: Text(
                                "Started",
                                style: TextStyle(
                                  color: state.filter == TaskFilter.started
                                      ? colorScheme.onPrimary
                                      : colorScheme.onSurface,
                                ),
                              ),
                              selected: state.filter == TaskFilter.started,
                              onSelected: (_) => context.read<TaskBloc>().add(
                                const ChangeFilterEvent(TaskFilter.started),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    DropdownButton<SortBy>(
                      value: state.sortBy,
                      dropdownColor: colorScheme.surface,
                      underline: const SizedBox(),
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: 14,
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: SortBy.dueDate,
                          child: Text("Due date"),
                        ),
                        DropdownMenuItem(
                          value: SortBy.priority,
                          child: Text("Priority"),
                        ),
                        DropdownMenuItem(
                          value: SortBy.createdDate,
                          child: Text("Created"),
                        ),
                      ],
                      onChanged: (v) =>
                          context.read<TaskBloc>().add(ChangeSortEvent(v!)),
                    ),
                  ],
                );
              },
            ),
          ),

          // Task list
          Expanded(
            child: BlocBuilder<TaskBloc, TaskState>(
              builder: (context, state) {
                if (state.status == TaskStatus.loading && state.tasks.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state.status == TaskStatus.error && state.tasks.isEmpty) {
                  return Center(
                    child: Text(
                      state.error ?? "Something went wrong",
                      style: TextStyle(color: colorScheme.error),
                    ),
                  );
                }
                if (state.visibleTasks.isEmpty) {
                  return Center(
                    child: Text(
                      "No tasks match your filters",
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => context.read<TaskBloc>().add(
                    FetchTasksEvent(userId: uid, refresh: true),
                  ),
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount:state.visibleTasks.length + (state.hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= state.visibleTasks.length) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      final task = state.visibleTasks[index];
                      return TaskTile(
                        task: task,
                        onEdit: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AddTaskScreen(task: task),
                          ),
                        ),
                        onDelete: () {
                          if (task.id != null) {
                            context.read<TaskBloc>().add(
                              DeleteTaskEvent(userId: uid, taskId: task.id!),
                            );
                          }
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
