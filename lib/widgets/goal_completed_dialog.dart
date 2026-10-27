import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/deposit_model.dart';
import '../theme/app_format.dart';
import '../theme/app_theme.dart';
import 'ui/app_ui.dart';

class GoalCompletedDialog extends StatefulWidget {
  final DepositProfile profile;
  final double balance;

  const GoalCompletedDialog({
    super.key,
    required this.profile,
    required this.balance,
  });

  @override
  State<GoalCompletedDialog> createState() => _GoalCompletedDialogState();
}

class _GoalCompletedDialogState extends State<GoalCompletedDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    duration: const Duration(milliseconds: 600),
    vsync: this,
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final palette = AppPalette.of(context);

    return Dialog(
      child: FadeTransition(
        opacity: CurvedAnimation(parent: _controller, curve: Curves.easeIn),
        child: ScaleTransition(
          scale: CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconBadge(
                  icon: Icons.celebration_rounded,
                  color: palette.income,
                  size: 80,
                ),
                const SizedBox(height: 20),
                Text(
                  l.goalReached,
                  textAlign: TextAlign.center,
                  style: textTheme.headlineSmall
                      ?.copyWith(color: palette.income),
                ),
                const SizedBox(height: 4),
                Text(
                  l.congratulations,
                  style: textTheme.bodyLarge
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.profile.name,
                  textAlign: TextAlign.center,
                  style: textTheme.titleMedium,
                ),
                const SizedBox(height: 10),
                StatusChip(
                  icon: Icons.savings_rounded,
                  color: palette.income,
                  label: l.amountSaved(
                      AppFormat.money(context, widget.balance, decimals: 0)),
                ),
                const SizedBox(height: 24),
                SubmitButton(
                  label: l.awesome,
                  icon: Icons.thumb_up_alt_rounded,
                  color: palette.income,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Show the dialog
void showGoalCompletedDialog(
    BuildContext context, DepositProfile profile, double balance) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => GoalCompletedDialog(
      profile: profile,
      balance: balance,
    ),
  );
}
