import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/background_restore_handler.dart';
import '../providers/expense_provider.dart';
import '../providers/budget_provider.dart';
import '../providers/auth_provider.dart';
import '../l10n/app_localizations.dart';
import '../models/expense_model.dart';
import '../theme/app_format.dart';
import '../theme/app_theme.dart';
import '../widgets/category_pie_chart.dart';
import '../widgets/daily_bar_chart.dart';
import '../widgets/expense_card.dart';
import '../widgets/ui/app_ui.dart';
import 'add_expense_page.dart';
import 'add_income_page.dart';
import 'category_report_page.dart';
import 'daily_expense_trend_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  DateTime selectedMonth = DateTime.now();
  bool _isRestoringInBackground = false;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    // Store the current user ID
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _currentUserId = authProvider.user?.uid;

    // Trigger background restore after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _performBackgroundRestore();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Check if the user has changed
    final authProvider = Provider.of<AuthProvider>(context);
    final newUserId = authProvider.user?.uid;

    if (_currentUserId != null &&
        newUserId != null &&
        _currentUserId != newUserId) {
      print('🔄 User changed in DashboardPage, reloading expenses...');
      _currentUserId = newUserId;

      // Reset the background restore flag for the new user
      BackgroundRestoreHandler.resetRestoreFlag();

      // Reload expenses for the new user
      final expenseProvider =
          Provider.of<ExpenseProvider>(context, listen: false);
      expenseProvider.reloadForNewUser();

      // Reload budget for the new user
      final budgetProvider =
          Provider.of<BudgetProvider>(context, listen: false);
      budgetProvider.reloadBudget();

      // Trigger background restore for the new user
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _performBackgroundRestore();
      });
    }
  }

  Future<void> _performBackgroundRestore() async {
    final expenseProvider =
        Provider.of<ExpenseProvider>(context, listen: false);

    // Only show loading indicator if there are no expenses (likely first time user)
    if (expenseProvider.expenses.isEmpty) {
      setState(() {
        _isRestoringInBackground = true;
      });
    }

    await BackgroundRestoreHandler.performAutoRestore(context);

    if (mounted) {
      setState(() {
        _isRestoringInBackground = false;
      });
    }
  }

  Future<void> _handleRefresh() async {
    final expenseProvider =
        Provider.of<ExpenseProvider>(context, listen: false);
    final budgetProvider = Provider.of<BudgetProvider>(context, listen: false);

    // Reload local data
    expenseProvider.loadExpenses();
    budgetProvider.reloadBudget();

    // Changes from other devices already arrive through the live listener,
    // so this only (re)starts it if it is not running. No reads otherwise.
    await expenseProvider.startCloudSync();
    budgetProvider.reloadBudget();

    if (mounted) {
      showAppSnack(context, AppLocalizations.of(context).refresh,
          type: AppSnackType.info);
    }
  }

  @override
  Widget build(BuildContext context) {
    final expenseProvider = Provider.of<ExpenseProvider>(context);
    final budgetProvider = Provider.of<BudgetProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final l = AppLocalizations.of(context);
    final palette = AppPalette.of(context);

    final totalExpense = expenseProvider.getTotalExpenseForMonth(selectedMonth);
    final totalIncome = expenseProvider.getTotalIncomeForMonth(selectedMonth);
    final monthBalance = expenseProvider.getBalanceForMonth(selectedMonth);
    final categoryExpense =
        expenseProvider.getCategoryExpenseForMonth(selectedMonth);
    final lastSevenDays = expenseProvider.getDailyExpenseForLastNDays(7);
    final recent = expenseProvider.expenses.take(5).toList();

    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? l.goodMorning
        : (hour < 17 ? l.goodAfternoon : l.goodEvening);
    final firstName =
        authProvider.getUserDisplayName()?.trim().split(' ').first ?? '';

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 72,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              greeting,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            Text(firstName.isEmpty ? l.appName : firstName),
          ],
        ),
        actions: [
          if (_isRestoringInBackground)
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          _MonthChip(
            label: AppFormat.monthYear(context, selectedMonth),
            onTap: () => _showMonthPicker(context),
          ),
          const SizedBox(width: 8),
          _Avatar(
            photoUrl: authProvider.getUserPhotoURL(),
            onTap: () => Navigator.pushReplacementNamed(context, '/settings'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            HeroSummaryCard(
              label: l.monthBalance,
              amount: AppFormat.money(context, monthBalance),
              badge: HeroBadge(
                icon: monthBalance >= 0
                    ? Icons.trending_up_rounded
                    : Icons.trending_down_rounded,
                label: monthBalance >= 0 ? l.surplus : l.deficit,
              ),
              stats: [
                HeroStat(
                  icon: Icons.south_west_rounded,
                  label: l.income,
                  value: AppFormat.money(context, totalIncome),
                  accent: palette.income,
                ),
                HeroStat(
                  icon: Icons.north_east_rounded,
                  label: l.expense,
                  value: AppFormat.money(context, totalExpense),
                  accent: palette.expense,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _QuickActions(
              actions: [
                _QuickAction(
                  icon: Icons.add_rounded,
                  label: l.addIncome,
                  color: palette.income,
                  onTap: () => _open(const AddIncomePage()),
                ),
                _QuickAction(
                  icon: Icons.remove_rounded,
                  label: l.addExpense,
                  color: palette.expense,
                  onTap: () => _open(const AddExpensePage()),
                ),
                _QuickAction(
                  icon: Icons.description_outlined,
                  label: l.statement,
                  color: Theme.of(context).colorScheme.primary,
                  onTap: () => Navigator.pushNamed(context, '/statement'),
                ),
                _QuickAction(
                  icon: Icons.insights_rounded,
                  label: l.dailyTrends,
                  color: palette.violet,
                  onTap: () => _open(const DailyExpenseTrendPage()),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SectionHeader(l.monthlyBudget),
            _BudgetCard(
              spent: totalExpense,
              budget: budgetProvider.monthlyBudget,
            ),
            const SizedBox(height: 24),
            SectionHeader(l.expensesByCategory),
            categoryExpense.isEmpty
                ? Card(
                    child: EmptyState(
                      compact: true,
                      icon: Icons.donut_large_rounded,
                      title: l.noExpensesThisMonth,
                    ),
                  )
                : _CategoryBreakdown(
                    categoryExpense: categoryExpense,
                    onCategoryTap: (category) =>
                        _open(CategoryReportPage(category: category)),
                  ),
            const SizedBox(height: 24),
            SectionHeader(
              l.dailyExpenseTrend,
              actionLabel: l.view,
              onAction: () => _open(const DailyExpenseTrendPage()),
            ),
            Card(
              child: lastSevenDays.values.every((v) => v == 0)
                  ? EmptyState(
                      compact: true,
                      icon: Icons.bar_chart_rounded,
                      title: l.noExpensesLast7Days,
                    )
                  : Padding(
                      padding: const EdgeInsets.fromLTRB(8, 20, 16, 8),
                      child: SizedBox(
                        height: 190,
                        child: DailyBarChart(
                          dailyExpense: lastSevenDays,
                          days: 7,
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 24),
            SectionHeader(
              l.recentTransactions,
              actionLabel: recent.isEmpty ? null : l.seeAll,
              onAction: () => Navigator.pushReplacementNamed(context, '/history'),
            ),
            Card(
              child: recent.isEmpty
                  ? EmptyState(
                      compact: true,
                      icon: Icons.receipt_long_rounded,
                      title: l.noTransactions,
                    )
                  : Column(
                      children: [
                        for (var i = 0; i < recent.length; i++) ...[
                          if (i > 0) const Divider(indent: 72),
                          ExpenseCard(
                            expense: recent[i],
                            onEdit: () => _open(recent[i].isDebit
                                ? AddExpensePage(expense: recent[i])
                                : AddIncomePage(income: recent[i])),
                            onDelete: () => confirmAndDeleteExpense(
                                context, recent[i], expenseProvider.deleteExpense),
                          ),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AppNavigationBar(currentIndex: 0),
    );
  }

  void _open(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  Future<void> _showMonthPicker(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: AppLocalizations.of(context).selectMonth,
      initialDatePickerMode: DatePickerMode.year,
    );

    if (picked != null && picked != selectedMonth) {
      setState(() {
        selectedMonth = DateTime(picked.year, picked.month, 1);
      });
    }
  }
}

class _MonthChip extends StatelessWidget {
  const _MonthChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface,
      shape: StadiumBorder(side: BorderSide(color: scheme.outlineVariant)),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.calendar_month_rounded,
                  size: 16, color: scheme.primary),
              const SizedBox(width: 6),
              Text(label, style: Theme.of(context).textTheme.labelLarge),
            ],
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.photoUrl, required this.onTap});

  final String? photoUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: CircleAvatar(
        radius: 19,
        backgroundColor: scheme.primaryContainer,
        foregroundImage: photoUrl == null ? null : NetworkImage(photoUrl!),
        child: Icon(Icons.person_rounded,
            size: 20, color: scheme.onPrimaryContainer),
      ),
    );
  }
}

class _QuickAction {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.actions});

  final List<_QuickAction> actions;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final action in actions)
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: action.onTap,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      children: [
                        IconBadge(
                            icon: action.icon, color: action.color, size: 48),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            action.label,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.labelMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _BudgetCard extends StatelessWidget {
  const _BudgetCard({required this.spent, required this.budget});

  final double spent;
  final double budget;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final palette = AppPalette.of(context);

    final ratio = budget > 0 ? spent / budget : 0.0;
    final over = spent > budget;
    final color =
        over ? palette.expense : (ratio >= 0.8 ? palette.warning : palette.income);
    final percent = '${AppFormat.number(context, (ratio * 100).round())}%';
    final left = (budget - spent).abs();

    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: AppFormat.money(context, spent, decimals: 0),
                        style: textTheme.titleLarge,
                      ),
                      TextSpan(
                        text:
                            '  / ${AppFormat.money(context, budget, decimals: 0)}',
                        style: textTheme.bodyMedium
                            ?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              StatusChip(
                label: over ? l.overBudget : '$percent ${l.usedLabel}',
                color: color,
                icon: over ? Icons.warning_amber_rounded : null,
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: ratio.clamp(0.0, 1.0),
              minHeight: 10,
              color: color,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                over ? l.overBudget : l.remaining,
                style: textTheme.bodySmall
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
              const Spacer(),
              Text(
                AppFormat.money(context, left),
                style: textTheme.titleSmall?.copyWith(color: color),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CategoryBreakdown extends StatelessWidget {
  const _CategoryBreakdown({
    required this.categoryExpense,
    required this.onCategoryTap,
  });

  final Map<String, double> categoryExpense;
  final ValueChanged<String> onCategoryTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final total = categoryExpense.values.fold(0.0, (sum, v) => sum + v);
    final entries = categoryExpense.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 20, bottom: 8),
            child: CategoryPieChart(categoryExpense: categoryExpense),
          ),
          for (final entry in entries)
            InkWell(
              onTap: () => onCategoryTap(entry.key),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
                child: Row(
                  children: [
                    IconBadge(
                      emoji: ExpenseCategory.getIcon(entry.key),
                      color: Color(ExpenseCategory.getCategoryColor(
                          entry.key)['color']!),
                      size: 38,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  l.getCategoryName(entry.key),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: textTheme.titleSmall,
                                ),
                              ),
                              Text(
                                AppFormat.money(context, entry.value),
                                style: textTheme.titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: total > 0 ? entry.value / total : 0,
                                    minHeight: 6,
                                    color: Color(ExpenseCategory
                                        .getCategoryColor(entry.key)['color']!),
                                    backgroundColor: scheme.surfaceContainer,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              SizedBox(
                                width: 40,
                                child: Text(
                                  '${AppFormat.number(context, total > 0 ? (entry.value / total * 100).round() : 0)}%',
                                  textAlign: TextAlign.right,
                                  style: textTheme.labelSmall?.copyWith(
                                      color: scheme.onSurfaceVariant),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded,
                        color: scheme.onSurfaceVariant),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
