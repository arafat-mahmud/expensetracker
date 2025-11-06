import 'package:hive_flutter/hive_flutter.dart';
import '../models/expense_model.dart';

class HiveService {
  static const String expenseBoxName = 'expenses';
  static const String settingsBoxName = 'settings';

  // Initialize Hive
  static Future<void> init() async {
    await Hive.initFlutter();

    // Register Adapters
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(ExpenseAdapter());
    }

    // Open Boxes
    await Hive.openBox<Expense>(expenseBoxName);
    await Hive.openBox(settingsBoxName);
  }

  // Get Expense Box
  static Box<Expense> getExpenseBox() {
    return Hive.box<Expense>(expenseBoxName);
  }

  // Get Settings Box
  static Box getSettingsBox() {
    return Hive.box(settingsBoxName);
  }

  // Add Expense
  static Future<void> addExpense(Expense expense) async {
    final box = getExpenseBox();
    await box.put(expense.id, expense);
  }

  // Update Expense
  static Future<void> updateExpense(Expense expense) async {
    final box = getExpenseBox();
    await box.put(expense.id, expense);
  }

  // Delete Expense
  static Future<void> deleteExpense(String id) async {
    final box = getExpenseBox();
    await box.delete(id);
  }

  // Get All Expenses
  static List<Expense> getAllExpenses() {
    final box = getExpenseBox();
    return box.values.toList();
  }

  // Get Expense by ID
  static Expense? getExpenseById(String id) {
    final box = getExpenseBox();
    return box.get(id);
  }

  // Settings - Monthly Budget
  static Future<void> setMonthlyBudget(double budget) async {
    final box = getSettingsBox();
    await box.put('monthlyBudget', budget);
  }

  static double getMonthlyBudget() {
    final box = getSettingsBox();
    return box.get('monthlyBudget', defaultValue: 10000.0) as double;
  }

  // Settings - Theme Mode
  static Future<void> setDarkMode(bool isDark) async {
    final box = getSettingsBox();
    await box.put('isDarkMode', isDark);
  }

  static bool getDarkMode() {
    final box = getSettingsBox();
    return box.get('isDarkMode', defaultValue: false) as bool;
  }

  // Clear all data
  static Future<void> clearAllData() async {
    final expenseBox = getExpenseBox();
    await expenseBox.clear();
  }
}
