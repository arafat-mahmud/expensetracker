import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/deposit_model.dart';
import '../../providers/deposit_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_format.dart';
import '../../theme/app_theme.dart';
import '../../widgets/deposit_profile_card.dart';
import '../../widgets/goal_completed_dialog.dart';
import '../../widgets/ui/app_ui.dart';
import '../../services/deposit_pdf_service.dart';
import 'add_deposit_profile_page.dart';
import 'deposit_profile_detail_page.dart';

class DepositDashboardPage extends StatefulWidget {
  const DepositDashboardPage({super.key});

  @override
  State<DepositDashboardPage> createState() => _DepositDashboardPageState();
}

class _DepositDashboardPageState extends State<DepositDashboardPage> {
  @override
  void initState() {
    super.initState();
    // Set up goal completion callback
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final depositProvider =
          Provider.of<DepositProvider>(context, listen: false);
      depositProvider.onGoalCompleted = (profile) {
        if (mounted) {
          final balance = depositProvider.getProfileBalance(profile.id);
          showGoalCompletedDialog(context, profile, balance);
        }
      };

      // Load saved data if needed and listen for changes from other devices
      depositProvider.startCloudSync();
    });
  }

  Future<void> _handleRefresh() async {
    final depositProvider =
        Provider.of<DepositProvider>(context, listen: false);
    depositProvider.loadData();
    // Only (re)starts the live listener if it is not running. No reads otherwise.
    await depositProvider.startCloudSync();
  }

  /// Runs a PDF action behind a progress dialog and reports the outcome
  Future<void> _runPdfAction(Future<void> Function(DepositProvider) action,
      {String? successMessage}) async {
    final depositProvider =
        Provider.of<DepositProvider>(context, listen: false);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
    try {
      await action(depositProvider);
      if (!mounted) return;
      Navigator.pop(context);
      if (successMessage != null) showAppSnack(context, successMessage);
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      showAppSnack(context, '${AppLocalizations.of(context).error}: $e',
          type: AppSnackType.error);
    }
  }

  Future<void> _downloadPdf() => _runPdfAction(
        (provider) => DepositPdfService.generateAndDownloadPdf(
          profiles: provider.profiles,
          transactions: provider.transactions,
          totalBalance: provider.totalBalance,
          totalDeposited: provider.totalDeposited,
          totalWithdrawn: provider.totalWithdrawn,
        ),
        successMessage: AppLocalizations.of(context).fileSaved,
      );

  Future<void> _sharePdf() => _runPdfAction(
        (provider) => DepositPdfService.sharePdf(
          profiles: provider.profiles,
          transactions: provider.transactions,
          totalBalance: provider.totalBalance,
          totalDeposited: provider.totalDeposited,
          totalWithdrawn: provider.totalWithdrawn,
        ),
      );

  void _openProfile(DepositProfile profile) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DepositProfileDetailPage(profile: profile),
      ),
    );
  }

  void _createProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddDepositProfilePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final depositProvider = Provider.of<DepositProvider>(context);
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final palette = AppPalette.of(context);
    final profiles = depositProvider.profiles;

    return Scaffold(
      appBar: AppBar(
        title: Text(l.depositProfiles),
        actions: [
          if (profiles.isNotEmpty)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded),
              onSelected: (value) =>
                  value == 'download' ? _downloadPdf() : _sharePdf(),
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'download',
                  child: Row(
                    children: [
                      Icon(Icons.file_download_outlined,
                          color: scheme.primary),
                      const SizedBox(width: 12),
                      Text(l.downloadPdf),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'share',
                  child: Row(
                    children: [
                      Icon(Icons.ios_share_rounded, color: palette.income),
                      const SizedBox(width: 12),
                      Text(l.sharePdf),
                    ],
                  ),
                ),
              ],
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: profiles.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 40),
                  EmptyState(
                    icon: Icons.savings_rounded,
                    title: l.noProfiles,
                    message: l.createFirstProfile,
                    action: FilledButton.icon(
                      onPressed: _createProfile,
                      icon: const Icon(Icons.add_rounded),
                      label: Text(l.createProfile),
                    ),
                  ),
                ],
              )
            : ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
                children: [
                  HeroSummaryCard(
                    label: l.totalSavings,
                    amount: AppFormat.money(context, depositProvider.totalBalance),
                    badge: HeroBadge(
                      icon: Icons.flag_rounded,
                      label:
                          '${AppFormat.number(context, depositProvider.activeProfiles.length)} ${l.activeGoals}',
                    ),
                    stats: [
                      HeroStat(
                        icon: Icons.south_west_rounded,
                        label: l.saved,
                        value: AppFormat.money(
                            context, depositProvider.totalDeposited,
                            decimals: 0),
                        accent: palette.income,
                      ),
                      HeroStat(
                        icon: Icons.north_east_rounded,
                        label: l.withdrawn,
                        value: AppFormat.money(
                            context, depositProvider.totalWithdrawn,
                            decimals: 0),
                        accent: palette.expense,
                      ),
                    ],
                  ),
                  if (depositProvider.activeProfiles.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    SectionHeader(l.activeGoals),
                    for (final profile in depositProvider.activeProfiles) ...[
                      DepositProfileCard(
                        profile: profile,
                        onTap: () => _openProfile(profile),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ],
                  if (depositProvider.completedProfiles.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    SectionHeader(l.completedGoals),
                    for (final profile in depositProvider.completedProfiles) ...[
                      DepositProfileCard(
                        profile: profile,
                        onTap: () => _openProfile(profile),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ],
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createProfile,
        icon: const Icon(Icons.add_rounded),
        label: Text(l.createProfile),
      ),
      bottomNavigationBar: const AppNavigationBar(currentIndex: 0),
    );
  }
}
