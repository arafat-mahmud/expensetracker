import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
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
  DateTime? _lastBackupTime;
  bool _isLoadingBackup = false;

  @override
  void initState() {
    super.initState();
    _loadLastBackupTime();
  }

  Future<void> _loadLastBackupTime() async {
    if (!mounted) return;

    final expenseProvider =
        Provider.of<ExpenseProvider>(context, listen: false);
    final backupTime = await expenseProvider.getLastBackupTime();

    if (!mounted) return;

    setState(() {
      _lastBackupTime = backupTime;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final budgetProvider = Provider.of<BudgetProvider>(context);
    final expenseProvider = Provider.of<ExpenseProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
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
                    subtitle: _lastBackupTime != null
                        ? Text(
                            'Last backup: ${DateFormat('MMM dd, yyyy hh:mm a').format(_lastBackupTime!)}')
                        : const Text('Backup all data to Google Drive'),
                    trailing: _isLoadingBackup
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.chevron_right),
                    onTap: _isLoadingBackup
                        ? null
                        : () => _backupToGoogleDrive(context, expenseProvider),
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
                      '৳${budgetProvider.monthlyBudget.toStringAsFixed(0)}'),
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
                  title: const Text('About SmartBudget'),
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
                    'Clear All Data',
                    style: TextStyle(color: Colors.red),
                  ),
                  subtitle: const Text('Delete all expenses permanently'),
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

    setState(() {
      _isLoadingBackup = true;
    });

    final success = await expenseProvider.backupToGoogleDrive();

    if (!mounted) return;

    setState(() {
      _isLoadingBackup = false;
    });

    if (success) {
      await _loadLastBackupTime();
    }

    if (mounted && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Backup to Google Drive successful'
                : 'Failed to backup to Google Drive',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
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

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    final success = await expenseProvider.restoreFromGoogleDrive();

    if (context.mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Data restored from Google Drive successfully'
                : 'Failed to restore from Google Drive',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
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
            prefixText: '৳ ',
            border: OutlineInputBorder(),
          ),
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
                budgetProvider.setMonthlyBudget(budget);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Budget updated successfully')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a valid amount')),
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
      applicationName: 'SmartBudget',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(Icons.account_balance_wallet, size: 48),
      children: [
        const Text(
          'A personal daily expense tracker with modern dashboard, '
          'category-wise analysis, and budget management features.',
        ),
        const SizedBox(height: 16),
        const Text(
          'Built with Flutter, Hive, and FL Chart.',
          style: TextStyle(fontStyle: FontStyle.italic),
        ),
      ],
    );
  }

  void _showClearDataDialog(
      BuildContext context, ExpenseProvider expenseProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text(
          'Are you sure you want to delete all expenses? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              expenseProvider.clearAllExpenses();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All data cleared')),
              );
            },
            child: const Text(
              'Delete All',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
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
