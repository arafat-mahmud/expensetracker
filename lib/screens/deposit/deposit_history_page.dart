import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/deposit_provider.dart';
import '../../providers/language_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/deposit_transaction_card.dart';

class DepositHistoryPage extends StatefulWidget {
  const DepositHistoryPage({super.key});

  @override
  State<DepositHistoryPage> createState() => _DepositHistoryPageState();
}

class _DepositHistoryPageState extends State<DepositHistoryPage> {
  String? _selectedProfileId;
  String _searchQuery = '';

  Future<void> _handleRefresh() async {
    final depositProvider =
        Provider.of<DepositProvider>(context, listen: false);
    depositProvider.loadData();
  }

  @override
  Widget build(BuildContext context) {
    final depositProvider = Provider.of<DepositProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);
    final localizations = AppLocalizations.of(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Filter transactions
    var transactions = depositProvider.transactions;
    if (_selectedProfileId != null) {
      transactions =
          transactions.where((t) => t.profileId == _selectedProfileId).toList();
    }
    if (_searchQuery.isNotEmpty) {
      transactions = transactions
          .where((t) =>
              t.note.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              t.amount.toString().contains(_searchQuery))
          .toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          localizations.depositHistory,
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
      ),
      body: Column(
        children: [
          // Filters
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Search field
                TextField(
                  decoration: InputDecoration(
                    hintText: localizations.search,
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: isDarkMode
                        ? Colors.grey.shade800
                        : Colors.grey.shade100,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
                const SizedBox(height: 12),

                // Profile filter dropdown
                if (depositProvider.profiles.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isDarkMode
                            ? Colors.grey.shade700
                            : Colors.grey.shade300,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedProfileId,
                        hint: Text(localizations.allProfiles),
                        isExpanded: true,
                        items: [
                          DropdownMenuItem<String>(
                            value: null,
                            child: Text(localizations.allProfiles),
                          ),
                          ...depositProvider.profiles.map((profile) {
                            return DropdownMenuItem<String>(
                              value: profile.id,
                              child: Text(profile.name),
                            );
                          }),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedProfileId = value;
                          });
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Transactions list
          Expanded(
            child: RefreshIndicator(
              onRefresh: _handleRefresh,
              child: transactions.isEmpty
                  ? _buildEmptyState(context, localizations)
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: transactions.length,
                      itemBuilder: (context, index) {
                        final transaction = transactions[index];
                        final profile = depositProvider
                            .getProfileById(transaction.profileId);
                        return DepositTransactionCard(
                          transaction: transaction,
                          profileName: profile?.name,
                          onDelete: () => _showDeleteDialog(
                              context, transaction, depositProvider),
                        );
                      },
                    ),
            ),
          ),
        ],
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
                Icons.receipt_long_outlined,
                size: 80,
                color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade300,
              ),
              const SizedBox(height: 24),
              Text(
                localizations.noTransactions,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _selectedProfileId != null || _searchQuery.isNotEmpty
                    ? localizations.noMatchingTransactions
                    : localizations.startByAddingDeposit,
                style: TextStyle(
                  color:
                      isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog(
      BuildContext context, transaction, DepositProvider depositProvider) {
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

  Widget _buildBottomNavBar(
      BuildContext context, AppLocalizations localizations) {
    return BottomNavigationBar(
      currentIndex: 1,
      onTap: (index) {
        if (index == 0) {
          Navigator.pushReplacementNamed(context, '/');
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
