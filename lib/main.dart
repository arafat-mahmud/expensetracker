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

// Wrapper to handle automatic restore after sign-in
class AutoRestoreWrapper extends StatefulWidget {
  final Widget child;

  const AutoRestoreWrapper({super.key, required this.child});

  @override
  State<AutoRestoreWrapper> createState() => _AutoRestoreWrapperState();
}

class _AutoRestoreWrapperState extends State<AutoRestoreWrapper> {
  bool _hasTriedRestore = false;
  bool _isRestoring = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _performAutoRestore();
    });
  }

  Future<void> _performAutoRestore() async {
    if (_hasTriedRestore || _isRestoring) return;

    setState(() {
      _isRestoring = true;
    });

    try {
      final expenseProvider =
          Provider.of<ExpenseProvider>(context, listen: false);

      // Check if there's any local data - if not, try to restore from Google Drive
      if (expenseProvider.expenses.isEmpty) {
        print(
            '📱 No local data found - attempting automatic restore from Google Drive...');

        final success = await expenseProvider.restoreFromGoogleDrive();

        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.cloud_download, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Data restored from Google Drive!'),
                ],
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else if (mounted) {
          print('ℹ️ No backup found or restore failed - starting fresh');
        }
      } else {
        print('📱 Local data exists - skipping automatic restore');
      }
    } catch (e) {
      print('❌ Error during automatic restore: $e');
    } finally {
      if (mounted) {
        setState(() {
          _hasTriedRestore = true;
          _isRestoring = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isRestoring) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Restoring your data...',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              const Text(
                'Please wait while we check for your backup',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return widget.child;
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
                    ? const AutoRestoreWrapper(child: DashboardPage())
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
