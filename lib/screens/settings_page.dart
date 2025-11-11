import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/theme_provider.dart';
import '../providers/budget_provider.dart';
import '../providers/expense_provider.dart';
import '../providers/auth_provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final budgetProvider = Provider.of<BudgetProvider>(context);
    final expenseProvider = Provider.of<ExpenseProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settings',
          style: GoogleFonts.rubik80sFade(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.black,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // User Profile Section
          if (authProvider.isAuthenticated)
            Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundImage: authProvider.getUserPhotoURL() != null
                      ? NetworkImage(authProvider.getUserPhotoURL()!)
                      : null,
                  child: authProvider.getUserPhotoURL() == null
                      ? const Icon(Icons.person)
                      : null,
                ),
                title: Text(
                  authProvider.getUserDisplayName() ?? 'User',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(authProvider.getUserEmail() ?? ''),
                trailing: IconButton(
                  icon: const Icon(Icons.logout, color: Colors.red),
                  onPressed: () => _showSignOutDialog(context, authProvider),
                ),
              ),
            ),
          if (authProvider.isAuthenticated) const SizedBox(height: 16),

          // Cloud Sync Section (Only if authenticated)
          if (authProvider.isAuthenticated) ...[
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.cloud_sync),
                    title: const Text('Auto Sync'),
                    subtitle:
                        const Text('Automatically sync expenses to cloud'),
                    trailing: Switch(
                      value: expenseProvider.autoSync,
                      onChanged: (value) {
                        expenseProvider.toggleAutoSync(value);
                      },
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.backup),
                    title: const Text('Backup to Google Drive'),
                    subtitle: expenseProvider.lastBackupTime != null
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  'Last backup: ${DateFormat('MMM dd, yyyy hh:mm a').format(expenseProvider.lastBackupTime!)}'),
                              if (expenseProvider.autoSync)
                                const Text(
                                  'Auto-backup enabled',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.green,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                            ],
                          )
                        : const Text('Backup all data to Google Drive'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _backupToGoogleDrive(context, expenseProvider),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.cloud_download),
                    title: const Text('Restore from Google Drive'),
                    subtitle: const Text('Restore data from backup'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () =>
                        _restoreFromGoogleDrive(context, expenseProvider),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Statement Section
          Card(
            child: ListTile(
              leading: const Icon(Icons.download),
              title: const Text('Download Statement'),
              subtitle: const Text('Export transactions as PDF or CSV'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.pushNamed(context, '/statement');
              },
            ),
          ),
          const SizedBox(height: 16),

          // Theme Section
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(
                    themeProvider.isDarkMode
                        ? Icons.dark_mode
                        : Icons.light_mode,
                  ),
                  title: const Text('Dark Mode'),
                  trailing: Switch(
                    value: themeProvider.isDarkMode,
                    onChanged: (value) {
                      themeProvider.toggleTheme();
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Budget Section
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.account_balance_wallet),
                  title: const Text('Monthly Budget'),
                  subtitle: Text(
                      '${budgetProvider.monthlyBudget.toStringAsFixed(0)}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () {
                      _showBudgetDialog(context, budgetProvider);
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // App Info Section
          Card(
            child: Column(
              children: [
                const ListTile(
                  leading: Icon(Icons.info),
                  title: Text('App Version'),
                  subtitle: Text('1.0.0'),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.code),
                  title: const Text('About Expense Tracker'),
                  subtitle: const Text('A personal daily expense tracker'),
                  onTap: () {
                    _showAboutDialog(context);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Data Management Section
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.delete_sweep, color: Colors.red),
                  title: const Text(
                    'Delete All Data',
                    style: TextStyle(color: Colors.red),
                  ),
                  subtitle: const Text('Permanent deletion all history'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    _showClearDataDialog(context, expenseProvider);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(context),
    );
  }

  void _showSignOutDialog(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await authProvider.signOut();
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Signed out successfully')),
                );
              }
            },
            child: const Text(
              'Sign Out',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _backupToGoogleDrive(
      BuildContext context, ExpenseProvider expenseProvider) async {
    if (!mounted) return;

    // Show instant feedback
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 12),
            Text('Backing up to Google Drive...'),
          ],
        ),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );

    // Backup in background - provider will update lastBackupTime automatically
    final success = await expenseProvider.backupToGoogleDrive();

    if (!mounted) return;

    if (mounted && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                success ? Icons.check_circle : Icons.error,
                color: Colors.white,
              ),
              const SizedBox(width: 8),
              Text(
                success
                    ? 'Backup completed successfully!'
                    : 'Backup failed. Try again.',
              ),
            ],
          ),
          backgroundColor: success ? Colors.green : Colors.red,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _restoreFromGoogleDrive(
      BuildContext context, ExpenseProvider expenseProvider) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore from Google Drive'),
        content: const Text(
          'This will replace all local expenses with data from Google Drive backup. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Restore'),
          ),
        ],
      ),
    );

    if (confirm != true || !context.mounted) return;

    // Show instant feedback
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 12),
            Text('Restoring from Google Drive...'),
          ],
        ),
        duration: Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );

    final success = await expenseProvider.restoreFromGoogleDrive();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                success ? Icons.check_circle : Icons.error,
                color: Colors.white,
              ),
              const SizedBox(width: 8),
              Text(
                success
                    ? 'Data restored successfully!'
                    : 'Restore failed. Try again.',
              ),
            ],
          ),
          backgroundColor: success ? Colors.green : Colors.red,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showBudgetDialog(BuildContext context, BudgetProvider budgetProvider) {
    final TextEditingController controller = TextEditingController(
      text: budgetProvider.monthlyBudget.toStringAsFixed(0),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Monthly Budget'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Budget Amount',
            prefixIcon: Icon(Icons.account_balance_wallet),
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final budget = double.tryParse(controller.text);
              if (budget != null && budget > 0) {
                // Close dialog immediately
                Navigator.pop(context);

                // Update budget - instant UI update via notifyListeners()
                budgetProvider.setMonthlyBudget(budget);

                // Show success feedback
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.white),
                        const SizedBox(width: 8),
                        Text('Budget updated to ${budget.toStringAsFixed(0)}'),
                      ],
                    ),
                    backgroundColor: Colors.green,
                    duration: const Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid amount'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Expense Tracker',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(Icons.account_balance_wallet, size: 48),
      children: [
        const Text(
          'A personal daily expense tracker with modern dashboard, '
          'category-wise analysis, and budget management features.',
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  void _showClearDataDialog(
      BuildContext context, ExpenseProvider expenseProvider) {
    // Directly show permanent deletion confirmation
    _showPermanentDeleteConfirmation(context, expenseProvider);
  }

  void _showPermanentDeleteConfirmation(
      BuildContext context, ExpenseProvider expenseProvider) {
    final TextEditingController confirmController = TextEditingController();
    bool isConfirmValid = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          icon: const Icon(
            Icons.delete_forever,
            color: Colors.red,
            size: 44,
          ),
          title: const Text(
            'PERMANENT DELETION',
            style: TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red, width: 2),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'THIS ACTION WILL:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text('• Delete ALL expenses from your device'),
                      Text('• Delete ALL backups from Google Drive'),
                      Text('• Make data recovery IMPOSSIBLE'),
                      SizedBox(height: 8),
                      Text(
                        'This action is IRREVERSIBLE!',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'To confirm permanent deletion, type "DELETE ALL DATA" below:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: confirmController,
                  decoration: InputDecoration(
                    hintText: 'DELETE ALL DATA',
                    border: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: isConfirmValid ? Colors.red : Colors.grey,
                      ),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.red, width: 2),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      isConfirmValid = value.trim() == 'DELETE ALL DATA';
                    });
                  },
                ),
                if (isConfirmValid)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 16),
                        SizedBox(width: 4),
                        Text(
                          'Confirmation text verified',
                          style: TextStyle(color: Colors.green, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: isConfirmValid
                  ? () {
                      Navigator.pop(context);
                      _showFinalWarning(context, expenseProvider);
                    }
                  : null,
              child: Text(
                'Continue',
                style: TextStyle(
                  color: isConfirmValid ? Colors.red : Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFinalWarning(
      BuildContext context, ExpenseProvider expenseProvider) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: const Icon(
          Icons.error,
          color: Colors.red,
          size: 72,
        ),
        title: const Text(
          'FINAL WARNING',
          style: TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'This is your LAST CHANCE to cancel.',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            Text(
              'Once you click "DELETE PERMANENTLY", all your expense data will be gone forever and cannot be recovered.',
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            Text(
              'Are you absolutely sure?',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel - Keep My Data',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              // Show fast deletion dialog with countdown
              _showFastDeletionDialog(context, expenseProvider);
            },
            child: const Text(
              'DELETE PERMANENTLY',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFastDeletionDialog(
      BuildContext context, ExpenseProvider expenseProvider) async {
    int countdown = 3;
    bool deletionCompleted = false;

    // Show countdown dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                color: Colors.red,
                strokeWidth: 3,
              ),
              const SizedBox(height: 20),
              Text(
                deletionCompleted
                    ? '✅ Deletion Complete!'
                    : 'Permanently deleting all data...',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              if (!deletionCompleted)
                Text(
                  'Estimated: ${countdown}s remaining',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
            ],
          ),
        ),
      ),
    );

    // Start countdown timer
    for (int i = 3; i > 0; i--) {
      await Future.delayed(const Duration(seconds: 1));
      if (context.mounted) {
        // Find the dialog and update it
        countdown = i - 1;
        // The StatefulBuilder will rebuild automatically
      }
    }

    // Perform permanent deletion
    final stopwatch = Stopwatch()..start();
    final success = await expenseProvider.permanentlyDeleteAllData();
    stopwatch.stop();

    if (context.mounted) {
      // Update dialog to show completion
      deletionCompleted = true;

      // Auto-close after showing completion
      await Future.delayed(const Duration(milliseconds: 500));

      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  success ? Icons.check_circle : Icons.error,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Text(
                  success
                      ? 'All data permanently deleted in ${stopwatch.elapsedMilliseconds}ms'
                      : 'Deletion failed - please try again',
                ),
              ],
            ),
            backgroundColor: success ? Colors.red : Colors.orange,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildBottomNavBar(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: 2,
      onTap: (index) {
        if (index == 0) {
          Navigator.popUntil(context, (route) => route.isFirst);
        } else if (index == 1) {
          Navigator.pop(context);
          Navigator.pushNamed(context, '/history');
        }
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard),
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.history),
          label: 'History',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings),
          label: 'Settings',
        ),
      ],
    );
  }
}
