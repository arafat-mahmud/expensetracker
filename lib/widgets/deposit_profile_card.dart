import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../models/deposit_model.dart';
import '../providers/deposit_provider.dart';
import '../theme/app_format.dart';
import '../theme/app_theme.dart';
import 'ui/app_ui.dart';

/// Label, colour and icon describing where a savings goal stands
class GoalStatus {
  const GoalStatus(this.label, this.color, this.icon);

  final String label;
  final Color color;
  final IconData icon;

  factory GoalStatus.of(
    BuildContext context, {
    required bool isCompleted,
    required int daysRemaining,
    required bool isOnTrack,
  }) {
    final l = AppLocalizations.of(context);
    final palette = AppPalette.of(context);
    if (isCompleted) {
      return GoalStatus(
          l.completedLabel, palette.income, Icons.check_circle_rounded);
    }
    if (daysRemaining < 0) {
      return GoalStatus(l.daysOverdue(daysRemaining.abs()), palette.expense,
          Icons.warning_amber_rounded);
    }
    if (isOnTrack) {
      return GoalStatus(l.onTrack, Theme.of(context).colorScheme.primary,
          Icons.trending_up_rounded);
    }
    return GoalStatus(l.behind, palette.warning, Icons.trending_down_rounded);
  }
}

class DepositProfileCard extends StatelessWidget {
  final DepositProfile profile;
  final VoidCallback onTap;

  const DepositProfileCard({
    super.key,
    required this.profile,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final depositProvider = Provider.of<DepositProvider>(context);
    final balance = depositProvider.getProfileBalance(profile.id);
    final progress = depositProvider.getProfileProgress(profile.id);
    final daysRemaining = depositProvider.getDaysRemaining(profile.id);
    final status = GoalStatus.of(
      context,
      isCompleted: profile.isCompleted,
      daysRemaining: daysRemaining,
      isOnTrack: depositProvider.isOnTrack(profile.id),
    );

    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconBadge(icon: Icons.savings_rounded, color: status.color),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleSmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${AppFormat.money(context, balance, decimals: 0)} / ${AppFormat.money(context, profile.targetAmount, decimals: 0)}',
                      style: textTheme.bodySmall
                          ?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Text(
                '${AppFormat.number(context, (progress * 100).round())}%',
                style: textTheme.titleMedium?.copyWith(
                  color: status.color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              color: status.color,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: StatusChip(
                  label: status.label,
                  color: status.color,
                  icon: status.icon,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                profile.isCompleted || daysRemaining < 0
                    ? AppFormat.date(context, profile.deadline)
                    : l.daysLeft(daysRemaining),
                style: textTheme.labelMedium
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
