import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/budget_provider.dart';
import '../providers/expense_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/language_provider.dart';
import '../providers/mode_provider.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_format.dart';
import '../theme/app_theme.dart';
import '../widgets/ui/app_ui.dart';
import 'developer_info_screen.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  static const _deleteConfirmation = 'DELETE ALL DATA';

  late final Future<PackageInfo> _packageInfo = PackageInfo.fromPlatform();

  Future<void> _handleRefresh() async {
    final budgetProvider = Provider.of<BudgetProvider>(context, listen: false);
    final expenseProvider =
        Provider.of<ExpenseProvider>(context, listen: false);

    // Reload local data
    budgetProvider.reloadBudget();
    expenseProvider.loadExpenses();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final budgetProvider = Provider.of<BudgetProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);
    final modeProvider = Provider.of<ModeProvider>(context);
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final palette = AppPalette.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l.settings)),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            if (authProvider.isAuthenticated) ...[
              _ProfileCard(
                name: authProvider.getUserDisplayName() ?? l.account,
                email: authProvider.getUserEmail() ?? '',
                photoUrl: authProvider.getUserPhotoURL(),
              ),
              const SizedBox(height: 24),
            ],
            SettingsGroup(
              title: l.general,
              children: [
                SettingsTile(
                  icon: modeProvider.isDepositMode
                      ? Icons.savings_rounded
                      : Icons.account_balance_wallet_rounded,
                  iconColor: scheme.primary,
                  title: l.appMode,
                  subtitle: modeProvider.isDepositMode
                      ? l.depositMode
                      : l.expenseMode,
                  trailing: Switch(
                    value: modeProvider.isDepositMode,
                    onChanged: (_) {
                      modeProvider.toggleMode();
                      Navigator.pushReplacementNamed(context, '/');
                    },
                  ),
                ),
                SettingsTile(
                  icon: Icons.pie_chart_rounded,
                  iconColor: palette.income,
                  title: l.monthlyBudget,
                  subtitle: AppFormat.money(
                      context, budgetProvider.monthlyBudget,
                      decimals: 0),
                  onTap: () => _showBudgetDialog(budgetProvider),
                ),
                SettingsTile(
                  icon: Icons.description_rounded,
                  iconColor: palette.violet,
                  title: l.downloadStatement,
                  subtitle: l.generateStatement,
                  onTap: () => Navigator.pushNamed(context, '/statement'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SettingsGroup(
              title: l.appearance,
              children: [
                SettingsTile(
                  icon: themeProvider.isDarkMode
                      ? Icons.dark_mode_rounded
                      : Icons.light_mode_rounded,
                  iconColor: palette.violet,
                  title: l.darkMode,
                  trailing: Switch(
                    value: themeProvider.isDarkMode,
                    onChanged: (_) => themeProvider.toggleTheme(),
                  ),
                ),
                SettingsTile(
                  icon: Icons.translate_rounded,
                  iconColor: palette.warning,
                  title: l.language,
                  subtitle: languageProvider.languageName,
                  onTap: () => _showLanguagePicker(languageProvider),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SettingsGroup(
              title: l.about,
              children: [
                SettingsTile(
                  icon: Icons.person_rounded,
                  iconColor: scheme.primary,
                  title: l.developerInfo,
                  subtitle: l.developerInfoSubtitle,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const DeveloperInfoScreen()),
                  ),
                ),
                FutureBuilder<PackageInfo>(
                  future: _packageInfo,
                  builder: (context, snapshot) => SettingsTile(
                    icon: Icons.info_rounded,
                    iconColor: scheme.onSurfaceVariant,
                    title: l.version,
                    trailing: Text(
                      snapshot.data?.version ?? '1.0.0',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                  ),
                ),
              ],
            ),
            if (authProvider.isAuthenticated) ...[
              const SizedBox(height: 24),
              SettingsGroup(
                title: l.account,
                children: [
                  SettingsTile(
                    icon: Icons.logout_rounded,
                    iconColor: scheme.error,
                    title: l.signOut,
                    onTap: () => _signOut(authProvider),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 24),
            SettingsGroup(
              title: l.dangerZone,
              children: [
                SettingsTile(
                  icon: Icons.delete_forever_rounded,
                  iconColor: scheme.error,
                  title: l.clearAllData,
                  subtitle: l.clearAllDataSubtitle,
                  destructive: true,
                  onTap: _startPermanentDeletion,
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AppNavigationBar(currentIndex: 2),
    );
  }

  Future<void> _signOut(AuthProvider authProvider) async {
    final l = AppLocalizations.of(context);
    final confirmed = await showConfirmDialog(
      context,
      title: l.signOut,
      message: l.signOutConfirm,
      confirmLabel: l.signOut,
      icon: Icons.logout_rounded,
    );
    if (!confirmed) return;

    await authProvider.signOut();
    if (!mounted) return;
    // Back to the sign-in screen
    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }

  void _showLanguagePicker(LanguageProvider languageProvider) {
    final l = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) {
        final scheme = Theme.of(sheetContext).colorScheme;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
                  child: Text(l.selectLanguage,
                      style: Theme.of(sheetContext).textTheme.titleLarge),
                ),
                for (final language in languageProvider.supportedLanguages)
                  Builder(builder: (context) {
                    final selected =
                        languageProvider.languageCode == language['code'];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: selected
                                ? scheme.primary
                                : scheme.outlineVariant,
                          ),
                        ),
                        tileColor: selected
                            ? scheme.primaryContainer
                            : scheme.surfaceContainerLow,
                        leading: IconBadge(
                          icon: Icons.translate_rounded,
                          color: scheme.primary,
                          size: 38,
                        ),
                        title: Text(language['name']!),
                        trailing: selected
                            ? Icon(Icons.check_circle_rounded,
                                color: scheme.primary)
                            : null,
                        onTap: () {
                          languageProvider.changeLanguage(language['code']!);
                          Navigator.pop(sheetContext);
                        },
                      ),
                    );
                  }),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showBudgetDialog(BudgetProvider budgetProvider) async {
    final l = AppLocalizations.of(context);
    final controller = TextEditingController(
      text: budgetProvider.monthlyBudget.toStringAsFixed(0),
    );
    String? error;

    final budget = await showDialog<double>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          icon: IconBadge(
            icon: Icons.pie_chart_rounded,
            color: AppPalette.of(dialogContext).income,
            size: 52,
          ),
          title: Text(l.setBudget, textAlign: TextAlign.center),
          content: TextField(
            controller: controller,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: l.amount,
              prefixText: '৳ ',
              errorText: error,
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          actions: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: Text(l.cancel),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      final value = AppFormat.parseAmount(controller.text);
                      if (value == null || value <= 0) {
                        setDialogState(() => error = l.enterValidAmount);
                        return;
                      }
                      Navigator.pop(dialogContext, value);
                    },
                    child: Text(l.save),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    controller.dispose();

    if (budget == null || !mounted) return;
    budgetProvider.setMonthlyBudget(budget);
    showAppSnack(context,
        '${l.budgetUpdated} ${AppFormat.money(context, budget, decimals: 0)}');
  }

  /// Three deliberate steps: type the confirmation text, read a final
  /// warning, then a short countdown before anything is deleted
  Future<void> _startPermanentDeletion() async {
    final typed = await _askForConfirmationText();
    if (!typed || !mounted) return;

    final l = AppLocalizations.of(context);
    final confirmed = await showConfirmDialog(
      context,
      title: l.finalWarning,
      message: l.finalWarningMessage,
      confirmLabel: l.deletePermanently,
      cancelLabel: l.keepMyData,
      icon: Icons.warning_amber_rounded,
    );
    if (!confirmed || !mounted) return;

    final expenseProvider =
        Provider.of<ExpenseProvider>(context, listen: false);
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: false,
        pageBuilder: (context, _, __) =>
            _DeletionProgressDialog(expenseProvider: expenseProvider),
      ),
    );
  }

  Future<bool> _askForConfirmationText() async {
    final l = AppLocalizations.of(context);
    final controller = TextEditingController();
    var valid = false;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          final scheme = Theme.of(dialogContext).colorScheme;
          final textTheme = Theme.of(dialogContext).textTheme;
          Widget point(String text) => Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.close_rounded,
                        size: 16, color: scheme.onErrorContainer),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        text,
                        style: textTheme.bodySmall
                            ?.copyWith(color: scheme.onErrorContainer),
                      ),
                    ),
                  ],
                ),
              );

          return AlertDialog(
            icon: IconBadge(
              icon: Icons.delete_forever_rounded,
              color: scheme.error,
              size: 52,
            ),
            title: Text(l.permanentDeletion, textAlign: TextAlign.center),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: scheme.errorContainer,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l.deletionWillTitle,
                          style: textTheme.labelLarge
                              ?.copyWith(color: scheme.onErrorContainer),
                        ),
                        point(l.deletionPointDevice),
                        point(l.deletionPointCloud),
                        point(l.deletionPointRecovery),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(l.typeToConfirm,
                      style: textTheme.bodyMedium
                          ?.copyWith(color: scheme.onSurface)),
                  const SizedBox(height: 10),
                  TextField(
                    controller: controller,
                    textCapitalization: TextCapitalization.characters,
                    decoration:
                        const InputDecoration(hintText: _deleteConfirmation),
                    onChanged: (value) => setDialogState(() =>
                        valid = value.trim() == _deleteConfirmation),
                  ),
                  if (valid)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle_rounded,
                              size: 16,
                              color: AppPalette.of(dialogContext).income),
                          const SizedBox(width: 6),
                          Text(
                            l.confirmTextVerified,
                            style: textTheme.bodySmall?.copyWith(
                                color: AppPalette.of(dialogContext).income),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            actions: [
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(dialogContext, false),
                      child: Text(l.cancel),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: scheme.error,
                        foregroundColor: scheme.onError,
                      ),
                      onPressed: valid
                          ? () => Navigator.pop(dialogContext, true)
                          : null,
                      child: Text(l.continueLabel),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
    controller.dispose();
    return result ?? false;
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.name,
    required this.email,
    required this.photoUrl,
  });

  final String name;
  final String email;
  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(AppTheme.radius),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
            ),
            child: CircleAvatar(
              radius: 28,
              backgroundColor: scheme.primaryContainer,
              foregroundImage:
                  photoUrl == null ? null : NetworkImage(photoUrl!),
              child: Icon(Icons.person_rounded,
                  color: scheme.onPrimaryContainer, size: 28),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.verified_user_rounded,
              color: Colors.white.withValues(alpha: 0.8)),
        ],
      ),
    );
  }
}

