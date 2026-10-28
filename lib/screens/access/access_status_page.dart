import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/admin_config.dart';
import '../../l10n/app_localizations.dart';
import '../../models/account_model.dart';
import '../../providers/account_provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ui/app_ui.dart';

/// Shown instead of the app while the account is being checked, waits for
/// approval, is blocked, or the app is under maintenance. It updates by
/// itself as soon as the administrator changes anything.
///
/// Built above the app's Navigator, so it uses no dialogs or routes.
class AccessStatusPage extends StatelessWidget {
  const AccessStatusPage({super.key, required this.state});

  final AccessState state;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final palette = AppPalette.of(context);
    final accountProvider = Provider.of<AccountProvider>(context);
    final account = accountProvider.account;
    final email = accountProvider.user?.email ?? '';

    void signOut() =>
        Provider.of<AuthProvider>(context, listen: false).signOut();

    if (state == AccessState.loading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 20),
              Text(l.checkingAccount,
                  style: textTheme.bodyMedium
                      ?.copyWith(color: scheme.onSurfaceVariant)),
              const SizedBox(height: 12),
              TextButton(onPressed: signOut, child: Text(l.signOut)),
            ],
          ),
        ),
      );
    }

    final (icon, color, title, message) = switch (state) {
      AccessState.blocked => (
          Icons.block_rounded,
          palette.expense,
          l.blockedTitle,
          l.blockedMessage,
        ),
      AccessState.maintenance => (
          Icons.construction_rounded,
          scheme.primary,
          l.maintenanceTitle,
          accountProvider.config.maintenanceMessage.trim().isNotEmpty
              ? accountProvider.config.maintenanceMessage.trim()
              : l.maintenanceDefaultMessage,
        ),
      _ => (
          Icons.hourglass_top_rounded,
          palette.warning,
          l.pendingTitle,
          l.pendingMessage,
        ),
    };
    final reason = account?.blockedReason?.trim() ?? '';

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: AppColors.navy,
        body: DecoratedBox(
          decoration: const BoxDecoration(gradient: AppColors.heroGradient),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Center(
                              child: IconBadge(
                                  icon: icon, color: color, size: 76)),
                          const SizedBox(height: 20),
                          Text(title,
                              textAlign: TextAlign.center,
                              style: textTheme.headlineSmall),
                          const SizedBox(height: 10),
                          Text(
                            message,
                            textAlign: TextAlign.center,
                            style: textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                              height: 1.5,
                            ),
                          ),
                          if (state == AccessState.blocked &&
                              reason.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: palette.expense.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Text(
                                '${l.reasonLabel}: $reason',
                                style: textTheme.bodyMedium,
                              ),
                            ),
                          ],
                          if (email.isNotEmpty &&
                              state != AccessState.maintenance) ...[
                            const SizedBox(height: 16),
                            Center(
                              child: StatusChip(
                                icon: Icons.account_circle_rounded,
                                label: email,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                          const SizedBox(height: 24),
                          if (state == AccessState.blocked) ...[
                            FilledButton.icon(
                              onPressed: () => launchUrl(Uri.parse(
                                  'mailto:${AdminConfig.supportEmail}'
                                  '?subject=${Uri.encodeComponent('Expense Tracker: $email')}')),
                              icon: const Icon(Icons.mail_outline_rounded),
                              label: Text(l.contactSupport),
                            ),
                            const SizedBox(height: 12),
                          ],
                          OutlinedButton.icon(
                            onPressed: signOut,
                            icon: const Icon(Icons.logout_rounded),
                            label: Text(l.signOut),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
