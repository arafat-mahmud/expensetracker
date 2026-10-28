import 'package:flutter/material.dart';

abstract class AppLocalizations {
  static AppLocalizations of(BuildContext context) {
    final locale = Localizations.localeOf(context);
    if (locale.languageCode == 'bn') {
      return BanglaLocalizations();
    }
    return EnglishLocalizations();
  }

  // Common
  String get appName;
  String get ok;
  String get cancel;
  String get save;
  String get delete;
  String get edit;
  String get back;
  String get search;
  String get loading;
  String get error;
  String get success;
  String get refresh;
  String get yes;
  String get no;

  // Navigation
  String get dashboard;
  String get history;
  String get settings;
  String get statement;

  // Dashboard
  String get totalBalance;
  String get totalIncome;
  String get totalExpense;
  String get addExpense;
  String get addIncome;
  String get categoryExpenses;
  String get dailyTrends;
  String get viewDetails;
  String get noDataAvailable;
  String get selectMonth;
  String get income;
  String get expense;

  // Budget
  String get monthlyBudget;
  String get setBudget;
  String get budgetRemaining;
  String get budgetExceeded;
  String get budgetWarning;

  // Categories
  String get food;
  String get transport;
  String get shopping;
  String get entertainment;
  String get health;
  String get education;
  String get bills;
  String get other;
  String get salary;
  String get freelance;
  String get investment;
  String get gift;
  String get category;

  // Add Expense
  String get addExpenseTitle;
  String get enterAmount;
  String get amount;
  String get selectCategory;
  String get selectDate;
  String get addNote;
  String get note;
  String get expenseAdded;
  String get enterValidAmount;

  // Add Income
  String get addIncomeTitle;
  String get incomeAdded;
  String get selectIncomeCategory;

  // History
  String get allTransactions;
  String get thisMonth;
  String get lastMonth;
  String get last3Months;
  String get last6Months;
  String get customRange;
  String get from;
  String get to;
  String get apply;
  String get noTransactions;
  String get transactions;
  String get filter;

  // Settings
  String get appearance;
  String get darkMode;
  String get language;
  String get selectLanguage;
  String get dataManagement;
  String get backup;
  String get restore;
  String get exportData;
  String get importData;
  String get backupToCloud;
  String get restoreFromCloud;
  String get lastBackup;
  String get never;
  String get account;
  String get signOut;
  String get signIn;
  String get about;
  String get version;
  String get developerInfo;
  String get clearData;
  String get clearAllData;
  String get confirmClearData;

  // Authentication
  String get welcomeBack;
  String get signInWithGoogle;
  String get signInToSync;
  String get signedInAs;
  String get signOutConfirm;

  // Login screen
  String get loginTagline;
  String get loginTitle;
  String get loginSubtitle;
  String get continueWithGoogle;
  String get signingIn;
  String get featureSyncTitle;
  String get featureSyncDesc;
  String get featureSecureTitle;
  String get featureSecureDesc;
  String get featureInsightsTitle;
  String get featureInsightsDesc;
  String get secureSignInNote;
  String get signInFailed;
  String get signInNetworkError;

  // Statement
  String get generateStatement;
  String get selectPeriod;
  String get statementGenerated;
  String get downloadStatement;
  String get shareStatement;
  String get startDate;
  String get endDate;
  String get generate;

  // PDF Statement
  String get personalFinanceManagement;
  String get accountStatement;
  String get statementPeriod;
  String get accountSummary;
  String get openingBalance;
  String get closingBalance;
  String get totalTransactions;
  String get transactionDetails;
  String get date;
  String get description;
  String get debit;
  String get credit;
  String get balance;
  String get runningBalance;
  String get statementFooter;
  String get thisStatementIsGenerated;
  String get pageOf;

  // Messages
  String get budgetUpdated;
  String get dataBackedUp;
  String get dataRestored;
  String get dataExported;
  String get dataImported;
  String get dataClearedSuccess;
  String get operationFailed;
  String get networkError;
  String get permissionDenied;
  String get fileSaved;

  // Validations
  String get requiredField;
  String get invalidAmount;
  String get selectValidDate;
  String get selectValidCategory;

  // Reports
  String get categoryReport;
  String get expensesByCategory;
  String get dailyExpenseTrend;
  String get weeklyAverage;
  String get monthlyTotal;
  String get highestExpense;
  String get lowestExpense;

  // Days
  String get monday;
  String get tuesday;
  String get wednesday;
  String get thursday;
  String get friday;
  String get saturday;
  String get sunday;

  // Months
  String get january;
  String get february;
  String get march;
  String get april;
  String get may;
  String get june;
  String get july;
  String get august;
  String get september;
  String get october;
  String get november;
  String get december;

  // Additional UI Strings
  String get all;
  String get expenses;
  String get view;
  String get spent;
  String get remaining;
  String get overBudget;
  String get noExpensesThisMonth;
  String get noExpensesLast7Days;
  String get noExpensesInAnyCategory;
  String get noExpensesFound;
  String get titleOptional;
  String get titleHint;
  String get incomeTitleHint;
  String get incomeCategory;
  String get pleaseEnterAmount;
  String get pleaseEnterValidAmount;
  String get noteOptional;
  String get noteHint;
  String get updateExpense;
  String get saveExpense;
  String get updateIncome;
  String get saveIncome;
  String get expenseUpdated;
  String get incomeUpdated;
  String get quickSelectPeriod;
  String get last30Days;
  String get thisYear;
  String get customDateRange;
  String get totalCredits;
  String get totalDebits;
  String get surplus;
  String get deficit;
  String get noTransactionsFound;
  String get noTransactionsMessage;
  String get downloadPdfStatement;

  // Category Dialog Strings
  String get categoriesAvailable;
  String get chooseDifferentGroup;

  // Category Group Names
  String get basicHouseholdExpenses;
  String get dailyLiving;
  String get transportation; // Group name
  String get healthWellness;
  String get workBusiness;
  String get financialObligations;
  String get specialOccasions;
  String get miscellaneous;

  // Income Categories
  String get business;

  // Expense Categories - Basic Household
  String get electricity;
  String get water;
  String get internet;
  String get gas;
  String get rentHouse;
  String get maintenanceRepair;

  // Daily Living
  String get foodRestaurant;
  String get grocery;
  String get vegetable;
  String get snacks;
  String get laundryCleaning;

  // Health & Wellness
  String get medicine;
  String get doctorHospital;
  String get fitnessGym;

  // Education Section
  String get tuitionFees;
  String get stationery;
  String get onlineCourses;

  // Work & Business
  String get officeSupplies;
  String get businessTravel;
  String get clientEntertainment;

  // Entertainment & Lifestyle
  String get moviesOTT;
  String get games;
  String get travelVacation;

  // Financial
  String get loanEMI;
  String get creditCardPayment;
  String get savingsInvestment;
  String get insurance;
  String get incomeTax;

  // Personal / Family
  String get gifts;
  String get charity;
  String get petCare;
  String get childExpenses;

  // ========== DEPOSIT/SAVINGS FEATURE ==========
  // Mode
  String get appMode;
  String get expenseMode;
  String get depositMode;
  String get switchToDepositMode;
  String get switchToExpenseMode;

  // Deposit Feature
  String get depositProfiles;
  String get createProfile;
  String get editProfile;
  String get profileName;
  String get targetAmount;
  String get deadline;
  String get currentBalance;
  String get remainingAmount;
  String get daysRemaining;
  String get addDeposit;
  String get withdraw;
  String get depositAmount;
  String get withdrawAmount;
  String get profileCompleted;
  String get goalReached;
  String get onTrack;
  String get behind;
  String get noProfiles;
  String get createFirstProfile;
  String get profileCreated;
  String get profileUpdated;
  String get saveProfile;
  String get updateProfile;
  String get pleaseEnterName;
  String get depositAdded;
  String get withdrawCompleted;
  String get confirmWithdraw;
  String get availableBalance;
  String get insufficientBalance;
  String get depositHistory;
  String get allProfiles;
  String get noMatchingTransactions;
  String get startByAddingDeposit;

  // Helper method to get translated category name
  String getCategoryName(String category);

  // Admin panel and account access
  String get adminPanel;
  String get adminPanelSubtitle;
  String get administration;
  String get usersTab;
  String get appControlsTab;
  String get statusPending;
  String get statusApproved;
  String get statusBlocked;
  String get approve;
  String get approveAll;
  String get approveAllTitle;
  String get block;
  String get unblock;
  String get moveToPending;
  String get blockUserTitle;
  String get blockUserMessage;
  String get blockReasonHint;
  String get userApproved;
  String get userBlocked;
  String get userMovedToPending;
  String get searchByEmail;
  String get userNotFound;
  String get noUsersHere;
  String get loadMore;
  String get joined;
  String get features;
  String get featureSavings;
  String get featureSavingsDesc;
  String get featureStatement;
  String get featureStatementDesc;
  String get featureCloudSync;
  String get featureCloudSyncDesc;
  String get followAppSetting;
  String get onLabel;
  String get offLabel;
  String get userFeaturesHint;
  String get maintenanceMode;
  String get maintenanceModeDesc;
  String get maintenanceOnTitle;
  String get maintenanceMessageLabel;
  String get maintenanceIsOn;
  String get newUsers;
  String get requireApproval;
  String get requireApprovalDesc;
  String get featuresForEveryone;
  String get settingSaved;
  String get savedWhenOnline;
  String get checkingAccount;
  String get pendingTitle;
  String get pendingMessage;
  String get blockedTitle;
  String get blockedMessage;
  String get reasonLabel;
  String get maintenanceTitle;
  String get maintenanceDefaultMessage;
  String get contactSupport;
  String get featureDisabled;
  String get cloudSyncPaused;

