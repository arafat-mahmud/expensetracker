import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/mode_provider.dart';
import '../../theme/app_theme.dart';

/// Bottom navigation shared by the three top-level screens
class AppNavigationBar extends StatelessWidget {
  const AppNavigationBar({super.key, required this.currentIndex});

  final int currentIndex;

  // '/' and '/history' open the savings screens in savings mode
  static const _routes = ['/', '/history', '/settings'];

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final savings = Provider.of<ModeProvider>(context).isDepositMode;
    final scheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
      ),
      child: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          if (index != currentIndex) {
            Navigator.pushReplacementNamed(context, _routes[index]);
          }
        },
        destinations: [
          NavigationDestination(
            icon: Icon(savings
                ? Icons.savings_outlined
                : Icons.space_dashboard_outlined),
            selectedIcon: Icon(
                savings ? Icons.savings_rounded : Icons.space_dashboard_rounded),
            label: l.dashboard,
          ),
          NavigationDestination(
            icon: const Icon(Icons.receipt_long_outlined),
            selectedIcon: const Icon(Icons.receipt_long_rounded),
            label: l.history,
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings_rounded),
            label: l.settings,
          ),
        ],
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(
    this.title, {
    super.key,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          if (actionLabel != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              child: Text(actionLabel!),
            ),
        ],
      ),
    );
  }
}

/// Rounded tinted square holding an icon or an emoji
class IconBadge extends StatelessWidget {
  const IconBadge({
    super.key,
    this.icon,
    this.emoji,
    required this.color,
    this.size = 44,
  });

  final IconData? icon;
  final String? emoji;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(size * 0.32),
      ),
      alignment: Alignment.center,
      child: emoji != null
          ? Text(emoji!, style: TextStyle(fontSize: size * 0.46))
          : Icon(icon, color: color, size: size * 0.5),
    );
  }
}

/// Card with optional tap handling and the standard inner padding
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.color,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

class HeroStat {
  const HeroStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color accent;
}

/// Brand-gradient summary card (balance on the dashboards)
class HeroSummaryCard extends StatelessWidget {
  const HeroSummaryCard({
    super.key,
    required this.label,
    required this.amount,
    this.badge,
    this.stats = const [],
  });

  final String label;
  final String amount;
  final Widget? badge;
  final List<HeroStat> stats;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.blue.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Soft light glows, as on the sign-in screen
            Positioned(
              top: -70,
              right: -50,
              child: _Glow(size: 200, color: AppColors.sky, opacity: 0.35),
            ),
            Positioned(
              bottom: -90,
              left: -60,
              child: _Glow(size: 200, color: AppColors.violet, opacity: 0.25),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          label,
                          style: textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.75),
                          ),
                        ),
                      ),
                      if (badge != null) badge!,
                    ],
                  ),
                  const SizedBox(height: 6),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      amount,
                      style: textTheme.headlineLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  if (stats.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        for (var i = 0; i < stats.length; i++) ...[
                          if (i > 0) const SizedBox(width: 10),
                          Expanded(child: _HeroStatTile(stat: stats[i])),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroStatTile extends StatelessWidget {
  const _HeroStatTile({required this.stat});

  final HeroStat stat;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: stat.accent.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(stat.icon, size: 16, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stat.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.labelSmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    stat.value,
                    style: textTheme.titleSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.size, required this.color, required this.opacity});

  final double size;
  final Color color;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [
          color.withValues(alpha: opacity),
          color.withValues(alpha: 0),
        ]),
      ),
    );
  }
}

/// Small white chip on a hero card (e.g. "Surplus", a growth figure)
class HeroBadge extends StatelessWidget {
  const HeroBadge({super.key, required this.label, this.icon});

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: Colors.white),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

/// Coloured status pill (on-track, overdue, completed…)
class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.label,
    required this.color,
    this.icon,
  });

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Icon + label + value tile inside cards
class MetricTile extends StatelessWidget {
  const MetricTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: [
          IconBadge(icon: icon, color: color, size: 36),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.labelSmall
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
    this.compact = false,
  });

  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  /// Smaller variant for use inside cards
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: 24, vertical: compact ? 20 : 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconBadge(
              icon: icon, color: scheme.primary, size: compact ? 52 : 72),
          SizedBox(height: compact ? 12 : 18),
          Text(
            title,
            textAlign: TextAlign.center,
            style: (compact ? textTheme.titleSmall : textTheme.titleMedium)
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          if (message != null) ...[
            const SizedBox(height: 6),
            Text(
              message!,
              textAlign: TextAlign.center,
              style:
                  textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
          if (action != null) ...[
            const SizedBox(height: 20),
            action!,
          ],
        ],
      ),
    );
  }
}

/// Grouped list of settings rows inside one card
class SettingsGroup extends StatelessWidget {
  const SettingsGroup({super.key, this.title, required this.children});

