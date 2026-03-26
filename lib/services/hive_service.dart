import 'package:hive_flutter/hive_flutter.dart';
import '../models/expense_model.dart';
import '../models/deposit_model.dart';

class HiveService {
  static const String expenseBoxName = 'expenses';
  static const String settingsBoxName = 'settings';
  static const String depositProfilesBoxName = 'deposit_profiles';
  static const String depositTransactionsBoxName = 'deposit_transactions';

  // Initialize Hive
  static Future<void> init() async {
    await Hive.initFlutter();

    // Register Adapters
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(ExpenseAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(DepositProfileAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(DepositTransactionAdapter());
    }

    // Open Boxes
    await Hive.openBox<Expense>(expenseBoxName);
    await Hive.openBox(settingsBoxName);
    await Hive.openBox<DepositProfile>(depositProfilesBoxName);
    await Hive.openBox<DepositTransaction>(depositTransactionsBoxName);
  }

  // Get Expense Box
  static Box<Expense> getExpenseBox() {
    return Hive.box<Expense>(expenseBoxName);
  }

  // Get Settings Box
  static Box getSettingsBox() {
    return Hive.box(settingsBoxName);
  }

  // Static getter for settings box
  static Box get settingsBox => getSettingsBox();

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

  // Settings - Current User ID (to track which user's data is stored)
  static Future<void> setCurrentUserId(String userId) async {
    final box = getSettingsBox();
    await box.put('currentUserId', userId);
  }

  static String? getCurrentUserId() {
    final box = getSettingsBox();
    return box.get('currentUserId') as String?;
  }

  static Future<void> clearCurrentUserId() async {
    final box = getSettingsBox();
    await box.delete('currentUserId');
  }

  // Clear all data
  static Future<void> clearAllData() async {
    final expenseBox = getExpenseBox();
    await expenseBox.clear();
  }

  // Clear all settings (including user ID)
  static Future<void> clearAllSettings() async {
    final settingsBox = getSettingsBox();
    await settingsBox.clear();
  }

  // ========== APP MODE METHODS ==========

  // Settings - App Mode (expense or deposit)
  static Future<void> setAppMode(String mode) async {
    final box = getSettingsBox();
    await box.put('appMode', mode);
  }

  static String getAppMode() {
    final box = getSettingsBox();
    return box.get('appMode', defaultValue: 'expense') as String;
  }

  // ========== DEPOSIT PROFILE METHODS ==========

  // Get Deposit Profiles Box
  static Box<DepositProfile> getDepositProfilesBox() {
    return Hive.box<DepositProfile>(depositProfilesBoxName);
  }

  // Get Deposit Transactions Box
  static Box<DepositTransaction> getDepositTransactionsBox() {
    return Hive.box<DepositTransaction>(depositTransactionsBoxName);
  }

  // Add Deposit Profile
  static Future<void> addDepositProfile(DepositProfile profile) async {
    final box = getDepositProfilesBox();
    await box.put(profile.id, profile);
  }

  // Update Deposit Profile
  static Future<void> updateDepositProfile(DepositProfile profile) async {
    final box = getDepositProfilesBox();
    await box.put(profile.id, profile);
  }

  // Delete Deposit Profile
  static Future<void> deleteDepositProfile(String id) async {
    final box = getDepositProfilesBox();
    await box.delete(id);

    // Also delete all transactions for this profile
    final transactionsBox = getDepositTransactionsBox();
    final transactionsToDelete = transactionsBox.values
        .where((t) => t.profileId == id)
        .map((t) => t.id)
        .toList();
    for (var transactionId in transactionsToDelete) {
      await transactionsBox.delete(transactionId);
    }
  }

  // Get All Deposit Profiles
  static List<DepositProfile> getAllDepositProfiles() {
    final box = getDepositProfilesBox();
    return box.values.toList();
  }

  // Get Deposit Profile by ID
  static DepositProfile? getDepositProfileById(String id) {
    final box = getDepositProfilesBox();
    return box.get(id);
  }

  // ========== DEPOSIT TRANSACTION METHODS ==========

  // Add Deposit Transaction
  static Future<void> addDepositTransaction(
      DepositTransaction transaction) async {
    final box = getDepositTransactionsBox();
    await box.put(transaction.id, transaction);
  }

  // Update Deposit Transaction
  static Future<void> updateDepositTransaction(
      DepositTransaction transaction) async {
    final box = getDepositTransactionsBox();
    await box.put(transaction.id, transaction);
  }

  // Delete Deposit Transaction
  static Future<void> deleteDepositTransaction(String id) async {
    final box = getDepositTransactionsBox();
    await box.delete(id);
  }

  // Get All Deposit Transactions
  static List<DepositTransaction> getAllDepositTransactions() {
    final box = getDepositTransactionsBox();
    return box.values.toList();
  }

  // Get Deposit Transactions for Profile
  static List<DepositTransaction> getDepositTransactionsForProfile(
      String profileId) {
    final box = getDepositTransactionsBox();
    return box.values.where((t) => t.profileId == profileId).toList();
  }

  // Get Deposit Transaction by ID
  static DepositTransaction? getDepositTransactionById(String id) {
    final box = getDepositTransactionsBox();
    return box.get(id);
  }

  // Clear all deposit data
  static Future<void> clearAllDepositData() async {
    final profilesBox = getDepositProfilesBox();
    final transactionsBox = getDepositTransactionsBox();
    await profilesBox.clear();
    await transactionsBox.clear();
  }
}
