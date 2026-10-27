import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import '../providers/language_provider.dart';
import '../services/localized_statement_service.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_format.dart';
import '../theme/app_theme.dart';
import '../widgets/ui/app_ui.dart';

class StatementPage extends StatefulWidget {
  const StatementPage({super.key});

  @override
  State<StatementPage> createState() => _StatementPageState();
}

class _StatementPageState extends State<StatementPage> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  bool _isGenerating = false;
  String? _period = 'last30Days';

  Future<void> _selectStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _startDate) {
      setState(() {
        _period = null;
        _startDate = picked;
        // Ensure end date is after start date
        if (_endDate.isBefore(_startDate)) {
          _endDate = _startDate;
        }
      });
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate,
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _endDate) {
      setState(() {
        _period = null;
        _endDate = picked;
      });
    }
  }

  void _generatePdfStatement() async {
    setState(() => _isGenerating = true);

    try {
      final expenseProvider =
          Provider.of<ExpenseProvider>(context, listen: false);
      final languageProvider =
          Provider.of<LanguageProvider>(context, listen: false);

      // Get transactions for the period
      final transactions =
          expenseProvider.filterByDateRange(_startDate, _endDate);

      // Calculate totals
      double totalIncome = 0;
      double totalExpense = 0;

      for (var transaction in transactions) {
        if (transaction.isCredit) {
          totalIncome += transaction.amount;
        } else {
          totalExpense += transaction.amount;
        }
      }

      final balance = totalIncome - totalExpense;

      // Use localized statement service
      await LocalizedStatementService.generateLocalizedPdfStatement(
        startDate: _startDate,
        endDate: _endDate,
        transactions: transactions,
        totalIncome: totalIncome,
        totalExpense: totalExpense,
        balance: balance,
        context: context,
        languageCode: languageProvider.languageCode,
      );

      if (mounted) {
        showAppSnack(context, AppLocalizations.of(context).statementGenerated);
      }
    } catch (e) {
      if (mounted) {
        showAppSnack(context, '${AppLocalizations.of(context).error}: $e',
            type: AppSnackType.error);
      }
    } finally {
      // The user may have left the page while the PDF was being generated
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  // Keys stay the same in every language (the chips show translated labels)
  void _selectQuickPeriod(String period) {
    final now = DateTime.now();
    setState(() {
      _period = period;
      _endDate = now;
      switch (period) {
        case 'thisMonth':
          _startDate = DateTime(now.year, now.month, 1);
          break;
        case 'lastMonth':
          _startDate = DateTime(now.year, now.month - 1, 1);
          _endDate = DateTime(now.year, now.month, 0);
          break;
        case 'last3Months':
          _startDate = DateTime(now.year, now.month - 3, now.day);
          break;
        case 'last6Months':
          _startDate = DateTime(now.year, now.month - 6, now.day);
          break;
        case 'thisYear':
          _startDate = DateTime(now.year, 1, 1);
          break;
        case 'last30Days':
          _startDate = now.subtract(const Duration(days: 30));
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final palette = AppPalette.of(context);
    final expenseProvider = Provider.of<ExpenseProvider>(context);
    final transactions =
        expenseProvider.filterByDateRange(_startDate, _endDate);

    double totalIncome = 0;
    double totalExpense = 0;
    for (final transaction in transactions) {
      if (transaction.isCredit) {
        totalIncome += transaction.amount;
      } else {
        totalExpense += transaction.amount;
      }
    }
    final balance = totalIncome - totalExpense;
    // Opening balance is 0 for the statement period
    const openingBalance = 0.0;

    final periods = {
      'last30Days': l.last30Days,
      'thisMonth': l.thisMonth,
      'lastMonth': l.lastMonth,
      'last3Months': l.last3Months,
      'last6Months': l.last6Months,
      'thisYear': l.thisYear,
    };

    return Scaffold(
      appBar: AppBar(title: Text(AppFormat.sentence(l.accountStatement))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          SectionHeader(l.quickSelectPeriod),
          // One swipeable row, running edge to edge past the page padding
          SizedBox(
            height: 44,
            child: OverflowBox(
              maxWidth: MediaQuery.sizeOf(context).width,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: periods.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final period = periods.entries.elementAt(index);
                  return Builder(
                    builder: (chipContext) => Center(
                      child: ChoiceChip(
                        label: Text(period.value),
                        selected: _period == period.key,
                        onSelected: (_) {
                          _selectQuickPeriod(period.key);
                          // Bring a half-hidden chip fully into view; only
                          // this row scrolls, not the page
                          final chip = chipContext.findRenderObject();
                          if (chip != null) {
                            Scrollable.of(chipContext).position.ensureVisible(
                                  chip,
                                  alignment: 0.5,
                                  duration: const Duration(milliseconds: 250),
                                  curve: Curves.easeOut,
                                );
                          }
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 24),
          SectionHeader(l.customDateRange),
          Row(
            children: [
              Expanded(
                child: PickerField(
                  label: l.startDate,
                  value: AppFormat.date(context, _startDate),
                  icon: Icons.event_rounded,
                  showChevron: false,
                  onTap: () => _selectStartDate(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: PickerField(
                  label: l.endDate,
                  value: AppFormat.date(context, _endDate),
                  icon: Icons.event_available_rounded,
                  showChevron: false,
                  onTap: () => _selectEndDate(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SectionHeader(AppFormat.sentence(l.accountSummary)),
          Card(
            child: Column(
              children: [
                Container(
                  color: scheme.surfaceContainerLow,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Icon(Icons.receipt_long_rounded,
                          size: 18, color: scheme.onSurfaceVariant),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l.transactionCount(transactions.length),
                          style: textTheme.labelLarge,
                        ),
                      ),
                      StatusChip(
                        label: balance >= 0 ? l.surplus : l.deficit,
                        color: balance >= 0 ? palette.income : palette.expense,
                      ),
                    ],
                  ),
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _SummaryRow(
                        label: l.openingBalance,
                        value: AppFormat.money(context, openingBalance),
                      ),
                      const SizedBox(height: 12),
                      _SummaryRow(
                        label: l.totalCredits,
                        value: AppFormat.money(context, totalIncome,
                            signed: true),
                        color: palette.income,
                      ),
                      const SizedBox(height: 12),
                      _SummaryRow(
                        label: l.totalDebits,
                        value: AppFormat.money(context, -totalExpense,
                            signed: true),
                        color: palette.expense,
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        child: Divider(),
                      ),
                      _SummaryRow(
                        label: l.closingBalance,
                        value: AppFormat.money(context, balance),
                        color: balance >= 0 ? palette.income : palette.expense,
                        emphasized: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (transactions.isEmpty)
            Card(
              child: EmptyState(
                compact: true,
                icon: Icons.search_off_rounded,
                title: l.noTransactionsFound,
                message: l.noTransactionsMessage,
              ),
            )
          else ...[
            SubmitButton(
              label: l.downloadPdfStatement,
              icon: Icons.picture_as_pdf_rounded,
              onPressed: _isGenerating ? null : _generatePdfStatement,
            ),
            if (_isGenerating)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: LinearProgressIndicator(),
              ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: scheme.primaryContainer.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded,
                      size: 18, color: scheme.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l.statementFormatNote,
                      style: textTheme.bodySmall?.copyWith(
                        color: scheme.onSurface,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.color,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final Color? color;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: (emphasized ? textTheme.titleSmall : textTheme.bodyMedium)
                ?.copyWith(
              color: emphasized ? scheme.onSurface : scheme.onSurfaceVariant,
            ),
          ),
        ),
        Text(
          value,
          style: (emphasized ? textTheme.titleLarge : textTheme.titleSmall)
              ?.copyWith(
            color: color ?? scheme.onSurface,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
