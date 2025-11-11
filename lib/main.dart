import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/hive_service.dart';
import 'providers/expense_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/budget_provider.dart';
import 'providers/auth_provider.dart';
import 'screens/dashboard_page.dart';
import 'screens/history_page.dart';
import 'screens/settings_page.dart';
import 'screens/login_page.dart';
import 'screens/statement_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  // Initialize Hive
  await HiveService.init();

  runApp(const ExpenseTrackerApp());
}

// Background restore handler that doesn't block the UI
class BackgroundRestoreHandler {
  static bool _hasTriedRestore = false;

  static Future<void> performAutoRestore(BuildContext context) async {
    if (_hasTriedRestore) return;
    _hasTriedRestore = true;

    // Add a small delay to let the dashboard render first
    await Future.delayed(const Duration(milliseconds: 500));

    if (!context.mounted) return;

    try {
      final expenseProvider =
          Provider.of<ExpenseProvider>(context, listen: false);

      // Check if there's any local data - if not, try to restore from Google Drive
      if (expenseProvider.expenses.isEmpty) {
        print(
            '📱 No local data found - attempting silent restore from Google Drive...');

        final success = await expenseProvider.restoreFromGoogleDrive();

        if (success && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.cloud_download, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Welcome back! Your data has been restored (${expenseProvider.expenses.length} items)',
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 4),
              behavior: SnackBarBehavior.floating,
              action: SnackBarAction(
                label: 'OK',
                textColor: Colors.white,
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                },
              ),
            ),
          );
        } else if (context.mounted) {
          print('ℹ️ No backup found or restore failed - starting fresh');
        }
      } else {
        print('📱 Local data exists - skipping automatic restore');
      }
    } catch (e) {
      print('❌ Error during background restore: $e');
      if (context.mounted) {
        // Show error notification but don't block the UI
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.cloud_off, color: Colors.white),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Could not check for backup data',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

class ExpenseTrackerApp extends StatelessWidget {
  const ExpenseTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => BudgetProvider()),
        ChangeNotifierProvider(create: (_) => ExpenseProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              return MaterialApp(
                title: 'Expense Tracker',
                debugShowCheckedModeBanner: false,
                theme: themeProvider.lightTheme.copyWith(
                  textTheme: themeProvider.lightTheme.textTheme.copyWith(
                    titleLarge: GoogleFonts.rubik80sFade(
                      textStyle: themeProvider.lightTheme.textTheme.titleLarge,
                    ),
                  ),
                  appBarTheme: themeProvider.lightTheme.appBarTheme.copyWith(
                    titleTextStyle: GoogleFonts.rubik80sFade(
                      textStyle:
                          themeProvider.lightTheme.appBarTheme.titleTextStyle ??
                              const TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                darkTheme: themeProvider.darkTheme.copyWith(
                  textTheme: themeProvider.darkTheme.textTheme.copyWith(
                    titleLarge: GoogleFonts.rubik80sFade(
                      textStyle: themeProvider.darkTheme.textTheme.titleLarge,
                    ),
                  ),
                  appBarTheme: themeProvider.darkTheme.appBarTheme.copyWith(
                    titleTextStyle: GoogleFonts.rubik80sFade(
                      textStyle:
                          themeProvider.darkTheme.appBarTheme.titleTextStyle ??
                              const TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                themeMode:
                    themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
                home: authProvider.isAuthenticated
                    ? const DashboardPage()
                    : const LoginPage(),
                routes: {
                  '/history': (context) => const HistoryPage(),
                  '/settings': (context) => const SettingsPage(),
                  '/statement': (context) => const StatementPage(),
                },
              );
            },
          );
        },
      ),
    );
  }
}
