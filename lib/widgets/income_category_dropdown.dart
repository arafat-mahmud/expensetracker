import 'package:flutter/material.dart';
import '../models/expense_model.dart';
import '../l10n/app_localizations.dart';
import 'grouped_category_dropdown.dart';
import 'ui/app_ui.dart';

/// Income category field with a single-step picker
class IncomeCategoryDropdown extends StatelessWidget {
  final String? selectedCategory;
  final Function(String?) onChanged;
  final String labelText;
  final IconData prefixIcon;

  const IncomeCategoryDropdown({
    super.key,
    required this.selectedCategory,
    required this.onChanged,
    this.labelText = 'Income Category',
    this.prefixIcon = Icons.trending_up,
  });

  static Color _color(String category) =>
      Color(IncomeCategory.getCategoryColor(category)['color']!);

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final selected = selectedCategory;
    return PickerField(
      label: labelText,
      icon: prefixIcon,
      value: selected == null
          ? l.selectIncomeCategory
          : l.getCategoryName(selected),
      leading: selected == null
          ? null
          : IconBadge(
              emoji: IncomeCategory.getIcon(selected),
              color: _color(selected),
              size: 34,
            ),
      onTap: () => CategoryPickerSheet.showFlat(
        context,
        title: l.selectIncomeCategory,
        categories: IncomeCategory.all,
        selected: selected,
        icon: IncomeCategory.getIcon,
        color: _color,
        onSelected: onChanged,
      ),
    );
  }
}