  // Design refresh
  String get goodMorning;
  String get goodAfternoon;
  String get goodEvening;
  String get overview;
  String get monthBalance;
  String get recentTransactions;
  String get seeAll;
  String get today;
  String get yesterday;
  String get usedLabel;
  String get total;
  String get average;
  String get highestDay;
  String get searchTransactions;
  String get deleteTransactionTitle;
  String get deleteCannotUndo;
  String get transactionDeleted;
  String get deleteProfileTitle;
  String get deleteProfileMessage;
  String get activeGoals;
  String get completedGoals;
  String get totalSavings;
  String get saved;
  String get withdrawn;
  String get completedLabel;
  String get depositLabel;
  String get withdrawalLabel;
  String get downloadPdf;
  String get sharePdf;
  String get noExpensesInPeriod;
  String get general;
  String get dangerZone;
  String get developerInfoSubtitle;
  String get clearAllDataSubtitle;
  String get statementFormatNote;
  String get profileNameHint;
  String get congratulations;
  String get awesome;
  String get aboutDeveloper;
  String get softwareDeveloper;
  String get appDescription;
  String get contact;
  String get emailLabel;
  String get websiteLabel;
  String get permanentDeletion;
  String get deletionWillTitle;
  String get deletionPointDevice;
  String get deletionPointCloud;
  String get deletionPointRecovery;
  String get typeToConfirm;
  String get confirmTextVerified;
  String get continueLabel;
  String get finalWarning;
  String get finalWarningMessage;
  String get keepMyData;
  String get deletePermanently;
  String get preparingDeletion;
  String get deletingData;
  String get deletionComplete;
  String get allDataDeleted;
  String get cloudDeletionPending;
  String daysLeft(int days);
  String daysOverdue(int days);
  String transactionCount(int count);
  String lastNDays(int days);
  String startingIn(int seconds);
  String secondsElapsed(int seconds);
  String amountSaved(String amount);
  String userCount(int count);
}

class EnglishLocalizations extends AppLocalizations {
  @override
  String get appName => 'Expense Tracker';
  @override
  String get ok => 'OK';
  @override
  String get cancel => 'Cancel';
  @override
  String get save => 'Save';
  @override
  String get delete => 'Delete';
  @override
  String get edit => 'Edit';
  @override
  String get back => 'Back';
  @override
  String get search => 'Search';
  @override
  String get loading => 'Loading...';
  @override
  String get error => 'Error';
  @override
  String get success => 'Success';
  @override
  String get refresh => 'Refresh';
  @override
  String get yes => 'Yes';
  @override
  String get no => 'No';

  @override
  String get dashboard => 'Dashboard';
  @override
  String get history => 'History';
  @override
  String get settings => 'Settings';
  @override
  String get statement => 'Statement';

  @override
  String get totalBalance => 'Total Balance';
  @override
  String get totalIncome => 'Total Income';
  @override
  String get totalExpense => 'Total Expense';
  @override
  String get addExpense => 'Add Expense';
  @override
  String get addIncome => 'Add Income';
  @override
  String get categoryExpenses => 'Category Expenses';
  @override
  String get dailyTrends => 'Daily Trends';
  @override
  String get viewDetails => 'View Details';
  @override
  String get noDataAvailable => 'No data available';
  @override
  String get selectMonth => 'Select Month';
  @override
  String get income => 'Income';
  @override
  String get expense => 'Expense';

  @override
  String get monthlyBudget => 'Monthly Budget';
  @override
  String get setBudget => 'Set Budget';
  @override
  String get budgetRemaining => 'Budget Remaining';
  @override
  String get budgetExceeded => 'Budget Exceeded';
  @override
  String get budgetWarning => 'Budget Warning';

  @override
  String get food => 'Food';
  @override
  String get transport => 'Transport';
  @override
  String get shopping => 'Shopping';
  @override
  String get entertainment => 'Entertainment';
  @override
  String get health => 'Health';
  @override
  String get education => 'Education';
  @override
  String get bills => 'Bills';
  @override
  String get other => 'Other';
  @override
  String get salary => 'Salary';
  @override
  String get freelance => 'Freelance';
  @override
  String get investment => 'Investment';
  @override
  String get gift => 'Gift';
  @override
  String get category => 'Category';

  @override
  String get addExpenseTitle => 'Add Expense';
  @override
  String get enterAmount => 'Enter Amount';
  @override
  String get amount => 'Amount';
  @override
  String get selectCategory => 'Select Category';
  @override
  String get selectDate => 'Select Date';
  @override
  String get addNote => 'Add Note';
  @override
  String get note => 'Note';
  @override
  String get expenseAdded => 'Expense added successfully';
  @override
  String get enterValidAmount => 'Enter valid amount';

  @override
  String get addIncomeTitle => 'Add Income';
  @override
  String get incomeAdded => 'Income added successfully';
  @override
  String get selectIncomeCategory => 'Select Income Category';

  @override
  String get allTransactions => 'All Transactions';
  @override
  String get thisMonth => 'This Month';
  @override
  String get lastMonth => 'Last Month';
  @override
  String get last3Months => 'Last 3 Months';
  @override
  String get last6Months => 'Last 6 Months';
  @override
  String get customRange => 'Custom Range';
  @override
  String get from => 'From';
  @override
  String get to => 'To';
  @override
  String get apply => 'Apply';
  @override
  String get noTransactions => 'No transactions found';
  @override
  String get transactions => 'Transactions';
  @override
  String get filter => 'Filter';

  @override
  String get appearance => 'Appearance';
  @override
  String get darkMode => 'Dark Mode';
  @override
  String get language => 'Language';
  @override
  String get selectLanguage => 'Select Language';
  @override
  String get dataManagement => 'Data Management';
  @override
  String get backup => 'Backup';
  @override
  String get restore => 'Restore';
  @override
  String get exportData => 'Export Data';
  @override
  String get importData => 'Import Data';
  @override
  String get backupToCloud => 'Backup to Cloud';
  @override
  String get restoreFromCloud => 'Restore from Cloud';
  @override
  String get lastBackup => 'Last Backup';
  @override
  String get never => 'Never';
  @override
  String get account => 'Account';
  @override
  String get signOut => 'Sign Out';
  @override
  String get signIn => 'Sign In';
  @override
  String get about => 'About';
  @override
  String get version => 'Version';
  @override
  String get developerInfo => 'Developer Info';
  @override
  String get clearData => 'Clear Data';
  @override
  String get clearAllData => 'Clear All Data';
  @override
  String get confirmClearData =>
      'Are you sure you want to clear all data? This action cannot be undone.';

  @override
  String get welcomeBack => 'Welcome Back';
  @override
  String get signInWithGoogle => 'Sign in with Google';
  @override
  String get signInToSync => 'Sign in to sync your data across devices';
  @override
  String get signedInAs => 'Signed in as';
  @override
  String get signOutConfirm => 'Are you sure you want to sign out?';

  // Login screen
  @override
  String get loginTagline => 'Smart money management, on every device';
  @override
  String get loginTitle => 'Welcome';
  @override
  String get loginSubtitle =>
      'Sign in to keep your finances safe and in sync across all your devices.';
  @override
  String get continueWithGoogle => 'Continue with Google';
  @override
  String get signingIn => 'Signing in…';
  @override
  String get featureSyncTitle => 'Real-time sync';
  @override
  String get featureSyncDesc => 'Changes appear on all your devices instantly';
  @override
  String get featureSecureTitle => 'Private & secure';
  @override
  String get featureSecureDesc => 'Only you can see your data';
  @override
  String get featureInsightsTitle => 'Smart insights';
  @override
  String get featureInsightsDesc => 'Charts, budgets and PDF statements';
  @override
  String get secureSignInNote =>
      'Secured by Google. We never see your password.';
  @override
  String get signInFailed => 'Sign-in failed. Please try again.';
  @override
  String get signInNetworkError =>
      'No internet connection. Check your network and try again.';

  @override
  String get generateStatement => 'Generate Statement';
  @override
  String get selectPeriod => 'Select Period';
  @override
  String get statementGenerated => 'Statement generated successfully';
  @override
  String get downloadStatement => 'Download Statement';
  @override
  String get shareStatement => 'Share Statement';
  @override
  String get startDate => 'Start Date';
  @override
  String get endDate => 'End Date';
  @override
  String get generate => 'Generate';

  @override
  String get personalFinanceManagement => 'Personal Finance Management';
  @override
  String get accountStatement => 'ACCOUNT STATEMENT';
  @override
  String get statementPeriod => 'Statement Period';
  @override
  String get accountSummary => 'ACCOUNT SUMMARY';
  @override
  String get openingBalance => 'Opening Balance';
  @override
  String get closingBalance => 'Closing Balance';
  @override
  String get totalTransactions => 'Total Transactions';
  @override
  String get transactionDetails => 'TRANSACTION DETAILS';
  @override
  String get date => 'Date';
  @override
  String get description => 'Description';
  @override
  String get debit => 'Debit';
  @override
  String get credit => 'Credit';
  @override
  String get balance => 'Balance';
  @override
  String get runningBalance => 'Running Balance';
  @override
  String get statementFooter =>
      'This is a computer generated statement and does not require signature';
  @override
  String get thisStatementIsGenerated =>
      'This statement is generated automatically';
  @override
  String get pageOf => 'Page';

  @override
  String get budgetUpdated => 'Budget updated successfully';
  @override
  String get dataBackedUp => 'Data backed up successfully';
  @override
  String get dataRestored => 'Data restored successfully';
  @override
  String get dataExported => 'Data exported successfully';
  @override
  String get dataImported => 'Data imported successfully';
  @override
  String get dataClearedSuccess => 'All data cleared successfully';
  @override
  String get operationFailed => 'Operation failed';
  @override
  String get networkError => 'Network error occurred';
  @override
  String get permissionDenied => 'Permission denied';
  @override
  String get fileSaved => 'File saved successfully';

