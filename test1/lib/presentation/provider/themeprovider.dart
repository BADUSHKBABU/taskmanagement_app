


import 'package:flutter/material.dart';
import 'package:test1/domain/repository/auth_repository.dart';

class ThemeProvider extends ChangeNotifier {
  final AuthRepository authRepository;

  // Initial state: ThemeMode.light
  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;

  ThemeProvider({
    required this.authRepository,
  });


  void initThemeFromUser(String? themeModeStr) {
    final targetMode = (themeModeStr == 'dark') ? ThemeMode.dark : ThemeMode.light;
    if (_themeMode != targetMode) {
      _themeMode = targetMode;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }
  }

  Future<void> toggleTheme(String userId) async {
    final nextMode = _themeMode == ThemeMode.light
        ? ThemeMode.dark
        : ThemeMode.light;

    _themeMode = nextMode;
    notifyListeners();

    if (userId.isNotEmpty) {
      final themeStr = nextMode == ThemeMode.dark ? 'dark' : 'light';
      await authRepository.updateThemeMode(userId, themeStr);
    }
  }
}
