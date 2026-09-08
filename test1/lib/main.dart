import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;

import 'package:test1/core/theme/app_theme.dart';
import 'package:test1/core/widgets/error_view.dart';
import 'package:test1/core/widgets/loading_view.dart';
import 'package:test1/data/localdatasorce/task_local_datasource.dart';
import 'package:test1/data/remotedatasorce/auth_remote_datasource.dart';
import 'package:test1/data/remotedatasorce/task_remote_datasource.dart';
import 'package:test1/data/repository/auth_repository_impl.dart';
import 'package:test1/data/repository/task_repository_impl.dart';
import 'package:test1/domain/usecase/auth_usecases.dart';
import 'package:test1/domain/usecase/task_usecase.dart';
import 'package:test1/firebase_options.dart';
import 'package:test1/presentation/bloc/authbloc/auth_bloc.dart';
import 'package:test1/presentation/bloc/authbloc/auth_state.dart';
import 'package:test1/presentation/bloc/taskbloc/task_bloc.dart';
import 'package:test1/presentation/bloc/themebloc/theme_cubit.dart';
import 'package:test1/presentation/pages/auth/login_screen.dart';
import 'package:test1/presentation/pages/taskpages/tasklistpage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize Hive database for local caching & offline sync
  await Hive.initFlutter();
  final tasksBox = await Hive.openBox(TaskLocalDataSourceImpl.boxName);
  final pendingTasksBox = await Hive.openBox(
    TaskLocalDataSourceImpl.pendingBoxName,
  );

  final httpClient = http.Client();

  final authRemoteDataSource = AuthRemoteDataSourceImpl();
  final taskRemoteDataSource = TaskRemoteDataSourceImpl(httpClient);
  final taskLocalDataSource = TaskLocalDataSourceImpl(
    tasksBox: tasksBox,
    pendingTasksBox: pendingTasksBox,
  );

  final authRepository = AuthRepositoryImpl(
    remoteDataSource: authRemoteDataSource,
  );
  final taskRepository = TaskRepositoryImpl(
    remoteDataSource: taskRemoteDataSource,
    localDataSource: taskLocalDataSource,
  );

  final signInUseCase = SignInUseCase(authRepository);
  final signUpUseCase = SignUpUseCase(authRepository);
  final signOutUseCase = SignOutUseCase(authRepository);
  final getCurrentUserUseCase = GetCurrentUserUseCase(authRepository);

  final getTasksUseCase = GetTasksUseCase(taskRepository);
  final addTaskUseCase = AddTaskUseCase(taskRepository);
  final updateTaskUseCase = UpdateTaskUseCase(taskRepository);
  final toggleTaskStatusUseCase = ToggleTaskStatusUseCase(taskRepository);
  final deleteTaskUseCase = DeleteTaskUseCase(taskRepository);

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider<ThemeCubit>(
          create: (_) => ThemeCubit(authRepository: authRepository),
        ),
        BlocProvider<AuthBloc>(
          create: (_) => AuthBloc(
            signInUseCase: signInUseCase,
            signUpUseCase: signUpUseCase,
            signOutUseCase: signOutUseCase,
            getCurrentUserUseCase: getCurrentUserUseCase,
          ),
        ),
        BlocProvider<TaskBloc>(
          create: (_) => TaskBloc(
            getTasksUseCase: getTasksUseCase,
            addTaskUseCase: addTaskUseCase,
            updateTaskUseCase: updateTaskUseCase,
            toggleTaskStatusUseCase: toggleTaskStatusUseCase,
            deleteTaskUseCase: deleteTaskUseCase,
          ),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeMode>(
      builder: (context, themeMode) {
        return MaterialApp(
          title: 'Task Manager',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeMode,
          home: const AuthGate(),
        );
      },
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is AuthInitialState || state is AuthLoadingState) {
          return const Scaffold(
            body: LoadingView(message: 'Checking authentication status...'),
          );
        }

        if (state is AuthenticatedState) {
          context.read<ThemeCubit>().initThemeFromUser(state.user.themeMode);
          return const TaskListScreen();
        }

        if (state is AuthErrorState) {
          return ErrorView(
            errorMessage: state.message.toString(),
            onRetry: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => LoginScreen()),
              );
            },
          );
        }

        return LoginScreen();
      },
    );
  }
}