class _DeletionProgressDialog extends StatefulWidget {
  final ExpenseProvider expenseProvider;

  const _DeletionProgressDialog({
    required this.expenseProvider,
  });

  @override
  State<_DeletionProgressDialog> createState() =>
      _DeletionProgressDialogState();
}

class _DeletionProgressDialogState extends State<_DeletionProgressDialog> {
  int countdown = 3;
  bool deletionCompleted = false;
  bool deletionStarted = false;
  int deletionTimeElapsed = 0;

  @override
  void initState() {
    super.initState();
    _startDeletionProcess();
  }

  Future<void> _startDeletionProcess() async {
    // Countdown phase
    for (int i = 3; i > 0; i--) {
      if (!mounted) return;
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        setState(() {
          countdown = i - 1;
        });
      }
    }

    // Start deletion
    if (!mounted) return;
    setState(() {
      deletionStarted = true;
      deletionTimeElapsed = 0;
    });

    // Start counting up timer during deletion
    Future(() async {
      while (!deletionCompleted && mounted) {
        await Future.delayed(const Duration(seconds: 1));
        if (mounted && !deletionCompleted) {
          setState(() {
            deletionTimeElapsed++;
          });
        }
      }
    });

    // Perform permanent deletion
    final success = await widget.expenseProvider.permanentlyDeleteAllData();