  final String? title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null)
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              title!,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: scheme.onSurfaceVariant,
                    letterSpacing: 0.2,
                  ),
            ),
          ),
        Card(
          child: Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) const Divider(indent: 68),
                children[i],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class SettingsTile extends StatelessWidget {
  const SettingsTile({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      minVerticalPadding: 12,
      leading: IconBadge(icon: icon, color: iconColor, size: 38),
      title: Text(
        title,
        style: destructive ? TextStyle(color: scheme.error) : null,
      ),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing: trailing ??
          (onTap == null
              ? null
              : Icon(Icons.chevron_right_rounded,
                  color: scheme.onSurfaceVariant)),
      onTap: onTap,
    );
  }
}

/// Read-only field that opens a picker (date, category…) when tapped
class PickerField extends StatelessWidget {
  const PickerField({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
    this.leading,
    this.trailingText,
    this.showChevron = true,
  });

  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  /// Off for narrow, side-by-side fields so the value has room
  final bool showChevron;

  /// Replaces the icon, e.g. with a category emoji
  final Widget? leading;
  final String? trailingText;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final valueStyle = textTheme.bodyLarge?.copyWith(
      fontWeight: FontWeight.w500,
      color: scheme.onSurface,
    );
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.fieldRadius),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: leading == null
              ? Icon(icon)
              : Padding(
                  padding: const EdgeInsets.only(left: 12, right: 8),
                  child: leading,
                ),
          prefixIconConstraints:
              const BoxConstraints(minWidth: 48, minHeight: 48),
          suffixIcon:
              showChevron ? const Icon(Icons.expand_more_rounded) : null,
        ),
        child: Row(
          children: [
            Expanded(
              child: showChevron
                  ? Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: valueStyle,
                    )
                  // Narrow side-by-side fields (dates) shrink the value to
                  // fit rather than cut it off, e.g. long Bengali month names
                  : FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(value, maxLines: 1, style: valueStyle),
                    ),
            ),
            if (trailingText != null)
              Text(
                trailingText!,
                style: textTheme.bodySmall
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
          ],
        ),
      ),
    );
  }
}

/// Large centred amount input with the taka sign, tinted by [color]
class AmountField extends StatelessWidget {
  const AmountField({
    super.key,
    required this.controller,
    required this.label,
    required this.color,
    this.validator,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final String label;
  final Color color;
  final FormFieldValidator<String>? validator;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final amountStyle = textTheme.headlineMedium?.copyWith(
      fontWeight: FontWeight.w700,
      color: color,
    );
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: textTheme.labelLarge?.copyWith(color: color),
          ),
          // The taka sign and the number stay together, centred
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 12, right: 4),
                child: Text('৳', style: amountStyle),
              ),
              IntrinsicWidth(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 80),
                  child: TextFormField(
                    controller: controller,
                    autofocus: autofocus,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    style: amountStyle,
                    cursorColor: color,
                    decoration: InputDecoration(
                      filled: false,
                      hintText: '0.00',
                      hintStyle: amountStyle?.copyWith(
                          color: color.withValues(alpha: 0.35)),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      focusedErrorBorder: InputBorder.none,
                    ),
                    validator: validator,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Full-width primary button tinted with the screen's accent colour
class SubmitButton extends StatelessWidget {
  const SubmitButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.color,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: onPressed,
        style: color == null
            ? null
            : FilledButton.styleFrom(
                backgroundColor: color,
                foregroundColor: AppPalette.of(context).onAccent,
              ),
        icon: Icon(icon),
        label: Text(label),
      ),
    );
  }
}

enum AppSnackType { success, error, info }

void showAppSnack(BuildContext context, String message,
    {AppSnackType type = AppSnackType.success}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  // The snack bar uses the inverse surface, so take accents from the other
  // theme's palette to keep them readable
  final palette = isDark ? AppPalette.light : AppPalette.dark;
  final (icon, color) = switch (type) {
    AppSnackType.success => (Icons.check_circle_rounded, palette.income),
    AppSnackType.error => (Icons.error_rounded, palette.expense),
    AppSnackType.info => (Icons.info_rounded, palette.warning),
  };
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 3),
        content: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
}

/// Confirmation dialog; resolves to true when the user confirms
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  String? cancelLabel,
  IconData icon = Icons.delete_outline_rounded,
  bool destructive = true,
}) async {
  final l = AppLocalizations.of(context);
  final scheme = Theme.of(context).colorScheme;
  final accent = destructive ? scheme.error : scheme.primary;
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      icon: IconBadge(icon: icon, color: accent, size: 52),
      title: Text(title, textAlign: TextAlign.center),
      content: Text(message, textAlign: TextAlign.center),
      actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      actions: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(cancelLabel ?? l.cancel),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: destructive ? scheme.onError : null,
                ),
                onPressed: () => Navigator.pop(context, true),
                child: Text(confirmLabel),
              ),
            ),
          ],
        ),
      ],
    ),
  );
  return result ?? false;
}
