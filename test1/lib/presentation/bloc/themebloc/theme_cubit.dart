import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:test1/domain/repository/auth_repository.dart';

class ThemeCubit extends Cubit<ThemeMode> {
  final AuthRepository authRepository;

  ThemeCubit({required this.authRepository}) : super(ThemeMode.light);

  void initThemeFromUser(String? themeModeStr) {
    if (themeModeStr == 'dark') {
      emit(ThemeMode.dark);
    } else {
      emit(ThemeMode.light);
    }
  }

  Future<void> toggleTheme(String userId) async {
    final nextMode = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    emit(nextMode);

    if (userId.isNotEmpty) {
      final themeStr = nextMode == ThemeMode.dark ? 'dark' : 'light';
      await authRepository.updateThemeMode(userId, themeStr);
    }
  }
}
