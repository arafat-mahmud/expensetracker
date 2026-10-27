import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/deposit_model.dart';
import '../../providers/deposit_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_format.dart';
import '../../theme/app_theme.dart';
import '../../widgets/deposit_profile_card.dart';
import '../../widgets/deposit_progress_chart.dart';
import '../../widgets/deposit_transaction_card.dart';
import '../../widgets/ui/app_ui.dart';
import 'add_deposit_profile_page.dart';
import 'add_deposit_transaction_page.dart';

class DepositProfileDetailPage extends StatelessWidget {
  final DepositProfile profile;

  const DepositProfileDetailPage({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    final depositProvider = Provider.of<DepositProvider>(context);
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final palette = AppPalette.of(context);

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
    final status = GoalStatus.of(
      context,
      isCompleted: currentProfile.isCompleted,
      daysRemaining: daysRemaining,
      isOnTrack: isOnTrack,
    );

    void open(Widget page) => Navigator.push(
        context, MaterialPageRoute(builder: (context) => page));

    return Scaffold(
      appBar: AppBar(
        title: Text(currentProfile.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: l.editProfile,
            onPressed: () =>
                open(AddDepositProfilePage(profile: currentProfile)),
          ),
          IconButton(
            icon: Icon(Icons.delete_outline_rounded, color: scheme.error),
            tooltip: l.delete,
            onPressed: () => _deleteProfile(context, currentProfile),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          AppCard(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
            child: Column(
              children: [
                DepositProgressChart(
                  progress: progress,
                  size: 150,
                  strokeWidth: 14,
                  isCompleted: currentProfile.isCompleted,
                  isOverdue: daysRemaining < 0,
                  isOnTrack: isOnTrack,
                ),
                const SizedBox(height: 16),
                StatusChip(
                  label: currentProfile.isCompleted ? l.goalReached : status.label,
                  color: status.color,
                  icon: status.icon,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: MetricTile(
                        icon: Icons.account_balance_wallet_rounded,
                        label: l.currentBalance,
                        value: AppFormat.money(context, balance, decimals: 0),
                        color: scheme.primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: MetricTile(
                        icon: Icons.flag_rounded,
                        label: l.targetAmount,
                        value: AppFormat.money(
                            context, currentProfile.targetAmount,
                            decimals: 0),
                        color: palette.income,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: MetricTile(
                        icon: Icons.hourglass_bottom_rounded,
                        label: l.remainingAmount,
                        value: AppFormat.money(context, remaining, decimals: 0),
                        color: palette.warning,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: MetricTile(
                        icon: Icons.event_rounded,
                        label: l.daysRemaining,
                        value: daysRemaining < 0
                            ? l.daysOverdue(daysRemaining.abs())
                            : AppFormat.number(context, daysRemaining),
                        color: daysRemaining < 0
                            ? palette.expense
                            : palette.violet,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (!currentProfile.isCompleted) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: palette.income,
                      foregroundColor: palette.onAccent,
                    ),
                    onPressed: () => open(AddDepositTransactionPage(
                      profileId: currentProfile.id,
                      isDeposit: true,
                    )),
                    icon: const Icon(Icons.add_rounded),
                    label: Text(l.addDeposit),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: palette.expense,
                      side: BorderSide(
                          color: palette.expense.withValues(alpha: 0.5)),
                    ),
                    onPressed: balance > 0
                        ? () => open(AddDepositTransactionPage(
                              profileId: currentProfile.id,
                              isDeposit: false,
                              maxWithdraw: balance,
                            ))
                        : null,
                    icon: const Icon(Icons.remove_rounded),
                    label: Text(l.withdraw),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 24),
          SettingsGroup(
            children: [
              SettingsTile(
                icon: Icons.event_rounded,
                iconColor: scheme.primary,
                title: l.deadline,
                subtitle: AppFormat.date(context, currentProfile.deadline),
              ),
              if (currentProfile.note.isNotEmpty)
                SettingsTile(
                  icon: Icons.notes_rounded,
                  iconColor: palette.violet,
                  title: l.note,
                  subtitle: currentProfile.note,
                ),
            ],
          ),
          const SizedBox(height: 24),
          SectionHeader(l.history),
          Card(
            child: transactions.isEmpty
                ? EmptyState(
                    compact: true,
                    icon: Icons.receipt_long_rounded,
                    title: l.noTransactions,
                    message: l.startByAddingDeposit,
                  )
                : Column(
                    children: [
                      for (var i = 0; i < transactions.length; i++) ...[
                        if (i > 0) const Divider(indent: 72),
                        DepositTransactionCard(
                          transaction: transactions[i],
                          onDelete: () => confirmAndDeleteDepositTransaction(
                            context,
                            transactions[i],
                            depositProvider.deleteTransaction,
                          ),
                        ),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteProfile(
      BuildContext context, DepositProfile profile) async {
    final l = AppLocalizations.of(context);
    final confirmed = await showConfirmDialog(
      context,
      title: l.deleteProfileTitle,
      message: l.deleteProfileMessage,
      confirmLabel: l.delete,
    );
    if (!confirmed || !context.mounted) return;
    await Provider.of<DepositProvider>(context, listen: false)
        .deleteProfile(profile.id);
    if (context.mounted) Navigator.pop(context); // Back to the dashboard
  }
}
