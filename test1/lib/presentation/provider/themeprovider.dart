// import 'package:flutter/material.dart';
// import 'package:test1/domain/repository/auth_repository.dart';

// class ThemeProvider extends ChangeNotifier {
//   ThemeMode _themeMode = ThemeMode.system;

//   ThemeMode get themeMode => _themeMode;
//  final AuthRepository authRepository;
//  ThemeProvider({required this.authRepository});
 
//   void initThemeFromUser(String? themeModeStr) {
//     if (themeModeStr == 'dark') {
//       emit(ThemeMode.dark);
//     } else {
//       emit(ThemeMode.light);
//     }
//   }
//   void toggleTheme(String userId) async {
//     print("user id is$userId");

//     _themeMode = _themeMode == ThemeMode.light
//         ? ThemeMode.dark
//         : ThemeMode.light;
//          if (userId.isNotEmpty) {
//       final themeStr = _themeMode == ThemeMode.dark ? 'dark' : 'light';
//       await authRepository.updateThemeMode(userId, themeStr);
//     }
//     notifyListeners();
//   }
// }


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

  /// Initialize theme from user preference without triggering build phase errors
  void initThemeFromUser(String? themeModeStr) {
    final targetMode = (themeModeStr == 'dark') ? ThemeMode.dark : ThemeMode.light;
    if (_themeMode != targetMode) {
      _themeMode = targetMode;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }
  }

  /// Toggle theme between light and dark mode and sync with Firestore
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