  @override
  String get requiredField => 'This field is required';
  @override
  String get invalidAmount => 'Invalid amount';
  @override
  String get selectValidDate => 'Select valid date';
  @override
  String get selectValidCategory => 'Select valid category';

  @override
  String get categoryReport => 'Category Report';
  @override
  String get expensesByCategory => 'Expenses by Category';
  @override
  String get dailyExpenseTrend => 'Daily Expense Trend';
  @override
  String get weeklyAverage => 'Weekly Average';
  @override
  String get monthlyTotal => 'Monthly Total';
  @override
  String get highestExpense => 'Highest Expense';
  @override
  String get lowestExpense => 'Lowest Expense';

  @override
  String get monday => 'Monday';
  @override
  String get tuesday => 'Tuesday';
  @override
  String get wednesday => 'Wednesday';
  @override
  String get thursday => 'Thursday';
  @override
  String get friday => 'Friday';
  @override
  String get saturday => 'Saturday';
  @override
  String get sunday => 'Sunday';

  @override
  String get january => 'January';
  @override
  String get february => 'February';
  @override
  String get march => 'March';
  @override
  String get april => 'April';
  @override
  String get may => 'May';
  @override
  String get june => 'June';
  @override
  String get july => 'July';
  @override
  String get august => 'August';
  @override
  String get september => 'September';
  @override
  String get october => 'October';
  @override
  String get november => 'November';
  @override
  String get december => 'December';

  // Additional UI Strings
  @override
  String get all => 'All';
  @override
  String get expenses => 'Expenses';
  @override
  String get view => 'View';
  @override
  String get spent => 'Spent';
  @override
  String get remaining => 'Remaining';
  @override
  String get overBudget => 'Over Budget';
  @override
  String get noExpensesThisMonth => 'No expenses this month';
  @override
  String get noExpensesLast7Days => 'No expenses in the last 7 days';
  @override
  String get noExpensesInAnyCategory => 'No expenses in any category';
  @override
  String get noExpensesFound => 'No expenses found';
  @override
  String get titleOptional => 'Title (Optional)';
  @override
  String get titleHint => 'e.g., Electricity Bill';
  @override
  String get incomeTitleHint => 'e.g., Monthly Salary';
  @override
  String get incomeCategory => 'Income Category';
  @override
  String get pleaseEnterAmount => 'Please enter an amount';
  @override
  String get pleaseEnterValidAmount => 'Please enter a valid amount';
  @override
  String get noteOptional => 'Note (Optional)';
  @override
  String get noteHint => 'Add any additional notes';
  @override
  String get updateExpense => 'Update Expense';
  @override
  String get saveExpense => 'Save Expense';
  @override
  String get updateIncome => 'Update Income';
  @override
  String get saveIncome => 'Save Income';
  @override
  String get expenseUpdated => 'Expense updated!';
  @override
  String get incomeUpdated => 'Income updated!';
  @override
  String get quickSelectPeriod => 'Quick select';
  @override
  String get last30Days => 'Last 30 Days';
  @override
  String get thisYear => 'This Year';
  @override
  String get customDateRange => 'Custom date range';
  @override
  String get totalCredits => 'Total Credits (+)';
  @override
  String get totalDebits => 'Total Debits (-)';
  @override
  String get surplus => 'Surplus';
  @override
  String get deficit => 'Deficit';
  @override
  String get noTransactionsFound => 'No Transactions Found';
  @override
  String get noTransactionsMessage =>
      'No transactions found for the selected period.\\nPlease adjust your date range.';
  @override
  String get downloadPdfStatement => 'Download PDF statement';

  // Category Dialog Strings (selectIncomeCategory and selectCategory already exist above)
  @override
  String get categoriesAvailable => 'categories available';

  @override
  String get chooseDifferentGroup => 'Choose Different Group';

  // Category Group Names
  @override
  String get basicHouseholdExpenses => 'Basic Household Expenses';
  @override
  String get dailyLiving => 'Daily Living';
  @override
  String get transportation => 'Transportation';
  @override
  String get healthWellness => 'Health & Wellness';
  @override
  String get workBusiness => 'Work & Business';
  @override
  String get financialObligations => 'Financial Obligations';
  @override
  String get specialOccasions => 'Special Occasions';
  @override
  String get miscellaneous => 'Miscellaneous';

  // Income Categories (only new ones, salary/freelance/investment/gift already exist above)
  @override
  String get business => 'Business';

  // Expense Categories - Basic Household
  @override
  String get electricity => 'Electricity';
  @override
  String get water => 'Water';
  @override
  String get internet => 'Internet';
  @override
  String get gas => 'Gas';
  @override
  String get rentHouse => 'Rent / House';
  @override
  String get maintenanceRepair => 'Maintenance / Repair';

  // Daily Living
  @override
  String get foodRestaurant => 'Food / Restaurant';
  @override
  String get grocery => 'Grocery';
  @override
  String get vegetable => 'Vegetable';
  @override
  String get snacks => 'Snacks';
  @override
  String get laundryCleaning => 'Laundry / Cleaning';

  // Transportation (specific categories, transport category already exists above)
  String get fuel => 'Fuel';
  String get publicTransport => 'Public Transport';
  String get parking => 'Parking';
  String get vehicleMaintenance => 'Vehicle Maintenance';

  // Health & Wellness
  @override
  String get medicine => 'Medicine';
  @override
  String get doctorHospital => 'Doctor / Hospital';
  @override
  String get fitnessGym => 'Fitness / Gym';

  // Education
  @override
  String get tuitionFees => 'Tuition Fees';
  @override
  String get stationery => 'Stationery';
  @override
  String get onlineCourses => 'Online Courses';

  // Work & Business
  @override
  String get officeSupplies => 'Office Supplies';
  @override
  String get businessTravel => 'Business Travel';
  @override
  String get clientEntertainment => 'Client Entertainment';

  // Entertainment & Lifestyle (shopping already exists above)
  @override
  String get moviesOTT => 'Movies / OTT';
  @override
  String get games => 'Games';
  @override
  String get travelVacation => 'Travel / Vacation';

  // Financial
  @override
  String get loanEMI => 'Loan / EMI';
  @override
  String get creditCardPayment => 'Credit Card Payment';
  @override
  String get savingsInvestment => 'Savings / Investment';
  @override
  String get insurance => 'Insurance';
  @override
  String get incomeTax => 'Income Tax';

  // Personal / Family
  @override
  String get gifts => 'Gifts';
  @override
  String get charity => 'Charity';
  @override
  String get petCare => 'Pet Care';
  @override
  String get childExpenses => 'Child Expenses';

  // ========== DEPOSIT/SAVINGS FEATURE ==========
  @override
  String get appMode => 'App Mode';
  @override
  String get expenseMode => 'Expense Mode';
  @override
  String get depositMode => 'Savings Mode';
  @override
  String get switchToDepositMode => 'Switch to Savings Mode';
  @override
  String get switchToExpenseMode => 'Switch to Expense Mode';
  @override
  String get depositProfiles => 'Savings Goals';
  @override
  String get createProfile => 'Create Goal';
  @override
  String get editProfile => 'Edit Goal';
  @override
  String get profileName => 'Goal Name';
  @override
  String get targetAmount => 'Target Amount';
  @override
  String get deadline => 'Deadline';
  @override
  String get currentBalance => 'Current Balance';
  @override
  String get remainingAmount => 'Remaining';
  @override
  String get daysRemaining => 'Days Left';
  @override
  String get addDeposit => 'Add Savings';
  @override
  String get withdraw => 'Withdraw';
  @override
  String get depositAmount => 'Savings Amount';
  @override
  String get withdrawAmount => 'Withdraw Amount';
  @override
  String get profileCompleted => 'Goal Completed';
  @override
  String get goalReached => 'Goal Reached!';
  @override
  String get onTrack => 'On Track';
  @override
  String get behind => 'Behind Schedule';
  @override
  String get noProfiles => 'No Savings Goals';
  @override
  String get createFirstProfile =>
      'Create your first savings goal to start tracking!';
  @override
  String get profileCreated => 'Goal created successfully!';
  @override
  String get profileUpdated => 'Goal updated successfully!';
  @override
  String get saveProfile => 'Save Goal';
  @override
  String get updateProfile => 'Update Goal';
  @override
  String get pleaseEnterName => 'Please enter a name';
  @override
  String get depositAdded => 'Savings added successfully!';
  @override
  String get withdrawCompleted => 'Withdrawal completed!';
  @override
  String get confirmWithdraw => 'Confirm Withdraw';
  @override
  String get availableBalance => 'Available Balance';
  @override
  String get insufficientBalance => 'Insufficient balance';
  @override
  String get depositHistory => 'Savings History';
  @override
  String get allProfiles => 'All Goals';
  @override
  String get noMatchingTransactions => 'No matching transactions found';
  @override
  String get startByAddingDeposit =>
      'Start by adding savings to your goal';

