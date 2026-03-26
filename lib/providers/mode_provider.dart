import 'package:flutter/foundation.dart';
import '../services/hive_service.dart';

enum AppMode { expense, deposit }

class ModeProvider with ChangeNotifier {
  AppMode _mode = AppMode.expense;

  AppMode get mode => _mode;
  bool get isExpenseMode => _mode == AppMode.expense;
  bool get isDepositMode => _mode == AppMode.deposit;

  ModeProvider() {
    _loadMode();
  }

  void _loadMode() {
    final savedMode = HiveService.getAppMode();
    _mode = savedMode == 'deposit' ? AppMode.deposit : AppMode.expense;
    notifyListeners();
  }

  void toggleMode() {
    _mode = _mode == AppMode.expense ? AppMode.deposit : AppMode.expense;
    _saveMode();
    notifyListeners();
  }

  void setMode(AppMode mode) {
    if (_mode != mode) {
      _mode = mode;
      _saveMode();
      notifyListeners();
    }
  }

  void _saveMode() {
    HiveService.setAppMode(_mode == AppMode.deposit ? 'deposit' : 'expense');
  }
}
