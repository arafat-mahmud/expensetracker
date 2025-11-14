import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import '../providers/budget_provider.dart';

// Background restore handler that doesn't block the UI
class BackgroundRestoreHandler {
  static bool _hasTriedRestore = false;

  // Reset the restore flag (useful when a new user signs in)
  static void resetRestoreFlag() {
    _hasTriedRestore = false;
    print('🔄 Background restore flag reset');
  }

  static Future<void> performAutoRestore(BuildContext context) async {
    if (_hasTriedRestore) return;
    _hasTriedRestore = true;

    // Add a small delay to let the dashboard render first
    await Future.delayed(const Duration(milliseconds: 500));

    if (!context.mounted) return;

    try {
      final expenseProvider =
          Provider.of<ExpenseProvider>(context, listen: false);
      final budgetProvider =
          Provider.of<BudgetProvider>(context, listen: false);

      // Check if there's any local data - if not, try to restore from Google Drive
      if (expenseProvider.expenses.isEmpty) {
        print(
            '📱 No local data found - attempting silent restore from Google Drive...');

        final success = await expenseProvider.restoreFromGoogleDrive();

        if (success) {
          // Reload budget after restore to update UI
          budgetProvider.reloadBudget();

          if (context.mounted) {
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
          }
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