  // Design refresh
  @override
  String get goodMorning => 'Good morning';
  @override
  String get goodAfternoon => 'Good afternoon';
  @override
  String get goodEvening => 'Good evening';
  @override
  String get overview => 'Overview';
  @override
  String get monthBalance => 'Balance this month';
  @override
  String get recentTransactions => 'Recent transactions';
  @override
  String get seeAll => 'See all';
  @override
  String get today => 'Today';
  @override
  String get yesterday => 'Yesterday';
  @override
  String get usedLabel => 'used';
  @override
  String get total => 'Total';
  @override
  String get average => 'Average';
  @override
  String get highestDay => 'Highest day';
  @override
  String get searchTransactions => 'Search transactions';
  @override
  String get deleteTransactionTitle => 'Delete transaction?';
  @override
  String get deleteCannotUndo => 'This cannot be undone.';
  @override
  String get transactionDeleted => 'Transaction deleted';
  @override
  String get deleteProfileTitle => 'Delete goal?';
  @override
  String get deleteProfileMessage => 'All deposits and withdrawals of this goal will be deleted too.';
  @override
  String get activeGoals => 'Active goals';
  @override
  String get completedGoals => 'Completed goals';
  @override
  String get totalSavings => 'Total savings';
  @override
  String get saved => 'Saved';
  @override
  String get withdrawn => 'Withdrawn';
  @override
  String get completedLabel => 'Completed';
  @override
  String get depositLabel => 'Deposit';
  @override
  String get withdrawalLabel => 'Withdrawal';
  @override
  String get downloadPdf => 'Download PDF';
  @override
  String get sharePdf => 'Share PDF';
  @override
  String get noExpensesInPeriod => 'No expenses in this period';
  @override
  String get general => 'General';
  @override
  String get dangerZone => 'Danger zone';
  @override
  String get developerInfoSubtitle => 'About the developer and contact';
  @override
  String get clearAllDataSubtitle => 'Permanently delete all expenses';
  @override
  String get statementFormatNote => 'Your statement is created as a bank-style PDF with a running balance for every transaction.';
  @override
  String get profileNameHint => 'e.g. Emergency fund';
  @override
  String get congratulations => 'Congratulations!';
  @override
  String get awesome => 'Awesome!';
  @override
  String get aboutDeveloper => 'About the developer';
  @override
  String get softwareDeveloper => 'Software Developer';
  @override
  String get appDescription => 'A personal finance app for tracking expenses and income, managing budgets and savings goals, with clear charts and PDF statements.';
  @override
  String get contact => 'Contact';
  @override
  String get emailLabel => 'Email';
  @override
  String get websiteLabel => 'Website';
  @override
  String get permanentDeletion => 'Delete all data permanently';
  @override
  String get deletionWillTitle => 'This will:';
  @override
  String get deletionPointDevice => 'Delete all expenses from this device';
  @override
  String get deletionPointCloud => 'Delete all your expenses from the cloud';
  @override
  String get deletionPointRecovery => 'Make recovery impossible';
  @override
  String get typeToConfirm => 'Type DELETE ALL DATA to confirm';
  @override
  String get confirmTextVerified => 'Confirmation verified';
  @override
  String get continueLabel => 'Continue';
  @override
  String get finalWarning => 'Final warning';
  @override
  String get finalWarningMessage => 'All your expense data will be deleted permanently and cannot be recovered. Are you absolutely sure?';
  @override
  String get keepMyData => 'Keep my data';
  @override
  String get deletePermanently => 'Delete permanently';
  @override
  String get preparingDeletion => 'Preparing to delete…';
  @override
  String get deletingData => 'Deleting all data…';
  @override
  String get deletionComplete => 'Deletion complete';
  @override
  String get allDataDeleted => 'All data has been permanently deleted.';
  @override
  String get cloudDeletionPending => 'Deleted on this device. The cloud copy will finish deleting once you\'re online.';
  @override
  String daysLeft(int days) => '$days days left';
  @override
  String daysOverdue(int days) => '$days days overdue';
  @override
  String transactionCount(int count) => count == 1 ? '1 transaction' : '$count transactions';
  @override
  String lastNDays(int days) => 'Last $days days';
  @override
  String startingIn(int seconds) => 'Starting in ${seconds}s';
  @override
  String secondsElapsed(int seconds) => '${seconds}s elapsed';
  @override
  String amountSaved(String amount) => '$amount saved';
  @override
  String userCount(int count) => count == 1 ? '1 user' : '$count users';

  // Admin panel and account access
  @override
  String get adminPanel => 'Admin panel';
  @override
  String get adminPanelSubtitle => 'Approve users, maintenance and features';
  @override
  String get administration => 'Administration';
  @override
  String get usersTab => 'Users';
  @override
  String get appControlsTab => 'App controls';
  @override
  String get statusPending => 'Pending';
  @override
  String get statusApproved => 'Approved';
  @override
  String get statusBlocked => 'Blocked';
  @override
  String get approve => 'Approve';
  @override
  String get approveAll => 'Approve all';
  @override
  String get approveAllTitle => 'Approve all pending users on this list?';
  @override
  String get block => 'Block';
  @override
  String get unblock => 'Unblock';
  @override
  String get moveToPending => 'Move to pending';
  @override
  String get blockUserTitle => 'Block this user?';
  @override
  String get blockUserMessage => 'They won\'t be able to use the app until you unblock them.';
  @override
  String get blockReasonHint => 'Reason (optional, shown to the user)';
  @override
  String get userApproved => 'User approved';
  @override
  String get userBlocked => 'User blocked';
  @override
  String get userMovedToPending => 'Moved to pending';
  @override
  String get searchByEmail => 'Find a user by email';
  @override
  String get userNotFound => 'No user with this email';
  @override
  String get noUsersHere => 'No users here';
  @override
  String get loadMore => 'Load more';
  @override
  String get joined => 'Joined';
  @override
  String get features => 'Features';
  @override
  String get featureSavings => 'Savings goals';
  @override
  String get featureSavingsDesc => 'Savings mode with goals, deposits and withdrawals';
  @override
  String get featureStatement => 'PDF statements';
  @override
  String get featureStatementDesc => 'Download account statements as PDF';
  @override
  String get featureCloudSync => 'Cloud sync';
  @override
  String get featureCloudSyncDesc => 'Sync data across devices. When off, data stays on the device and syncs later.';
  @override
  String get followAppSetting => 'Default';
  @override
  String get onLabel => 'On';
  @override
  String get offLabel => 'Off';
  @override
  String get userFeaturesHint => 'Only for this user. Default follows the setting for everyone.';
  @override
  String get maintenanceMode => 'Maintenance mode';
  @override
  String get maintenanceModeDesc => 'Everyone except admins sees a maintenance screen';
  @override
  String get maintenanceOnTitle => 'Turn on maintenance mode?';
  @override
  String get maintenanceMessageLabel => 'Message for users';
  @override
  String get maintenanceIsOn => 'Maintenance mode is on — users can\'t use the app right now.';
  @override
  String get newUsers => 'New users';
  @override
  String get requireApproval => 'Require approval';
  @override
  String get requireApprovalDesc => 'New users wait for your approval. When off, they are approved automatically.';
  @override
  String get featuresForEveryone => 'Features for everyone';
  @override
  String get settingSaved => 'Saved';
  @override
  String get savedWhenOnline => 'Saved. It applies once you\'re online.';
  @override
  String get checkingAccount => 'Checking your account…';
  @override
  String get pendingTitle => 'Waiting for approval';
  @override
  String get pendingMessage => 'Your account is registered. An administrator will review it soon — this screen updates by itself once you\'re approved.';
  @override
  String get blockedTitle => 'Account blocked';
  @override
  String get blockedMessage => 'Your account has been blocked by the administrator.';
  @override
  String get reasonLabel => 'Reason';
  @override
  String get maintenanceTitle => 'Under maintenance';
  @override
  String get maintenanceDefaultMessage => 'We\'re improving the app. Please check back soon.';
  @override
  String get contactSupport => 'Contact support';
  @override
  String get featureDisabled => 'This feature is turned off by the administrator.';
  @override
  String get cloudSyncPaused => 'Cloud sync is paused by the administrator. Your data is safe on this device and will sync later.';

  @override
  String getCategoryName(String category) {
    // Income categories
    if (category == 'Salary') return salary;
    if (category == 'Business') return business;
    if (category == 'Freelance') return freelance;
    if (category == 'Investment') return investment;
    if (category == 'Gift') return gift;

    // Basic Household
    if (category == 'Electricity') return electricity;
    if (category == 'Water') return water;
    if (category == 'Internet') return internet;
    if (category == 'Gas') return gas;
    if (category == 'Rent / House') return rentHouse;
    if (category == 'Maintenance / Repair') return maintenanceRepair;

    // Daily Living
    if (category == 'Food / Restaurant') return foodRestaurant;
    if (category == 'Grocery') return grocery;
    if (category == 'Vegetable') return vegetable;
    if (category == 'Snacks') return snacks;
    if (category == 'Laundry / Cleaning') return laundryCleaning;

    // Transportation
    if (category == 'Fuel') return fuel;
    if (category == 'Public Transport') return publicTransport;
    if (category == 'Parking') return parking;
    if (category == 'Vehicle Maintenance') return vehicleMaintenance;
    if (category == 'Transport') return transport;

    // Health
    if (category == 'Medicine') return medicine;
    if (category == 'Doctor / Hospital') return doctorHospital;
    if (category == 'Fitness / Gym') return fitnessGym;

    // Education
    if (category == 'Tuition Fees') return tuitionFees;
    if (category == 'Stationery') return stationery;
    if (category == 'Online Courses') return onlineCourses;

    // Work & Business
    if (category == 'Office Supplies') return officeSupplies;
    if (category == 'Business Travel') return businessTravel;
    if (category == 'Client Entertainment') return clientEntertainment;

    // Entertainment
    if (category == 'Movies / OTT') return moviesOTT;
    if (category == 'Games') return games;
    if (category == 'Shopping') return shopping;
    if (category == 'Travel / Vacation') return travelVacation;

    // Financial
    if (category == 'Loan / EMI') return loanEMI;
    if (category == 'Credit Card Payment') return creditCardPayment;
    if (category == 'Savings / Investment') return savingsInvestment;
    if (category == 'Insurance') return insurance;
    if (category == 'Income Tax') return incomeTax;

    // Personal
    if (category == 'Gifts') return gifts;
    if (category == 'Charity') return charity;
    if (category == 'Pet Care') return petCare;
    if (category == 'Child Expenses') return childExpenses;

    // Default
    if (category == 'Other') return other;
    return category;
  }
}

