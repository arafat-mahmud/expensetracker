import 'package:flutter/material.dart';
import '../models/expense_model.dart';
import '../l10n/app_localizations.dart';
import 'ui/app_ui.dart';

/// Expense category field. Opens a two-step picker: group, then category.
class GroupedCategoryDropdown extends StatelessWidget {
  final String? selectedCategory;
  final Function(String?) onChanged;
  final String labelText;
  final IconData prefixIcon;

  const GroupedCategoryDropdown({
    super.key,
    required this.selectedCategory,
    required this.onChanged,
    this.labelText = 'Category',
    this.prefixIcon = Icons.category,
  });

  static Color _color(String category) =>
      Color(ExpenseCategory.getCategoryColor(category)['color']!);

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final selected = selectedCategory;
    return PickerField(
      label: labelText,
      icon: prefixIcon,
      value: selected == null ? l.selectCategory : l.getCategoryName(selected),
      leading: selected == null
          ? null
          : IconBadge(
              emoji: ExpenseCategory.getIcon(selected),
              color: _color(selected),
              size: 34,
            ),
      onTap: () => _showGroups(context),
    );
  }

  String _groupName(AppLocalizations l, String groupHeader) {
    // Headers look like "🏠 Basic Household Expenses"
    final spaceIndex = groupHeader.indexOf(' ');
    final name = spaceIndex >= 0
        ? groupHeader.substring(spaceIndex + 1).trim()
        : groupHeader;
    return switch (name) {
      'Basic Household Expenses' => l.basicHouseholdExpenses,
      'Daily Living' => l.dailyLiving,
      'Transportation' => l.transportation,
      'Health & Wellness' => l.healthWellness,
      'Education' => l.education,
      'Work & Business' => l.workBusiness,
      'Entertainment & Lifestyle' => l.entertainment,
      'Financial' => l.financialObligations,
      'Personal / Family' => l.specialOccasions,
      'Other' => l.miscellaneous,
      _ => name,
    };
  }

  void _showGroups(BuildContext context) {
    final l = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => _PickerSheet(
        title: l.selectCategory,
        itemCount: ExpenseCategory.groupHeaders.length,
        itemBuilder: (context, index) {
          final header = ExpenseCategory.groupHeaders[index];
          final categories = ExpenseCategory.getCategoriesForGroup(header);
          final containsSelected = categories.contains(selectedCategory);
          return _PickerRow(
            leading: IconBadge(
              emoji: header.split(' ').first,
              color: _color(categories.first),
            ),
            title: _groupName(l, header),
            subtitle: '${categories.length} ${l.categoriesAvailable}',
            highlighted: containsSelected,
            onTap: () {
              Navigator.pop(sheetContext);
              _showCategories(context, header);
            },
          );
        },
      ),
    );
  }

  void _showCategories(BuildContext context, String groupHeader) {
    final l = AppLocalizations.of(context);
    final categories = ExpenseCategory.getCategoriesForGroup(groupHeader);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => _PickerSheet(
        title: _groupName(l, groupHeader),
        onBack: () {
          Navigator.pop(sheetContext);
          _showGroups(context);
        },
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          return _PickerRow(
            leading: IconBadge(
              emoji: ExpenseCategory.getIcon(category),
              color: _color(category),
            ),
            title: l.getCategoryName(category),
            selected: category == selectedCategory,
            onTap: () {
              onChanged(category);
              Navigator.pop(sheetContext);
            },
          );
        },
      ),
    );
  }
}

/// Bottom sheet body shared by the category pickers
class _PickerSheet extends StatelessWidget {
  const _PickerSheet({
    required this.title,
    required this.itemCount,
    required this.itemBuilder,
    this.onBack,
  });

  final String title;
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      minChildSize: 0.45,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(onBack == null ? 24 : 8, 0, 24, 8),
            child: Row(
              children: [
                if (onBack != null)
                  IconButton(
                    onPressed: onBack,
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              itemCount: itemCount,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: itemBuilder,
            ),
          ),
        ],
      ),
    );
  }
}

class _PickerRow extends StatelessWidget {
  const _PickerRow({
    required this.leading,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.selected = false,
    this.highlighted = false,
  });

  final Widget leading;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final bool selected;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final active = selected || highlighted;
    return Material(
      color: active ? scheme.primaryContainer : scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: active
              ? scheme.primary.withValues(alpha: 0.4)
              : scheme.outlineVariant,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              leading,
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: textTheme.titleSmall?.copyWith(
                        color: active ? scheme.onPrimaryContainer : null,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: textTheme.bodySmall
                            ?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                  ],
                ),
              ),
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.chevron_right_rounded,
                color: selected ? scheme.primary : scheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Single-step income category picker (same look as the expense picker)
class CategoryPickerSheet {
  static void showFlat(
    BuildContext context, {
    required String title,
    required List<String> categories,
    required String? selected,
    required String Function(String) icon,
    required Color Function(String) color,
    required ValueChanged<String> onSelected,
  }) {
    final l = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => _PickerSheet(
        title: title,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          return _PickerRow(
            leading: IconBadge(emoji: icon(category), color: color(category)),
            title: l.getCategoryName(category),
            selected: category == selected,
            onTap: () {
              onSelected(category);
              Navigator.pop(sheetContext);
            },
          );
        },
      ),
    );
  }
}
