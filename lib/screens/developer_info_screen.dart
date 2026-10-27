import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../widgets/ui/app_ui.dart';

class DeveloperInfoScreen extends StatefulWidget {
  const DeveloperInfoScreen({super.key});

  @override
  State<DeveloperInfoScreen> createState() => _DeveloperInfoScreenState();
}

class _DeveloperInfoScreenState extends State<DeveloperInfoScreen> {
  late final Future<PackageInfo> _packageInfo = PackageInfo.fromPlatform();

  Future<void> _launchUrl(String url) async {
    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      } else {
        debugPrint('Could not launch $url');
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final palette = AppPalette.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l.aboutDeveloper)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
            decoration: BoxDecoration(
              gradient: AppColors.heroGradient,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                Container(
                  width: 84,
                  height: 84,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.15),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.4), width: 2),
                  ),
                  child: Text(
                    'AM',
                    style: textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Arafat Mahmud',
                  style: textTheme.titleLarge?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  l.softwareDeveloper,
                  style: textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SectionHeader(l.appName),
          AppCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconBadge(
                  icon: Icons.account_balance_wallet_rounded,
                  color: scheme.primary,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    l.appDescription,
                    style: textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SettingsGroup(
            title: l.contact,
            children: [
              SettingsTile(
                icon: Icons.mail_rounded,
                iconColor: palette.expense,
                title: l.emailLabel,
                subtitle: 'arafat.mahmud.2001@gmail.com',
                onTap: () => _launchUrl('mailto:arafat.mahmud.2001@gmail.com'),
              ),
              SettingsTile(
                icon: Icons.code_rounded,
                iconColor: scheme.onSurface,
                title: 'GitHub',
                subtitle: 'github.com/arafat-mahmud',
                onTap: () => _launchUrl('https://github.com/arafat-mahmud'),
              ),
              SettingsTile(
                icon: Icons.language_rounded,
                iconColor: scheme.primary,
                title: l.websiteLabel,
                subtitle: 'arafat-mahmud.netlify.app',
                onTap: () => _launchUrl('https://arafat-mahmud.netlify.app'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          FutureBuilder<PackageInfo>(
            future: _packageInfo,
            builder: (context, snapshot) => Text(
              '${l.version} ${snapshot.data?.version ?? '1.0.0'}',
              textAlign: TextAlign.center,
              style: textTheme.bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}
