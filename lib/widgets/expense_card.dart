import 'package:flutter/material.dart';
import '../models/expense_model.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_format.dart';
import '../theme/app_theme.dart';
import 'ui/app_ui.dart';

/// One transaction row. Rows are meant to sit inside a card, separated by
/// dividers (see the history and category screens).
class ExpenseCard extends StatelessWidget {
  final Expense expense;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  /// Hide the date when the list is already grouped by day
  final bool showDate;

  const ExpenseCard({
    super.key,
    required this.expense,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.showDate = true,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final palette = AppPalette.of(context);

    final isCredit = expense.isCredit;
    final categoryColor = Color(isCredit
        ? IncomeCategory.getCategoryColor(expense.category)['color']!
        : ExpenseCategory.getCategoryColor(expense.category)['color']!);
    final emoji = isCredit
        ? IncomeCategory.getIcon(expense.category)
        : ExpenseCategory.getIcon(expense.category);
    final categoryName = l.getCategoryName(expense.category);
    // Untitled entries are saved with the category key as their title
    final title = expense.title == expense.category ? categoryName : expense.title;
    final subtitle = [
      if (title != categoryName) categoryName,
      if (showDate) AppFormat.date(context, expense.date),
    ].join(' · ');

    return InkWell(
      onTap: onTap ?? onEdit,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
        child: Row(
          children: [
            IconBadge(emoji: emoji, color: categoryColor, size: 44),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
                  if (expense.note.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      expense.note,
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
              AppFormat.money(
                  context, isCredit ? expense.amount : -expense.amount,
                  signed: true),
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: isCredit ? palette.income : scheme.onSurface,
              ),
            ),
            if (onEdit != null || onDelete != null)
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert_rounded,
                    size: 20, color: scheme.onSurfaceVariant),
                tooltip: '',
                onSelected: (value) {
                  if (value == 'edit') onEdit?.call();
                  if (value == 'delete') onDelete?.call();
                },
                itemBuilder: (context) => [
                  if (onEdit != null)
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined,
                              size: 20, color: scheme.onSurfaceVariant),
                          const SizedBox(width: 12),
                          Text(l.edit),
                        ],
                      ),
                    ),
                  if (onDelete != null)
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline_rounded,
                              size: 20, color: scheme.error),
                          const SizedBox(width: 12),
                          Text(l.delete, style: TextStyle(color: scheme.error)),
                        ],
                      ),
                    ),
                ],
              )
            else
              const SizedBox(width: 12),
          ],
        ),
      ),
    );
  }
}

/// Asks before deleting a transaction, then deletes it and confirms
Future<void> confirmAndDeleteExpense(
  BuildContext context,
  Expense expense,
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
  await delete(expense.id);
  if (context.mounted) showAppSnack(context, l.transactionDeleted);
}
