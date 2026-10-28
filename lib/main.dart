import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'services/hive_service.dart';
import 'services/user_data_manager.dart';
import 'services/sync_queue_service.dart';
import 'services/background_sync_service.dart';
import 'services/app_check_service.dart';
import 'providers/expense_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/budget_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/language_provider.dart';
import 'providers/mode_provider.dart';
import 'providers/deposit_provider.dart';
import 'providers/account_provider.dart';
import 'models/account_model.dart';
import 'screens/access/access_status_page.dart';
import 'l10n/app_localizations.dart';
import 'theme/app_theme.dart';
import 'screens/dashboard_page.dart';
import 'screens/history_page.dart';
import 'screens/settings_page.dart';
import 'screens/login_page.dart';
import 'screens/statement_page.dart';
import 'screens/deposit/deposit_dashboard_page.dart';
import 'screens/deposit/deposit_history_page.dart';

void main() {
  // Release builds print nothing: the logs include user ids, emails and
  // amounts, and anyone with adb access to the phone could read them
  runZoned(
    _startApp,
    zoneSpecification: ZoneSpecification(
      print: (self, parent, zone, line) {
        if (!kReleaseMode) parent.print(zone, line);
      },
    ),
  );
}

Future<void> _startApp() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  // Only the genuine Play Store app may use Firestore (see app_check_service)
  await activateAppCheck();

  // Enable Firestore offline persistence and optimize cache settings
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  // Initialize Hive
  await HiveService.init();

  // Initialize User Data Manager for proper data isolation
  UserDataManager().initialize();

  // Start sync queue service for offline-safe Firestore writes
  SyncQueueService().start();

  // Initialize background sync (runs even when app is closed)
  await BackgroundSyncService().initialize();

  runApp(const ExpenseTrackerApp());
}

class ExpenseTrackerApp extends StatelessWidget {
  const ExpenseTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(
            create: (_) => LanguageProvider(HiveService.settingsBox)),
        ChangeNotifierProvider(create: (_) => BudgetProvider()),
        ChangeNotifierProvider(create: (_) => ExpenseProvider()),
        ChangeNotifierProvider(create: (_) => ModeProvider()),
        ChangeNotifierProvider(create: (_) => DepositProvider()),
        // Approval, blocking, maintenance and feature switches
        ChangeNotifierProvider(create: (_) => AccountProvider(), lazy: false),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              return Consumer<LanguageProvider>(
                builder: (context, languageProvider, child) {
                  final languageCode = languageProvider.languageCode;

                  return Consumer2<ModeProvider, AccountProvider>(
                    builder: (context, modeProvider, accountProvider, child) {
                      // Savings mode only while the admin allows it
                      final savingsMode = modeProvider.isDepositMode &&
                          accountProvider.isEnabled(AppFeature.savings);
                      final access = accountProvider.state;
                      return MaterialApp(
                        title: 'Expense Tracker',
                        debugShowCheckedModeBanner: false,
                        locale: languageProvider.locale,
                        supportedLocales: const [
                          Locale('en'),
                          Locale('bn'),
                        ],
                        localizationsDelegates: const [
                          AppLocalizationsDelegate(),
                          GlobalMaterialLocalizations.delegate,
                          GlobalWidgetsLocalizations.delegate,
                          GlobalCupertinoLocalizations.delegate,
                        ],
                        theme: AppTheme.light(languageCode),
                        darkTheme: AppTheme.dark(languageCode),
                        // Status bar icons that match the theme on every
                        // screen (app bars apply the same style)
                        // Pending, blocked or maintenance: the access screen
                        // replaces every route until the admin lets them in
                        builder: (context, child) =>
                            AnnotatedRegion<SystemUiOverlayStyle>(
                          value: AppTheme.overlayStyle(
                              Theme.of(context).brightness),
                          child: access == AccessState.signedOut ||
                                  access == AccessState.approved
                              ? child!
                              : AccessStatusPage(state: access),
                        ),
                        themeMode: themeProvider.isDarkMode
                            ? ThemeMode.dark
                            : ThemeMode.light,
                        initialRoute: '/',
                        routes: {
                          '/': (context) => authProvider.isAuthenticated
                              ? (savingsMode
                                  ? const DepositDashboardPage()
                                  : const DashboardPage())
                              : const LoginPage(),
                          '/history': (context) => savingsMode
                              ? const DepositHistoryPage()
                              : const HistoryPage(),
                          '/deposit-history': (context) =>
                              const DepositHistoryPage(),
                          '/settings': (context) => const SettingsPage(),
                          '/statement': (context) => const StatementPage(),
                        },
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