class BanglaLocalizations extends AppLocalizations {
  @override
  String get appName => 'খরচ ট্র্যাকার';
  @override
  String get ok => 'ঠিক আছে';
  @override
  String get cancel => 'বাতিল';
  @override
  String get save => 'সংরক্ষণ';
  @override
  String get delete => 'মুছুন';
  @override
  String get edit => 'সম্পাদনা';
  @override
  String get back => 'পিছনে';
  @override
  String get search => 'অনুসন্ধান';
  @override
  String get loading => 'লোড হচ্ছে...';
  @override
  String get error => 'ত্রুটি';
  @override
  String get success => 'সফল';
  @override
  String get refresh => 'রিফ্রেশ';
  @override
  String get yes => 'হ্যাঁ';
  @override
  String get no => 'না';

  @override
  String get dashboard => 'ড্যাশবোর্ড';
  @override
  String get history => 'ইতিহাস';
  @override
  String get settings => 'সেটিংস';
  @override
  String get statement => 'বিবৃতি';

  @override
  String get totalBalance => 'মোট ব্যালেন্স';
  @override
  String get totalIncome => 'মোট আয়';
  @override
  String get totalExpense => 'মোট খরচ';
  @override
  String get addExpense => 'খরচ যোগ করুন';
  @override
  String get addIncome => 'আয় যোগ করুন';
  @override
  String get categoryExpenses => 'বিভাগ অনুযায়ী খরচ';
  @override
  String get dailyTrends => 'দৈনিক প্রবণতা';
  @override
  String get viewDetails => 'বিস্তারিত দেখুন';
  @override
  String get noDataAvailable => 'কোন তথ্য নেই';
  @override
  String get selectMonth => 'মাস নির্বাচন করুন';
  @override
  String get income => 'আয়';
  @override
  String get expense => 'খরচ';

  @override
  String get monthlyBudget => 'মাসিক বাজেট';
  @override
  String get setBudget => 'বাজেট সেট করুন';
  @override
  String get budgetRemaining => 'বাজেট অবশিষ্ট';
  @override
  String get budgetExceeded => 'বাজেট অতিক্রম করেছে';
  @override
  String get budgetWarning => 'বাজেট সতর্কতা';

  @override
  String get food => 'খাবার';
  @override
  String get transport => 'যাতায়াত';
  @override
  String get shopping => 'কেনাকাটা';
  @override
  String get entertainment => 'বিনোদন';
  @override
  String get health => 'স্বাস্থ্য';
  @override
  String get education => 'শিক্ষা';
  @override
  String get bills => 'বিল';
  @override
  String get other => 'অন্যান্য';
  @override
  String get salary => 'বেতন';
  @override
  String get freelance => 'ফ্রিল্যান্স';
  @override
  String get investment => 'বিনিয়োগ';
  @override
  String get gift => 'উপহার';
  @override
  String get category => 'বিভাগ';

  @override
  String get addExpenseTitle => 'খরচ যোগ করুন';
  @override
  String get enterAmount => 'পরিমাণ লিখুন';
  @override
  String get amount => 'পরিমাণ';
  @override
  String get selectCategory => 'বিভাগ নির্বাচন করুন';
  @override
  String get selectDate => 'তারিখ নির্বাচন করুন';
  @override
  String get addNote => 'নোট যোগ করুন';
  @override
  String get note => 'নোট';
  @override
  String get expenseAdded => 'খরচ সফলভাবে যোগ করা হয়েছে';
  @override
  String get enterValidAmount => 'সঠিক পরিমাণ লিখুন';

  @override
  String get addIncomeTitle => 'আয় যোগ করুন';
  @override
  String get incomeAdded => 'আয় সফলভাবে যোগ করা হয়েছে';
  @override
  String get selectIncomeCategory => 'আয়ের বিভাগ নির্বাচন করুন';

  @override
  String get allTransactions => 'সকল লেনদেন';
  @override
  String get thisMonth => 'এই মাস';
  @override
  String get lastMonth => 'গত মাস';
  @override
  String get last3Months => 'গত ৩ মাস';
  @override
  String get last6Months => 'গত ৬ মাস';
  @override
  String get customRange => 'কাস্টম রেঞ্জ';
  @override
  String get from => 'থেকে';
  @override
  String get to => 'পর্যন্ত';
  @override
  String get apply => 'প্রয়োগ করুন';
  @override
  String get noTransactions => 'কোন লেনদেন পাওয়া যায়নি';
  @override
  String get transactions => 'লেনদেন';
  @override
  String get filter => 'ফিল্টার';

  @override
  String get appearance => 'চেহারা';
  @override
  String get darkMode => 'ডার্ক মোড';
  @override
  String get language => 'ভাষা';
  @override
  String get selectLanguage => 'ভাষা নির্বাচন করুন';
  @override
  String get dataManagement => 'ডেটা ব্যবস্থাপনা';
  @override
  String get backup => 'ব্যাকআপ';
  @override
  String get restore => 'পুনরুদ্ধার';
  @override
  String get exportData => 'ডেটা রপ্তানি';
  @override
  String get importData => 'ডেটা আমদানি';
  @override
  String get backupToCloud => 'ক্লাউডে ব্যাকআপ';
  @override
  String get restoreFromCloud => 'ক্লাউড থেকে পুনরুদ্ধার';
  @override
  String get lastBackup => 'শেষ ব্যাকআপ';
  @override
  String get never => 'কখনো নয়';
  @override
  String get account => 'অ্যাকাউন্ট';
  @override
  String get signOut => 'সাইন আউট';
  @override
  String get signIn => 'সাইন ইন';
  @override
  String get about => 'সম্পর্কে';
  @override
  String get version => 'সংস্করণ';
  @override
  String get developerInfo => 'ডেভেলপার তথ্য';
  @override
  String get clearData => 'ডেটা মুছুন';
  @override
  String get clearAllData => 'সব ডেটা মুছুন';
  @override
  String get confirmClearData =>
      'আপনি কি নিশ্চিত যে সমস্ত ডেটা মুছে ফেলতে চান? এই কাজটি পূর্বাবস্থায় ফেরানো যাবে না।';

  @override
  String get welcomeBack => 'আবার স্বাগতম';
  @override
  String get signInWithGoogle => 'গুগল দিয়ে সাইন ইন করুন';
  @override
  String get signInToSync => 'আপনার ডেটা সিঙ্ক করতে সাইন ইন করুন';
  @override
  String get signedInAs => 'সাইন ইন আছে';
  @override
  String get signOutConfirm => 'আপনি কি সাইন আউট করতে চান?';

  // Login screen
  @override
  String get loginTagline => 'স্মার্ট হিসাব, সব ডিভাইসে সবসময়';
  @override
  String get loginTitle => 'স্বাগতম';
  @override
  String get loginSubtitle =>
      'আপনার আর্থিক হিসাব নিরাপদ রাখতে এবং সব ডিভাইসে সিঙ্ক করতে সাইন ইন করুন।';
  @override
  String get continueWithGoogle => 'Google দিয়ে চালিয়ে যান';
  @override
  String get signingIn => 'সাইন ইন হচ্ছে…';
  @override
  String get featureSyncTitle => 'রিয়েল-টাইম সিঙ্ক';
  @override
  String get featureSyncDesc => 'যেকোনো পরিবর্তন সাথে সাথে সব ডিভাইসে';
  @override
  String get featureSecureTitle => 'নিরাপদ ও গোপনীয়';
  @override
  String get featureSecureDesc => 'আপনার ডেটা শুধু আপনিই দেখতে পারবেন';
  @override
  String get featureInsightsTitle => 'স্মার্ট বিশ্লেষণ';
  @override
  String get featureInsightsDesc => 'চার্ট, বাজেট আর PDF বিবরণী';
  @override
  String get secureSignInNote =>
      'Google দ্বারা সুরক্ষিত। আপনার পাসওয়ার্ড আমরা কখনো দেখি না।';
  @override
  String get signInFailed => 'সাইন ইন হয়নি। আবার চেষ্টা করুন।';
  @override
  String get signInNetworkError =>
      'ইন্টারনেট সংযোগ নেই। নেটওয়ার্ক দেখে আবার চেষ্টা করুন।';

  @override
  String get generateStatement => 'বিবৃতি তৈরি করুন';
  @override
  String get selectPeriod => 'সময়কাল নির্বাচন করুন';
  @override
  String get statementGenerated => 'বিবৃতি সফলভাবে তৈরি হয়েছে';
  @override
  String get downloadStatement => 'বিবৃতি ডাউনলোড করুন';
  @override
  String get shareStatement => 'বিবৃতি শেয়ার করুন';
  @override
  String get startDate => 'শুরুর তারিখ';
  @override
  String get endDate => 'শেষ তারিখ';
  @override
  String get generate => 'তৈরি করুন';

