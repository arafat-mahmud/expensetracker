import 'package:flutter/material.dart';
import '../services/hive_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

class ThemeProvider with ChangeNotifier {
  bool _isDarkMode = false;
  final AuthService _authService = AuthService();
  String? _currentUserId;

  bool get isDarkMode => _isDarkMode;

  ThemeProvider() {
    _currentUserId = _authService.getUserId();
    _loadTheme();

    // Listen to auth state changes to detect user switches
    _authService.authStateChanges.listen((user) {
      final newUserId = user?.uid;
      if (_currentUserId != newUserId) {
        print(
            'ThemeProvider: User switch detected from $_currentUserId to $newUserId');
        _currentUserId = newUserId;
        if (newUserId != null) {
          // New user signed in, reload theme
          _loadTheme();
        } else {
          // User signed out, reset to default
          _isDarkMode = false;
          notifyListeners();
        }
      }
    });
  }

  void _loadTheme() {
    _isDarkMode = HiveService.getDarkMode();
    notifyListeners();
  }

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    HiveService.setDarkMode(_isDarkMode);
    notifyListeners();
  }

  // The full design system lives in theme/app_theme.dart
  ThemeData get lightTheme => AppTheme.light(HiveService.getLanguage());

  ThemeData get darkTheme => AppTheme.dark(HiveService.getLanguage());
}
