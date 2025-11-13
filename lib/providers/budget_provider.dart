import 'package:flutter/foundation.dart';
import '../services/hive_service.dart';
import '../services/auth_service.dart';
import '../services/google_drive_service.dart';

class BudgetProvider with ChangeNotifier {
  double _monthlyBudget = 10000.0;
  final AuthService _authService = AuthService();
  final GoogleDriveService _driveService = GoogleDriveService();
  String? _currentUserId;

  double get monthlyBudget => _monthlyBudget;

  BudgetProvider() {
    _currentUserId = _authService.getUserId();
    _loadBudget();

    // Listen to auth state changes to detect user switches
    _authService.authStateChanges.listen((user) {
      final newUserId = user?.uid;
      if (_currentUserId != newUserId) {
        print(
            'BudgetProvider: User switch detected from $_currentUserId to $newUserId');
        _currentUserId = newUserId;
        if (newUserId != null) {
          // New user signed in, reload budget
          _loadBudget();
        } else {
          // User signed out, reset to default
          _monthlyBudget = 10000.0;
          notifyListeners();
        }
      }
    });
  }

  void _loadBudget() {
    _monthlyBudget = HiveService.getMonthlyBudget();
    notifyListeners();
  }

  Future<void> setMonthlyBudget(double budget) async {
    _monthlyBudget = budget;
    await HiveService.setMonthlyBudget(budget);
    notifyListeners();
    
    // Backup to Google Drive immediately
    try {
      final expenses = HiveService.getAllExpenses();
      await _driveService.backupExpenses(expenses, monthlyBudget: budget);
      print('✅ Budget backed up to Google Drive: $budget');
    } catch (e) {
      print('⚠️ Failed to backup budget to Drive: $e');
    }
  }

  double getBudgetUsedPercentage(double totalExpense) {
    if (_monthlyBudget == 0) return 0;
    return (totalExpense / _monthlyBudget).clamp(0.0, 1.0);
  }

  double getRemainingBudget(double totalExpense) {
    return (_monthlyBudget - totalExpense).clamp(0.0, _monthlyBudget);
  }

  bool isOverBudget(double totalExpense) {
    return totalExpense > _monthlyBudget;
  }
}
