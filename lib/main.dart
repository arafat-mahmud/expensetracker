import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'services/hive_service.dart';
import 'services/user_data_manager.dart';
import 'services/sync_queue_service.dart';
import 'services/background_sync_service.dart';
import 'providers/expense_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/budget_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/language_provider.dart';
import 'providers/mode_provider.dart';
import 'providers/deposit_provider.dart';
import 'l10n/app_localizations.dart';
import 'screens/dashboard_page.dart';
import 'screens/history_page.dart';
import 'screens/settings_page.dart';
import 'screens/login_page.dart';
import 'screens/statement_page.dart';
import 'screens/deposit/deposit_dashboard_page.dart';
import 'screens/deposit/deposit_history_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

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
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              return Consumer<LanguageProvider>(
                builder: (context, languageProvider, child) {
                  // Select font family based on language
                  final fontFamily = languageProvider.languageCode == 'bn'
                      ? 'NotoSansBengali'
                      : null;

                  return Consumer<ModeProvider>(
                    builder: (context, modeProvider, child) {
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
                        theme: themeProvider.lightTheme.copyWith(
                          textTheme: fontFamily != null
                              ? themeProvider.lightTheme.textTheme.apply(
                                  fontFamily: fontFamily,
                                )
                              : themeProvider.lightTheme.textTheme.copyWith(
                                  titleLarge: GoogleFonts.rubik80sFade(
                                    textStyle: themeProvider
                                        .lightTheme.textTheme.titleLarge,
                                  ),
                                ),
                          appBarTheme:
                              themeProvider.lightTheme.appBarTheme.copyWith(
                            titleTextStyle: fontFamily != null
                                ? TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: fontFamily,
                                    color: themeProvider.lightTheme.appBarTheme
                                            .titleTextStyle?.color ??
                                        Colors.black,
                                  )
                                : GoogleFonts.rubik80sFade(
                                    textStyle: themeProvider.lightTheme
                                            .appBarTheme.titleTextStyle ??
                                        const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold),
                                  ),
                          ),
                        ),
                        darkTheme: themeProvider.darkTheme.copyWith(
                          textTheme: fontFamily != null
                              ? themeProvider.darkTheme.textTheme.apply(
                                  fontFamily: fontFamily,
                                )
                              : themeProvider.darkTheme.textTheme.copyWith(
                                  titleLarge: GoogleFonts.rubik80sFade(
                                    textStyle: themeProvider
                                        .darkTheme.textTheme.titleLarge,
                                  ),
                                ),
                          appBarTheme:
                              themeProvider.darkTheme.appBarTheme.copyWith(
                            titleTextStyle: fontFamily != null
                                ? TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: fontFamily,
                                    color: themeProvider.darkTheme.appBarTheme
                                            .titleTextStyle?.color ??
                                        Colors.white,
                                  )
                                : GoogleFonts.rubik80sFade(
                                    textStyle: themeProvider.darkTheme
                                            .appBarTheme.titleTextStyle ??
                                        const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold),
                                  ),
                          ),
                        ),
                        themeMode: themeProvider.isDarkMode
                            ? ThemeMode.dark
                            : ThemeMode.light,
                        initialRoute: '/',
                        routes: {
                          '/': (context) => authProvider.isAuthenticated
                              ? (modeProvider.isDepositMode
                                  ? const DepositDashboardPage()
                                  : const DashboardPage())
                              : const LoginPage(),
                          '/history': (context) => modeProvider.isDepositMode
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