  @override
  String get personalFinanceManagement => 'ব্যক্তিগত আর্থিক ব্যবস্থাপনা';
  @override
  String get accountStatement => 'হিসাব বিবৃতি';
  @override
  String get statementPeriod => 'বিবৃতি সময়কাল';
  @override
  String get accountSummary => 'হিসাব সারসংক্ষেপ';
  @override
  String get openingBalance => 'শুরুর ব্যালেন্স';
  @override
  String get closingBalance => 'শেষ ব্যালেন্স';
  @override
  String get totalTransactions => 'মোট লেনদেন';
  @override
  String get transactionDetails => 'লেনদেনের বিবরণ';
  @override
  String get date => 'তারিখ';
  @override
  String get description => 'বিবরণ';
  @override
  String get debit => 'ডেবিট';
  @override
  String get credit => 'ক্রেডিট';
  @override
  String get balance => 'ব্যালেন্স';
  @override
  String get runningBalance => 'চলমান ব্যালেন্স';
  @override
  String get statementFooter =>
      'এটি একটি কম্পিউটার জেনারেটেড বিবৃতি এবং স্বাক্ষর প্রয়োজন নেই';
  @override
  String get thisStatementIsGenerated =>
      'এই বিবৃতিটি স্বয়ংক্রিয়ভাবে তৈরি হয়েছে';
  @override
  String get pageOf => 'পৃষ্ঠা';

  @override
  String get budgetUpdated => 'বাজেট সফলভাবে আপডেট হয়েছে';
  @override
  String get dataBackedUp => 'ডেটা সফলভাবে ব্যাকআপ হয়েছে';
  @override
  String get dataRestored => 'ডেটা সফলভাবে পুনরুদ্ধার হয়েছে';
  @override
  String get dataExported => 'ডেটা সফলভাবে রপ্তানি হয়েছে';
  @override
  String get dataImported => 'ডেটা সফলভাবে আমদানি হয়েছে';
  @override
  String get dataClearedSuccess => 'সমস্ত ডেটা সফলভাবে মুছে ফেলা হয়েছে';
  @override
  String get operationFailed => 'অপারেশন ব্যর্থ হয়েছে';
  @override
  String get networkError => 'নেটওয়ার্ক ত্রুটি ঘটেছে';
  @override
  String get permissionDenied => 'অনুমতি অস্বীকৃত';
  @override
  String get fileSaved => 'ফাইল সফলভাবে সংরক্ষিত হয়েছে';

  @override
  String get requiredField => 'এই ক্ষেত্রটি প্রয়োজন';
  @override
  String get invalidAmount => 'অবৈধ পরিমাণ';
  @override
  String get selectValidDate => 'সঠিক তারিখ নির্বাচন করুন';
  @override
  String get selectValidCategory => 'সঠিক বিভাগ নির্বাচন করুন';

  @override
  String get categoryReport => 'বিভাগ প্রতিবেদন';
  @override
  String get expensesByCategory => 'বিভাগ অনুযায়ী খরচ';
  @override
  String get dailyExpenseTrend => 'দৈনিক খরচের প্রবণতা';
  @override
  String get weeklyAverage => 'সাপ্তাহিক গড়';
  @override
  String get monthlyTotal => 'মাসিক মোট';
  @override
  String get highestExpense => 'সর্বোচ্চ খরচ';
  @override
  String get lowestExpense => 'সর্বনিম্ন খরচ';

  @override
  String get monday => 'সোমবার';
  @override
  String get tuesday => 'মঙ্গলবার';
  @override
  String get wednesday => 'বুধবার';
  @override
  String get thursday => 'বৃহস্পতিবার';
  @override
  String get friday => 'শুক্রবার';
  @override
  String get saturday => 'শনিবার';
  @override
  String get sunday => 'রবিবার';

  @override
  String get january => 'জানুয়ারি';
  @override
  String get february => 'ফেব্রুয়ারি';
  @override
  String get march => 'মার্চ';
  @override
  String get april => 'এপ্রিল';
  @override
  String get may => 'মে';
  @override
  String get june => 'জুন';
  @override
  String get july => 'জুলাই';
  @override
  String get august => 'আগস্ট';
  @override
  String get september => 'সেপ্টেম্বর';
  @override
  String get october => 'অক্টোবর';
  @override
  String get november => 'নভেম্বর';
  @override
  String get december => 'ডিসেম্বর';

  // Additional UI Strings
  @override
  String get all => 'সব';
  @override
  String get expenses => 'ব্যয়';
  @override
  String get view => 'দেখুন';
  @override
  String get spent => 'ব্যয়িত';
  @override
  String get remaining => 'অবশিষ্ট';
  @override
  String get overBudget => 'বাজেট অতিক্রম';
  @override
  String get noExpensesThisMonth => 'এই মাসে কোন ব্যয় নেই';
  @override
  String get noExpensesLast7Days => 'শেষ ৭ দিনে কোন ব্যয় নেই';
  @override
  String get noExpensesInAnyCategory => 'কোন বিভাগে ব্যয় নেই';
  @override
  String get noExpensesFound => 'কোন ব্যয় পাওয়া যায়নি';
  @override
  String get titleOptional => 'শিরোনাম (ঐচ্ছিক)';
  @override
  String get titleHint => 'যেমন: বিদ্যুৎ বিল';
  @override
  String get incomeTitleHint => 'যেমন: মাসিক বেতন';
  @override
  String get incomeCategory => 'আয়ের ধরন';
  @override
  String get pleaseEnterAmount => 'অনুগ্রহ করে পরিমাণ লিখুন';
  @override
  String get pleaseEnterValidAmount => 'অনুগ্রহ করে একটি সঠিক পরিমাণ লিখুন';
  @override
  String get noteOptional => 'নোট (ঐচ্ছিক)';
  @override
  String get noteHint => 'অতিরিক্ত নোট যুক্ত করুন';
  @override
  String get updateExpense => 'ব্যয় আপডেট করুন';
  @override
  String get saveExpense => 'ব্যয় সংরক্ষণ করুন';
  @override
  String get updateIncome => 'আয় আপডেট করুন';
  @override
  String get saveIncome => 'আয় সংরক্ষণ করুন';
  @override
  String get expenseUpdated => 'ব্যয় আপডেট হয়েছে!';
  @override
  String get incomeUpdated => 'আয় আপডেট হয়েছে!';
  @override
  String get quickSelectPeriod => 'দ্রুত সময়কাল নির্বাচন';
  @override
  String get last30Days => 'শেষ ৩০ দিন';
  @override
  String get thisYear => 'এই বছর';
  @override
  String get customDateRange => 'কাস্টম তারিখ পরিসীমা';
  @override
  String get totalCredits => 'মোট জমা (+)';
  @override
  String get totalDebits => 'মোট খরচ (-)';
  @override
  String get surplus => 'উদ্বৃত্ত';
  @override
  String get deficit => 'ঘাটতি';
  @override
  String get noTransactionsFound => 'কোন লেনদেন পাওয়া যায়নি';
  @override
  String get noTransactionsMessage =>
      'নির্বাচিত সময়ের জন্য কোন লেনদেন পাওয়া যায়নি।\\nঅনুগ্রহ করে আপনার তারিখের পরিসীমা সামঞ্জস্য করুন।';
  @override
  String get downloadPdfStatement => 'পিডিএফ বিবরণী ডাউনলোড করুন';

  // Category Dialog Strings (selectIncomeCategory and selectCategory already exist above)
  @override
  String get categoriesAvailable => 'বিভাগ উপলব্ধ';

  @override
  String get chooseDifferentGroup => 'ভিন্ন গ্রুপ নির্বাচন করুন';

  // Category Group Names
  @override
  String get basicHouseholdExpenses => 'মৌলিক ঘরোয়া খরচ';
  @override
  String get dailyLiving => 'দৈনন্দিন জীবনযাত্রা';
  @override
  String get transportation => 'যাতায়াত';
  @override
  String get healthWellness => 'স্বাস্থ্য ও সুস্থতা';
  @override
  String get workBusiness => 'কাজ ও ব্যবসা';
  @override
  String get financialObligations => 'আর্থিক বাধ্যবাধকতা';
  @override
  String get specialOccasions => 'বিশেষ অনুষ্ঠান';
  @override
  String get miscellaneous => 'বিবিধ';

  // Income Categories (only new ones, salary/freelance/investment/gift already exist above)
  @override
  String get business => 'ব্যবসা';

  // Expense Categories - Basic Household
  @override
  String get electricity => 'বিদ্যুৎ';
  @override
  String get water => 'পানি';
  @override
  String get internet => 'ইন্টারনেট';
  @override
  String get gas => 'গ্যাস';
  @override
  String get rentHouse => 'ভাড়া / বাড়ি';
  @override
  String get maintenanceRepair => 'রক্ষণাবেক্ষণ / মেরামত';

  // Daily Living
  @override
  String get foodRestaurant => 'খাবার / রেস্তোরাঁ';
  @override
  String get grocery => 'মুদিখানা';
  @override
  String get vegetable => 'সবজি';
  @override
  String get snacks => 'নাস্তা';
  @override
  String get laundryCleaning => 'লন্ড্রি / পরিষ্কার';

  // Transportation (specific categories, transport category already exists above)
  String get fuel => 'জ্বালানি';
  String get publicTransport => 'পাবলিক ট্রান্সপোর্ট';
  String get parking => 'পার্কিং';
  String get vehicleMaintenance => 'গাড়ি রক্ষণাবেক্ষণ';

  // Health & Wellness
  @override
  String get medicine => 'ওষুধ';
  @override
  String get doctorHospital => 'ডাক্তার / হাসপাতাল';
  @override
  String get fitnessGym => 'ফিটনেস / জিম';

  // Education
  @override
  String get tuitionFees => 'টিউশন ফি';
  @override
  String get stationery => 'লেখার সামগ্রী';
  @override
  String get onlineCourses => 'অনলাইন কোর্স';

  // Work & Business
  @override
  String get officeSupplies => 'অফিস সরঞ্জাম';
  @override
  String get businessTravel => 'ব্যবসায়িক ভ্রমণ';
  @override
  String get clientEntertainment => 'ক্লায়েন্ট বিনোদন';

