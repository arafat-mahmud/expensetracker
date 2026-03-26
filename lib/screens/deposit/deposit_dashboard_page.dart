import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/deposit_provider.dart';
import '../../providers/language_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/deposit_profile_card.dart';
import '../../widgets/goal_completed_dialog.dart';
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
    });
  }

  Future<void> _handleRefresh() async {
    final depositProvider =
        Provider.of<DepositProvider>(context, listen: false);
    depositProvider.loadData();
    await depositProvider.restoreFromFirestore();
  }

  Future<void> _downloadPdf() async {
    final depositProvider =
        Provider.of<DepositProvider>(context, listen: false);

    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Generate PDF
      await DepositPdfService.generateAndDownloadPdf(
        profiles: depositProvider.profiles,
        transactions: depositProvider.transactions,
        totalBalance: depositProvider.totalBalance,
        totalDeposited: depositProvider.totalDeposited,
        totalWithdrawn: depositProvider.totalWithdrawn,
      );

      // Close loading indicator
      if (mounted) Navigator.pop(context);

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('PDF downloaded successfully!'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      // Close loading indicator
      if (mounted) Navigator.pop(context);

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Text('Error: ${e.toString()}'),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _sharePdf() async {
    final depositProvider =
        Provider.of<DepositProvider>(context, listen: false);

    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Generate and share PDF
      await DepositPdfService.sharePdf(
        profiles: depositProvider.profiles,
        transactions: depositProvider.transactions,
        totalBalance: depositProvider.totalBalance,
        totalDeposited: depositProvider.totalDeposited,
        totalWithdrawn: depositProvider.totalWithdrawn,
      );

      // Close loading indicator
      if (mounted) Navigator.pop(context);
    } catch (e) {
      // Close loading indicator
      if (mounted) Navigator.pop(context);

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Text('Error: ${e.toString()}'),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final depositProvider = Provider.of<DepositProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);
    final localizations = AppLocalizations.of(context);
    final profiles = depositProvider.profiles;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          localizations.depositProfiles,
          style: languageProvider.languageCode == 'bn'
              ? const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                )
              : GoogleFonts.rubik80sFade(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black,
                ),
        ),
        actions: [
          // PDF Download Menu
          if (profiles.isNotEmpty)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                if (value == 'download') {
                  _downloadPdf();
                } else if (value == 'share') {
                  _sharePdf();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'download',
                  child: Row(
                    children: [
                      Icon(Icons.download, color: Colors.blue),
                      SizedBox(width: 8),
                      Text('Download PDF'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'share',
                  child: Row(
                    children: [
                      Icon(Icons.share, color: Colors.green),
                      SizedBox(width: 8),
                      Text('Share PDF'),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: profiles.isEmpty
            ? _buildEmptyState(context, localizations)
            : _buildProfileGrid(context, profiles, depositProvider),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddDepositProfilePage(),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: Text(localizations.createProfile),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      bottomNavigationBar: _buildBottomNavBar(context, localizations),
    );
  }

  Widget _buildEmptyState(
      BuildContext context, AppLocalizations localizations) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.savings_outlined,
                size: 100,
                color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade300,
              ),
              const SizedBox(height: 24),
              Text(
                localizations.noProfiles,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                localizations.createFirstProfile,
                style: TextStyle(
                  color:
                      isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddDepositProfilePage(),
                    ),
                  );
                },
                icon: const Icon(Icons.add),
                label: Text(localizations.createProfile),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileGrid(
      BuildContext context, List profiles, DepositProvider depositProvider) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Card
          _buildSummaryCard(context, depositProvider),
          const SizedBox(height: 20),

          // Active Profiles Section
          if (depositProvider.activeProfiles.isNotEmpty) ...[
            Text(
              'Active Goals',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.85,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: depositProvider.activeProfiles.length,
              itemBuilder: (context, index) {
                final profile = depositProvider.activeProfiles[index];
                return DepositProfileCard(
                  profile: profile,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            DepositProfileDetailPage(profile: profile),
                      ),
                    );
                  },
                );
              },
            ),
          ],

          // Completed Profiles Section
          if (depositProvider.completedProfiles.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              'Completed Goals',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.85,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: depositProvider.completedProfiles.length,
              itemBuilder: (context, index) {
                final profile = depositProvider.completedProfiles[index];
                return DepositProfileCard(
                  profile: profile,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            DepositProfileDetailPage(profile: profile),
                      ),
                    );
                  },
                );
              },
            ),
          ],
          const SizedBox(height: 80), // Space for FAB
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
      BuildContext context, DepositProvider depositProvider) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade400, Colors.blue.shade600],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              'Total Savings',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              '${depositProvider.totalBalance.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.arrow_downward,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Deposited',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: Colors.white),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${depositProvider.totalDeposited.toStringAsFixed(0)}',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.arrow_upward,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Withdrawn',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: Colors.white),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${depositProvider.totalWithdrawn.toStringAsFixed(0)}',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavBar(
      BuildContext context, AppLocalizations localizations) {
    return BottomNavigationBar(
      currentIndex: 0,
      onTap: (index) {
        if (index == 1) {
          Navigator.pushReplacementNamed(context, '/deposit-history');
        } else if (index == 2) {
          Navigator.pushReplacementNamed(context, '/settings');
        }
      },
      items: [
        BottomNavigationBarItem(
          icon: const Icon(Icons.savings),
          label: localizations.dashboard,
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.history),
          label: localizations.history,
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.settings),
          label: localizations.settings,
        ),
      ],
    );
  }
}
