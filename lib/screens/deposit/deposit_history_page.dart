import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/deposit_model.dart';
import '../../providers/deposit_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_format.dart';
import '../../theme/app_theme.dart';
import '../../widgets/deposit_transaction_card.dart';
import '../../widgets/ui/app_ui.dart';

class DepositHistoryPage extends StatefulWidget {
  const DepositHistoryPage({super.key});

  @override
  State<DepositHistoryPage> createState() => _DepositHistoryPageState();
}

class _DepositHistoryPageState extends State<DepositHistoryPage> {
  String? _selectedProfileId;
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    final depositProvider =
        Provider.of<DepositProvider>(context, listen: false);
    depositProvider.loadData();
    // Only (re)starts the live listener if it is not running. No reads otherwise.
    await depositProvider.startCloudSync();
  }

  @override
  Widget build(BuildContext context) {
    final depositProvider = Provider.of<DepositProvider>(context);
    final l = AppLocalizations.of(context);

    // Filter transactions (the provider sorts them newest first)
    var transactions = depositProvider.transactions;
    if (_selectedProfileId != null) {
      transactions =
          transactions.where((t) => t.profileId == _selectedProfileId).toList();
    }
    final query = _searchQuery.trim().toLowerCase();
    if (query.isNotEmpty) {
      transactions = transactions
          .where((t) =>
              t.note.toLowerCase().contains(query) ||
              t.amount.toString().contains(query) ||
              (depositProvider.getProfileById(t.profileId)?.name ?? '')
                  .toLowerCase()
                  .contains(query))
          .toList();
    }

    final groups = <DateTime, List<DepositTransaction>>{};
    for (final t in transactions) {
      groups
          .putIfAbsent(DateTime(t.date.year, t.date.month, t.date.day), () => [])
          .add(t);
    }

    return Scaffold(
      appBar: AppBar(title: Text(l.depositHistory)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: l.searchTransactions,
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchQuery.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () {
                          FocusScope.of(context).unfocus();
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      ),
              ),
            ),
          ),
          if (depositProvider.profiles.isNotEmpty)
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(l.allProfiles),
                      selected: _selectedProfileId == null,
                      onSelected: (_) =>
                          setState(() => _selectedProfileId = null),
                    ),
                  ),
                  for (final profile in depositProvider.profiles)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        avatar: const Icon(Icons.savings_rounded, size: 16),
                        label: Text(profile.name),
                        selected: _selectedProfileId == profile.id,
                        onSelected: (_) =>
                            setState(() => _selectedProfileId = profile.id),
                      ),
                    ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _handleRefresh,
              child: transactions.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        EmptyState(
                          icon: Icons.receipt_long_rounded,
                          title: l.noTransactions,
                          message:
                              _selectedProfileId != null || query.isNotEmpty
                                  ? l.noMatchingTransactions
                                  : l.startByAddingDeposit,
                        ),
                      ],
                    )
                  : ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                      children: [
                        for (final entry in groups.entries) ...[
                          _DayHeader(day: entry.key, items: entry.value),
                          Card(
                            child: Column(
                              children: [
                                for (var i = 0; i < entry.value.length; i++) ...[
                                  if (i > 0) const Divider(indent: 72),
                                  DepositTransactionCard(
                                    transaction: entry.value[i],
                                    showDate: false,
                                    profileName: depositProvider
                                        .getProfileById(entry.value[i].profileId)
                                        ?.name,
                                    onDelete: () =>
                                        confirmAndDeleteDepositTransaction(
                                      context,
                                      entry.value[i],
                                      depositProvider.deleteTransaction,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ],
                    ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const AppNavigationBar(currentIndex: 1),
    );
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.day, required this.items});

  final DateTime day;
  final List<DepositTransaction> items;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final palette = AppPalette.of(context);

    final now = DateTime.now();
    final label = AppFormat.isSameDay(day, now)
        ? l.today
        : AppFormat.isSameDay(day, now.subtract(const Duration(days: 1)))
            ? l.yesterday
            : AppFormat.longDate(context, day);
    final net = items.fold(
        0.0, (sum, t) => sum + (t.isDeposit ? t.amount : -t.amount));

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: textTheme.labelLarge
                    ?.copyWith(color: scheme.onSurfaceVariant)),
          ),
          Text(
            AppFormat.money(context, net, signed: true),
            style: textTheme.labelLarge?.copyWith(
              color: net >= 0 ? palette.income : scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
