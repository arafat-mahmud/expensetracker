import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/deposit_model.dart';
import '../../providers/deposit_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/deposit_progress_chart.dart';
import '../../widgets/deposit_transaction_card.dart';
import 'add_deposit_profile_page.dart';
import 'add_deposit_transaction_page.dart';

class DepositProfileDetailPage extends StatelessWidget {
  final DepositProfile profile;

  const DepositProfileDetailPage({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    final depositProvider = Provider.of<DepositProvider>(context);
    final localizations = AppLocalizations.of(context);

    // Get fresh profile data
    final currentProfile =
        depositProvider.getProfileById(profile.id) ?? profile;
    final balance = depositProvider.getProfileBalance(currentProfile.id);
    final progress = depositProvider.getProfileProgress(currentProfile.id);
    final remaining = depositProvider.getRemainingAmount(currentProfile.id);
    final daysRemaining = depositProvider.getDaysRemaining(currentProfile.id);
    final isOnTrack = depositProvider.isOnTrack(currentProfile.id);
    final transactions =
        depositProvider.getTransactionsForProfile(currentProfile.id);

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(currentProfile.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      AddDepositProfilePage(profile: currentProfile),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () => _showDeleteDialog(context, currentProfile),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Progress Chart
                    DepositProgressChart(
                      progress: progress,
                      size: 140,
                      strokeWidth: 14,
                      isCompleted: currentProfile.isCompleted,
                      isOverdue: daysRemaining < 0,
                      isOnTrack: isOnTrack,
                    ),
                    const SizedBox(height: 20),

                    // Balance info
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildInfoColumn(
                          context,
                          localizations.currentBalance,
                          balance.toStringAsFixed(0),
                          Colors.blue,
                        ),
                        Container(
                          height: 40,
                          width: 1,
                          color: isDarkMode
                              ? Colors.grey.shade700
                              : Colors.grey.shade300,
                        ),
                        _buildInfoColumn(
                          context,
                          localizations.targetAmount,
                          currentProfile.targetAmount.toStringAsFixed(0),
                          Colors.green,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),

                    // Remaining & Days info
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildInfoColumn(
                          context,
                          localizations.remainingAmount,
                          remaining.toStringAsFixed(0),
                          Colors.orange,
                        ),
                        Container(
                          height: 40,
                          width: 1,
                          color: isDarkMode
                              ? Colors.grey.shade700
                              : Colors.grey.shade300,
                        ),
                        _buildInfoColumn(
                          context,
                          localizations.daysRemaining,
                          daysRemaining < 0
                              ? '${daysRemaining.abs()} overdue'
                              : '$daysRemaining',
                          daysRemaining < 0 ? Colors.red : Colors.purple,
                        ),
                      ],
                    ),

                    // Status badge
                    if (!currentProfile.isCompleted) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: (isOnTrack ? Colors.green : Colors.orange)
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isOnTrack
                                  ? Icons.trending_up
                                  : Icons.trending_down,
                              size: 16,
                              color: isOnTrack ? Colors.green : Colors.orange,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isOnTrack
                                  ? localizations.onTrack
                                  : localizations.behind,
                              style: TextStyle(
                                color: isOnTrack ? Colors.green : Colors.orange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Completed badge
                    if (currentProfile.isCompleted) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.check_circle,
                              size: 16,
                              color: Colors.green,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              localizations.goalReached,
                              style: const TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Deadline info
            Card(
              child: ListTile(
                leading: const Icon(Icons.event, color: Colors.blue),
                title: Text(localizations.deadline),
                subtitle: Text(
                  DateFormat('MMMM dd, yyyy').format(currentProfile.deadline),
                ),
              ),
            ),

            // Note
            if (currentProfile.note.isNotEmpty) ...[
              const SizedBox(height: 8),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.note, color: Colors.purple),
                  title: const Text('Note'),
                  subtitle: Text(currentProfile.note),
                ),
              ),
            ],
            const SizedBox(height: 20),

            // Quick Actions (only for active profiles)
            if (!currentProfile.isCompleted) ...[
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AddDepositTransactionPage(
                              profileId: currentProfile.id,
                              isDeposit: true,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.add),
                      label: Text(localizations.addDeposit),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: balance > 0
                          ? () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      AddDepositTransactionPage(
                                    profileId: currentProfile.id,
                                    isDeposit: false,
                                    maxWithdraw: balance,
                                  ),
                                ),
                              );
                            }
                          : null,
                      icon: const Icon(Icons.remove),
                      label: Text(localizations.withdraw),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],

            // Transactions list
            Text(
              localizations.history,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),

            if (transactions.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.receipt_long,
                          size: 48,
                          color: isDarkMode
                              ? Colors.grey.shade600
                              : Colors.grey.shade300,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No transactions yet',
                          style: TextStyle(
                            color: isDarkMode
                                ? Colors.grey.shade400
                                : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: transactions.length,
                itemBuilder: (context, index) {
                  final transaction = transactions[index];
                  return DepositTransactionCard(
                    transaction: transaction,
                    onDelete: () => _showDeleteTransactionDialog(
                        context, transaction, depositProvider),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoColumn(
      BuildContext context, String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
        ),
      ],
    );
  }

  void _showDeleteDialog(BuildContext context, DepositProfile profile) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Profile'),
        content: Text(
            'Are you sure you want to delete "${profile.name}"? This will also delete all transactions for this profile.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final depositProvider =
                  Provider.of<DepositProvider>(context, listen: false);
              await depositProvider.deleteProfile(profile.id);
              if (context.mounted) {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Go back to dashboard
              }
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteTransactionDialog(BuildContext context,
      DepositTransaction transaction, DepositProvider depositProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: Text(
            'Are you sure you want to delete this ${transaction.isDeposit ? "deposit" : "withdrawal"} of ${transaction.amount.toStringAsFixed(2)}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await depositProvider.deleteTransaction(transaction.id);
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