  // Entertainment & Lifestyle (shopping already exists above)
  @override
  String get moviesOTT => 'সিনেমা / ওটিটি';
  @override
  String get games => 'গেম';
  @override
  String get travelVacation => 'ভ্রমণ / ছুটি';

  // Financial
  @override
  String get loanEMI => 'ঋণ / ইএমআই';
  @override
  String get creditCardPayment => 'ক্রেডিট কার্ড পেমেন্ট';
  @override
  String get savingsInvestment => 'সঞ্চয় / বিনিয়োগ';
  @override
  String get insurance => 'বীমা';
  @override
  String get incomeTax => 'আয়কর';

  // Personal / Family
  @override
  String get gifts => 'উপহার';
  @override
  String get charity => 'দান';
  @override
  String get petCare => 'পোষা প্রাণীর যত্ন';
  @override
  String get childExpenses => 'সন্তানের খরচ';

  // ========== DEPOSIT/SAVINGS FEATURE ==========
  @override
  String get appMode => 'অ্যাপ মোড';
  @override
  String get expenseMode => 'খরচ মোড';
  @override
  String get depositMode => 'সঞ্চয় মোড';
  @override
  String get switchToDepositMode => 'সঞ্চয় মোডে যান';
  @override
  String get switchToExpenseMode => 'খরচ মোডে যান';
  @override
  String get depositProfiles => 'সঞ্চয় লক্ষ্য';
  @override
  String get createProfile => 'লক্ষ্য তৈরি করুন';
  @override
  String get editProfile => 'লক্ষ্য সম্পাদনা';
  @override
  String get profileName => 'লক্ষ্যের নাম';
  @override
  String get targetAmount => 'লক্ষ্য পরিমাণ';
  @override
  String get deadline => 'সময়সীমা';
  @override
  String get currentBalance => 'বর্তমান ব্যালেন্স';
  @override
  String get remainingAmount => 'বাকি পরিমাণ';
  @override
  String get daysRemaining => 'বাকি দিন';
  @override
  String get addDeposit => 'জমা করুন';
  @override
  String get withdraw => 'উত্তোলন';
  @override
  String get depositAmount => 'জমার পরিমাণ';
  @override
  String get withdrawAmount => 'উত্তোলনের পরিমাণ';
  @override
  String get profileCompleted => 'লক্ষ্য সম্পন্ন';
  @override
  String get goalReached => 'লক্ষ্যে পৌঁছেছেন!';
  @override
  String get onTrack => 'সঠিক পথে';
  @override
  String get behind => 'পিছিয়ে আছেন';
  @override
  String get noProfiles => 'কোন সঞ্চয় লক্ষ্য নেই';
  @override
  String get createFirstProfile =>
      'ট্র্যাকিং শুরু করতে আপনার প্রথম সঞ্চয় লক্ষ্য তৈরি করুন!';
  @override
  String get profileCreated => 'লক্ষ্য সফলভাবে তৈরি হয়েছে!';
  @override
  String get profileUpdated => 'লক্ষ্য সফলভাবে আপডেট হয়েছে!';
  @override
  String get saveProfile => 'লক্ষ্য সংরক্ষণ করুন';
  @override
  String get updateProfile => 'লক্ষ্য আপডেট করুন';
  @override
  String get pleaseEnterName => 'একটি নাম লিখুন';
  @override
  String get depositAdded => 'জমা সফলভাবে যোগ হয়েছে!';
  @override
  String get withdrawCompleted => 'উত্তোলন সম্পন্ন!';
  @override
  String get confirmWithdraw => 'উত্তোলন নিশ্চিত করুন';
  @override
  String get availableBalance => 'উপলব্ধ ব্যালেন্স';
  @override
  String get insufficientBalance => 'অপর্যাপ্ত ব্যালেন্স';
  @override
  String get depositHistory => 'জমার ইতিহাস';
  @override
  String get allProfiles => 'সকল লক্ষ্য';
  @override
  String get noMatchingTransactions => 'কোন মিল পাওয়া যায়নি';
  @override
  String get startByAddingDeposit => 'আপনার সঞ্চয় লক্ষ্যে জমা দিয়ে শুরু করুন';

  // Design refresh
  @override
  String get goodMorning => 'শুভ সকাল';
  @override
  String get goodAfternoon => 'শুভ অপরাহ্ন';
  @override
  String get goodEvening => 'শুভ সন্ধ্যা';
  @override
  String get overview => 'সংক্ষিপ্ত চিত্র';
  @override
  String get monthBalance => 'এই মাসের ব্যালেন্স';
  @override
  String get recentTransactions => 'সাম্প্রতিক লেনদেন';
  @override
  String get seeAll => 'সব দেখুন';
  @override
  String get today => 'আজ';
  @override
  String get yesterday => 'গতকাল';
  @override
  String get usedLabel => 'ব্যবহৃত';
  @override
  String get total => 'মোট';
  @override
  String get average => 'গড়';
  @override
  String get highestDay => 'সর্বোচ্চ দিন';
  @override
  String get searchTransactions => 'লেনদেন খুঁজুন';
  @override
  String get deleteTransactionTitle => 'লেনদেনটি মুছবেন?';
  @override
  String get deleteCannotUndo => 'এটি আর ফিরিয়ে আনা যাবে না।';
  @override
  String get transactionDeleted => 'লেনদেন মুছে ফেলা হয়েছে';
  @override
  String get deleteProfileTitle => 'লক্ষ্যটি মুছবেন?';
  @override
  String get deleteProfileMessage => 'এই লক্ষ্যের সব জমা ও উত্তোলনও মুছে যাবে।';
  @override
  String get activeGoals => 'চলমান লক্ষ্য';
  @override
  String get completedGoals => 'সম্পন্ন লক্ষ্য';
  @override
  String get totalSavings => 'মোট সঞ্চয়';
  @override
  String get saved => 'জমা';
  @override
  String get withdrawn => 'উত্তোলন';
  @override
  String get completedLabel => 'সম্পন্ন';
  @override
  String get depositLabel => 'জমা';
  @override
  String get withdrawalLabel => 'উত্তোলন';
  @override
  String get downloadPdf => 'PDF ডাউনলোড';
  @override
  String get sharePdf => 'PDF শেয়ার';
  @override
  String get noExpensesInPeriod => 'এই সময়ে কোনো খরচ নেই';
  @override
  String get general => 'সাধারণ';
  @override
  String get dangerZone => 'সতর্কতা অঞ্চল';
  @override
  String get developerInfoSubtitle => 'ডেভেলপার পরিচিতি ও যোগাযোগ';
  @override
  String get clearAllDataSubtitle => 'সব খরচ স্থায়ীভাবে মুছে ফেলুন';
  @override
  String get statementFormatNote => 'প্রতিটি লেনদেনের চলতি ব্যালেন্সসহ ব্যাংক-স্টাইলের PDF আকারে আপনার বিবরণী তৈরি হবে।';
  @override
  String get profileNameHint => 'যেমন: জরুরি তহবিল';
  @override
  String get congratulations => 'অভিনন্দন!';
  @override
  String get awesome => 'দারুণ!';
  @override
  String get aboutDeveloper => 'ডেভেলপার সম্পর্কে';
  @override
  String get softwareDeveloper => 'সফটওয়্যার ডেভেলপার';
  @override
  String get appDescription => 'খরচ ও আয়ের হিসাব, বাজেট ও সঞ্চয়ের লক্ষ্য ব্যবস্থাপনার জন্য একটি ব্যক্তিগত আর্থিক অ্যাপ — সহজ চার্ট ও PDF বিবরণীসহ।';
  @override
  String get contact => 'যোগাযোগ';
  @override
  String get emailLabel => 'ইমেইল';
  @override
  String get websiteLabel => 'ওয়েবসাইট';
  @override
  String get permanentDeletion => 'সব ডেটা স্থায়ীভাবে মুছুন';
  @override
  String get deletionWillTitle => 'এর ফলে:';
  @override
  String get deletionPointDevice => 'এই ডিভাইস থেকে সব খরচ মুছে যাবে';
  @override
  String get deletionPointCloud => 'ক্লাউড থেকে আপনার সব খরচ মুছে যাবে';
  @override
  String get deletionPointRecovery => 'ডেটা আর কখনো ফেরত আনা যাবে না';
  @override
  String get typeToConfirm => 'নিশ্চিত করতে DELETE ALL DATA লিখুন';
  @override
  String get confirmTextVerified => 'নিশ্চিতকরণ সঠিক হয়েছে';
  @override
  String get continueLabel => 'চালিয়ে যান';
  @override
  String get finalWarning => 'শেষ সতর্কতা';
  @override
  String get finalWarningMessage => 'আপনার সব খরচের ডেটা স্থায়ীভাবে মুছে যাবে এবং আর ফেরত আনা যাবে না। আপনি কি পুরোপুরি নিশ্চিত?';
  @override
  String get keepMyData => 'ডেটা রাখুন';
  @override
  String get deletePermanently => 'স্থায়ীভাবে মুছুন';
  @override
  String get preparingDeletion => 'মুছে ফেলার প্রস্তুতি চলছে…';
  @override
  String get deletingData => 'সব ডেটা মুছে ফেলা হচ্ছে…';
  @override
  String get deletionComplete => 'মুছে ফেলা সম্পন্ন';
  @override
  String get allDataDeleted => 'সব ডেটা স্থায়ীভাবে মুছে ফেলা হয়েছে।';
  @override
  String get cloudDeletionPending => 'এই ডিভাইস থেকে মুছে ফেলা হয়েছে। অনলাইনে এলে ক্লাউডের কপিও মুছে যাবে।';
  @override
  String daysLeft(int days) => '${_bn(days)} দিন বাকি';
  @override
  String daysOverdue(int days) => '${_bn(days)} দিন পেরিয়ে গেছে';
  @override
  String transactionCount(int count) => '${_bn(count)}টি লেনদেন';
  @override
  String lastNDays(int days) => 'শেষ ${_bn(days)} দিন';
  @override
  String startingIn(int seconds) => '${_bn(seconds)} সেকেন্ডে শুরু হবে';
  @override
  String secondsElapsed(int seconds) => '${_bn(seconds)} সেকেন্ড পেরিয়েছে';
  @override
  String amountSaved(String amount) => '$amount জমা হয়েছে';
  @override
  String userCount(int count) => '${_bn(count)} জন ইউজার';

