import 'package:flutter/foundation.dart';
import '../services/hive_service.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

class BudgetProvider with ChangeNotifier {
  double _monthlyBudget = 10000.0;
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
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

  // Public method to reload budget (e.g., after data restore)
  void reloadBudget() {
    print('🔄 BudgetProvider: Reloading budget from Hive...');
    _loadBudget();
    print('✅ BudgetProvider: Budget reloaded: $_monthlyBudget');
  }

  // Set budget (optimized - only syncs settings, not all expenses)
  Future<void> setMonthlyBudget(double budget) async {
    _monthlyBudget = budget;
    await HiveService.setMonthlyBudget(budget);
    notifyListeners();

    // Only sync the budget setting, not all expenses (reduces writes significantly)
    try {
      await _firestoreService.syncSettings(budget, HiveService.getDarkMode());
      print('✅ Budget synced to Firestore: $budget');
    } catch (e) {
      print('⚠️ Failed to sync budget to Firestore: $e');
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
