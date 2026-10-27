import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/deposit_model.dart';
import '../theme/app_format.dart';
import '../theme/app_theme.dart';
import 'ui/app_ui.dart';

/// One savings transaction row, meant to sit inside a card
class DepositTransactionCard extends StatelessWidget {
  final DepositTransaction transaction;
  final String? profileName;
  final VoidCallback? onDelete;
  final bool showDate;

  const DepositTransactionCard({
    super.key,
    required this.transaction,
    this.profileName,
    this.onDelete,
    this.showDate = true,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final palette = AppPalette.of(context);

    final isDeposit = transaction.isDeposit;
    final color = isDeposit ? palette.income : palette.expense;
    final subtitle = [
      if (profileName != null) profileName!,
      if (showDate) AppFormat.date(context, transaction.date),
    ].join(' · ');

    return InkWell(
      onLongPress: onDelete,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
        child: Row(
          children: [
            IconBadge(
              icon: isDeposit
                  ? Icons.south_west_rounded
                  : Icons.north_east_rounded,
              color: color,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isDeposit ? l.depositLabel : l.withdrawalLabel,
                    style: textTheme.titleSmall,
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall
                          ?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ],
                  if (transaction.note.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      transaction.note,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              AppFormat.money(context,
                  isDeposit ? transaction.amount : -transaction.amount,
                  signed: true),
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: isDeposit ? palette.income : scheme.onSurface,
              ),
            ),
            if (onDelete != null)
              IconButton(
                icon: Icon(Icons.delete_outline_rounded,
                    size: 20, color: scheme.onSurfaceVariant),
                tooltip: l.delete,
                onPressed: onDelete,
              )
            else
              const SizedBox(width: 12),
          ],
        ),
      ),
    );
  }
}

/// Asks before deleting a savings transaction, then deletes it
Future<void> confirmAndDeleteDepositTransaction(
  BuildContext context,
  DepositTransaction transaction,
  Future<void> Function(String id) delete,
) async {
  final l = AppLocalizations.of(context);
  final confirmed = await showConfirmDialog(
    context,
    title: l.deleteTransactionTitle,
    message: l.deleteCannotUndo,
    confirmLabel: l.delete,
  );
  if (!confirmed || !context.mounted) return;
  await delete(transaction.id);
  if (context.mounted) showAppSnack(context, l.transactionDeleted);
}