  static String _bn(int value) {
    const digits = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
    return value
        .toString()
        .split('')
        .map((c) => int.tryParse(c) == null ? c : digits[int.parse(c)])
        .join();
  }

  // Admin panel and account access
  @override
  String get adminPanel => 'অ্যাডমিন প্যানেল';
  @override
  String get adminPanelSubtitle => 'ইউজার অনুমোদন, মেইনটেন্যান্স ও ফিচার নিয়ন্ত্রণ';
  @override
  String get administration => 'প্রশাসন';
  @override
  String get usersTab => 'ইউজার';
  @override
  String get appControlsTab => 'অ্যাপ নিয়ন্ত্রণ';
  @override
  String get statusPending => 'অপেক্ষমাণ';
  @override
  String get statusApproved => 'অনুমোদিত';
  @override
  String get statusBlocked => 'ব্লক করা';
  @override
  String get approve => 'অনুমোদন দিন';
  @override
  String get approveAll => 'সবাইকে অনুমোদন দিন';
  @override
  String get approveAllTitle => 'তালিকার অপেক্ষমাণ সবাইকে অনুমোদন দেবেন?';
  @override
  String get block => 'ব্লক করুন';
  @override
  String get unblock => 'আনব্লক করুন';
  @override
  String get moveToPending => 'অপেক্ষমাণ তালিকায় নিন';
  @override
  String get blockUserTitle => 'এই ইউজারকে ব্লক করবেন?';
  @override
  String get blockUserMessage => 'আনব্লক না করা পর্যন্ত তিনি অ্যাপ ব্যবহার করতে পারবেন না।';
  @override
  String get blockReasonHint => 'কারণ (ঐচ্ছিক, ইউজার দেখতে পাবেন)';
  @override
  String get userApproved => 'ইউজার অনুমোদিত হয়েছেন';
  @override
  String get userBlocked => 'ইউজার ব্লক করা হয়েছে';
  @override
  String get userMovedToPending => 'অপেক্ষমাণ তালিকায় নেওয়া হয়েছে';
  @override
  String get searchByEmail => 'ইমেইল দিয়ে ইউজার খুঁজুন';
  @override
  String get userNotFound => 'এই ইমেইলের কোনো ইউজার নেই';
  @override
  String get noUsersHere => 'এখানে কোনো ইউজার নেই';
  @override
  String get loadMore => 'আরও দেখুন';
  @override
  String get joined => 'যোগদান';
  @override
  String get features => 'ফিচার';
  @override
  String get featureSavings => 'সঞ্চয়ের লক্ষ্য';
  @override
  String get featureSavingsDesc => 'লক্ষ্য, জমা ও উত্তোলনসহ সঞ্চয় মোড';
  @override
  String get featureStatement => 'PDF বিবরণী';
  @override
  String get featureStatementDesc => 'হিসাব বিবরণী PDF আকারে ডাউনলোড';
  @override
  String get featureCloudSync => 'ক্লাউড সিঙ্ক';
  @override
  String get featureCloudSyncDesc => 'ডিভাইসগুলোর মধ্যে ডেটা সিঙ্ক। বন্ধ থাকলে ডেটা ডিভাইসে থাকে, পরে সিঙ্ক হয়।';
  @override
  String get followAppSetting => 'ডিফল্ট';
  @override
  String get onLabel => 'চালু';
  @override
  String get offLabel => 'বন্ধ';
  @override
  String get userFeaturesHint => 'শুধু এই ইউজারের জন্য। ডিফল্ট মানে সবার জন্য যে সেটিং।';
  @override
  String get maintenanceMode => 'মেইনটেন্যান্স মোড';
  @override
  String get maintenanceModeDesc => 'অ্যাডমিন ছাড়া সবাই মেইনটেন্যান্স স্ক্রিন দেখবেন';
  @override
  String get maintenanceOnTitle => 'মেইনটেন্যান্স মোড চালু করবেন?';
  @override
  String get maintenanceMessageLabel => 'ইউজারদের জন্য বার্তা';
  @override
  String get maintenanceIsOn => 'মেইনটেন্যান্স মোড চালু — ইউজাররা এখন অ্যাপ ব্যবহার করতে পারছেন না।';
  @override
  String get newUsers => 'নতুন ইউজার';
  @override
  String get requireApproval => 'অনুমোদন বাধ্যতামূলক';
  @override
  String get requireApprovalDesc => 'নতুন ইউজাররা আপনার অনুমোদনের অপেক্ষায় থাকবেন। বন্ধ থাকলে স্বয়ংক্রিয়ভাবে অনুমোদিত হবেন।';
  @override
  String get featuresForEveryone => 'সবার জন্য ফিচার';
  @override
  String get settingSaved => 'সংরক্ষিত হয়েছে';
  @override
  String get savedWhenOnline => 'সংরক্ষিত। অনলাইনে এলে কার্যকর হবে।';
  @override
  String get checkingAccount => 'আপনার অ্যাকাউন্ট যাচাই হচ্ছে…';
  @override
  String get pendingTitle => 'অনুমোদনের অপেক্ষায়';
  @override
  String get pendingMessage => 'আপনার অ্যাকাউন্ট নিবন্ধিত হয়েছে। অ্যাডমিন শীঘ্রই এটি যাচাই করবেন — অনুমোদন পেলে এই স্ক্রিন নিজে থেকেই বদলে যাবে।';
  @override
  String get blockedTitle => 'অ্যাকাউন্ট ব্লক করা হয়েছে';
  @override
  String get blockedMessage => 'অ্যাডমিন আপনার অ্যাকাউন্ট ব্লক করেছেন।';
  @override
  String get reasonLabel => 'কারণ';
  @override
  String get maintenanceTitle => 'রক্ষণাবেক্ষণ চলছে';
  @override
  String get maintenanceDefaultMessage => 'অ্যাপটি উন্নত করা হচ্ছে। কিছুক্ষণ পরে আবার দেখুন।';
  @override
  String get contactSupport => 'সাপোর্টে যোগাযোগ';
  @override
  String get featureDisabled => 'অ্যাডমিন এই ফিচারটি বন্ধ রেখেছেন।';
  @override
  String get cloudSyncPaused => 'অ্যাডমিন ক্লাউড সিঙ্ক বন্ধ রেখেছেন। আপনার ডেটা এই ডিভাইসে নিরাপদ, পরে সিঙ্ক হবে।';

  @override
  String getCategoryName(String category) {
    // Income categories
    if (category == 'Salary') return salary;
    if (category == 'Business') return business;
    if (category == 'Freelance') return freelance;
    if (category == 'Investment') return investment;
    if (category == 'Gift') return gift;

    // Basic Household
    if (category == 'Electricity') return electricity;
    if (category == 'Water') return water;
    if (category == 'Internet') return internet;
    if (category == 'Gas') return gas;
    if (category == 'Rent / House') return rentHouse;
    if (category == 'Maintenance / Repair') return maintenanceRepair;

    // Daily Living
    if (category == 'Food / Restaurant') return foodRestaurant;
    if (category == 'Grocery') return grocery;
    if (category == 'Vegetable') return vegetable;
    if (category == 'Snacks') return snacks;
    if (category == 'Laundry / Cleaning') return laundryCleaning;

    // Transportation
    if (category == 'Fuel') return fuel;
    if (category == 'Public Transport') return publicTransport;
    if (category == 'Parking') return parking;
    if (category == 'Vehicle Maintenance') return vehicleMaintenance;
    if (category == 'Transport') return transport;

    // Health
    if (category == 'Medicine') return medicine;
    if (category == 'Doctor / Hospital') return doctorHospital;
    if (category == 'Fitness / Gym') return fitnessGym;

    // Education
    if (category == 'Tuition Fees') return tuitionFees;
    if (category == 'Stationery') return stationery;
    if (category == 'Online Courses') return onlineCourses;

    // Work & Business
    if (category == 'Office Supplies') return officeSupplies;
    if (category == 'Business Travel') return businessTravel;
    if (category == 'Client Entertainment') return clientEntertainment;

    // Entertainment
    if (category == 'Movies / OTT') return moviesOTT;
    if (category == 'Games') return games;
    if (category == 'Shopping') return shopping;
    if (category == 'Travel / Vacation') return travelVacation;

    // Financial
    if (category == 'Loan / EMI') return loanEMI;
    if (category == 'Credit Card Payment') return creditCardPayment;
    if (category == 'Savings / Investment') return savingsInvestment;
    if (category == 'Insurance') return insurance;
    if (category == 'Income Tax') return incomeTax;

    // Personal
    if (category == 'Gifts') return gifts;
    if (category == 'Charity') return charity;
    if (category == 'Pet Care') return petCare;
    if (category == 'Child Expenses') return childExpenses;

    // Default
    if (category == 'Other') return other;
    return category;
  }
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'bn'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    if (locale.languageCode == 'bn') {
      return BanglaLocalizations();
    }
    return EnglishLocalizations();
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}