    if (!mounted) return;

    // Reload budget provider to reflect the reset budget
    Provider.of<BudgetProvider>(context, listen: false).reloadBudget();

    // Show completion
    setState(() {
      deletionCompleted = true;
    });

    // Auto-close after showing completion
    await Future.delayed(const Duration(milliseconds: 1500));

    if (mounted) {
      final l = AppLocalizations.of(context);
      Navigator.of(context).pop(); // Close dialog
      showAppSnack(
        context,
        success ? l.allDataDeleted : l.cloudDeletionPending,
        type: success ? AppSnackType.success : AppSnackType.info,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final palette = AppPalette.of(context);

    final title = deletionCompleted
        ? l.deletionComplete
        : (deletionStarted ? l.deletingData : l.preparingDeletion);
    final detail = deletionCompleted
        ? null
        : (deletionStarted
            ? l.secondsElapsed(deletionTimeElapsed)
            : l.startingIn(countdown));

    return Material(
      type: MaterialType.transparency,
      child: Container(
        color: scheme.scrim.withValues(alpha: 0.55),
        alignment: Alignment.center,
        padding: const EdgeInsets.all(32),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 64,
                  height: 64,
                  child: deletionCompleted
                      ? IconBadge(
                          icon: Icons.check_rounded,
                          color: palette.income,
                          size: 64,
                        )
                      : CircularProgressIndicator(
                          strokeWidth: 5,
                          color: scheme.error,
                        ),
                ),
                const SizedBox(height: 20),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: textTheme.titleMedium,
                ),
                if (detail != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    detail,
                    style: textTheme.bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
