import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../providers/language_provider.dart';
import '../utils/localization_helper.dart';

// Brand palette for the sign-in screen
const _navy = Color(0xFF0B1437);
const _indigo = Color(0xFF1E3A8A);
const _blue = Color(0xFF2563EB);
const _sky = Color(0xFF60A5FA);
const _violet = Color(0xFF8B5CF6);
const _emerald = Color(0xFF10B981);
const _rose = Color(0xFFF43F5E);

// Height the whole screen needs (below the status bar, above the navigation
// bar) to show the preview card without scrolling, measured at the default
// text size
const double _minHeightWithPreview = 864;

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _intro.value = 1;
    } else if (!_intro.isAnimating && _intro.value == 0) {
      _intro.forward();
    }
  }

  @override
  void dispose() {
    _intro.dispose();
    super.dispose();
  }

  Animation<double> _interval(double begin, double end) => CurvedAnimation(
        parent: _intro,
        curve: Interval(begin, end, curve: Curves.easeOutCubic),
      );

  Future<void> _signIn(AuthProvider auth, AppLocalizations l) async {
    HapticFeedback.lightImpact();
    setState(() => _error = null);

    final success = await auth.signInWithGoogle();
    if (success || !mounted) return;

    final message = auth.errorMessage;
    // Closing the Google account picker is not an error
    if (message == null || message == 'Sign in cancelled') return;
    debugPrint('Sign-in failed: $message');
    final lower = message.toLowerCase();
    setState(() {
      _error = lower.contains('network') || lower.contains('unavailable')
          ? l.signInNetworkError
          : l.signInFailed;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final auth = Provider.of<AuthProvider>(context);
    final wide = MediaQuery.sizeOf(context).width >= 840;

    Widget hero({required bool showPreview}) => _Hero(
          localizations: l,
          showPreview: showPreview,
          intro: _interval(0, 0.6),
          previewIntro: _interval(0.15, 0.75),
          barsIntro: _interval(0.4, 1),
        );
    final topBar = Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Align(
        alignment: Alignment.centerRight,
        child: FadeTransition(
          opacity: _interval(0.3, 0.9),
          child: const _LanguageSwitch(),
        ),
      ),
    );
    Widget panel({required bool floating}) => _SignInPanel(
          localizations: l,
          loading: auth.isLoading,
          error: _error,
          floating: floating,
          onSignIn: () => _signIn(auth, l),
        );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: _navy,
        body: Stack(
          children: [
            const Positioned.fill(child: _HeroBackground()),
            SafeArea(
              bottom: wide,
              child: wide
                  ? Row(
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              topBar,
                              Expanded(
                                child: Center(child: hero(showPreview: true)),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: SizedBox(
                            width: 440,
                            child: Center(
                              child: SingleChildScrollView(
                                child: _slideUp(panel(floating: true)),
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : LayoutBuilder(
                      builder: (context, constraints) => SingleChildScrollView(
                        child: ConstrainedBox(
                          constraints:
                              BoxConstraints(minHeight: constraints.maxHeight),
                          child: IntrinsicHeight(
                            child: Column(
                              children: [
                                topBar,
                                Expanded(
                                  child: Center(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 24, vertical: 8),
                                      // The preview card is decoration;
                                      // drop it where it would not fit
                                      child: hero(
                                        showPreview: constraints.maxHeight -
                                                MediaQuery.paddingOf(context)
                                                    .bottom >=
                                            _minHeightWithPreview,
                                      ),
                                    ),
                                  ),
                                ),
                                _slideUp(panel(floating: false)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _slideUp(Widget child) {
    final animation = _interval(0.3, 1);
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween(begin: const Offset(0, 0.12), end: Offset.zero)
            .animate(animation),
        child: child,
      ),
    );
  }
}

/// Deep gradient with soft light glows and a faint dot texture
class _HeroBackground extends StatelessWidget {
  const _HeroBackground();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_navy, _indigo, _blue],
          stops: [0, 0.6, 1],
        ),
      ),
      child: Stack(
        children: const [
          Positioned(top: -140, right: -90, child: _Glow(340, _sky, 0.35)),
          Positioned(top: 200, left: -160, child: _Glow(320, _violet, 0.28)),
          Positioned(bottom: -60, right: -120, child: _Glow(300, _emerald, 0.16)),
          Positioned.fill(child: CustomPaint(painter: _DotGridPainter())),
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow(this.size, this.color, this.opacity);

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
        gradient: RadialGradient(
          colors: [
            color.withValues(alpha: opacity),
            color.withValues(alpha: 0),
          ],
        ),
      ),
    );
  }
}

class _DotGridPainter extends CustomPainter {
  const _DotGridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.05);
    const gap = 22.0;
    for (var y = gap / 2; y < size.height; y += gap) {
      for (var x = gap / 2; x < size.width; x += gap) {
        canvas.drawCircle(Offset(x, y), 1, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DotGridPainter oldDelegate) => false;
}

class _LanguageSwitch extends StatelessWidget {
  const _LanguageSwitch();

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    Widget segment(String code, String label) {
      final selected = languageProvider.languageCode == code;
      return Semantics(
        button: true,
        selected: selected,
        child: GestureDetector(
          onTap: () {
            if (selected) return;
            HapticFeedback.selectionClick();
            languageProvider.changeLanguage(code);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: selected ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? _navy : Colors.white.withValues(alpha: 0.8),
                fontFamily: code == 'bn' ? 'NotoSansBengali' : null,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(21),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [segment('en', 'EN'), segment('bn', 'বাংলা')],
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({
    required this.localizations,
    required this.showPreview,
    required this.intro,
    required this.previewIntro,
    required this.barsIntro,
  });

  final AppLocalizations localizations;
  final bool showPreview;
  final Animation<double> intro;
  final Animation<double> previewIntro;
  final Animation<double> barsIntro;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FadeTransition(
          opacity: intro,
          child: SlideTransition(
            position: Tween(begin: const Offset(0, -0.08), end: Offset.zero)
                .animate(intro),
            child: Column(
              children: [
                const _AppIconTile(),
                const SizedBox(height: 14),
                Text(
                  localizations.appName,
                  textAlign: TextAlign.center,
                  style: textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  localizations.loginTagline,
                  textAlign: TextAlign.center,
                  style: textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withValues(alpha: 0.72),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (showPreview) ...[
          const SizedBox(height: 20),
          FadeTransition(
            opacity: previewIntro,
            child: ScaleTransition(
              scale: Tween(begin: 0.94, end: 1.0).animate(previewIntro),
              child: _PreviewCard(
                localizations: localizations,
                barsIntro: barsIntro,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _AppIconTile extends StatelessWidget {
  const _AppIconTile();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.7),
            Colors.white.withValues(alpha: 0.15),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(19),
        child: Image.asset(
          'assets/expensetracker.png',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            color: Colors.white,
            child: const Icon(Icons.account_balance_wallet_rounded,
                color: _blue, size: 40),
          ),
        ),
      ),
    );
  }
}

/// Frosted illustration of the product: balance, trend and income/expense.
/// Decorative only, so it is hidden from screen readers.
class _PreviewCard extends StatelessWidget {
  const _PreviewCard({required this.localizations, required this.barsIntro});

  final AppLocalizations localizations;
  final Animation<double> barsIntro;

  static const _barHeights = [0.42, 0.66, 0.5, 0.82, 0.58, 0.95, 0.74];

  // The bundled Bengali font has the taka sign (৳) when the UI font lacks it;
  // Roboto (Android's system font) has the Latin comma it lacks
  static const _takaFallback = ['NotoSansBengali', 'Roboto'];

  @override
  Widget build(BuildContext context) {
    final languageCode = Localizations.localeOf(context).languageCode;
    String amount(int value) => '৳ ${LocalizationHelper.localizeDigits(
          NumberFormat('#,##0', 'en').format(value),
          languageCode,
        )}';
    final textTheme = Theme.of(context).textTheme;

    return ExcludeSemantics(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          localizations.totalBalance,
                          style: textTheme.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _emerald.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.trending_up_rounded,
                                size: 14, color: Color(0xFF6EE7B7)),
                            const SizedBox(width: 4),
                            Text(
                              LocalizationHelper.localizeDigits(
                                  '12.4%', languageCode),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF6EE7B7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    amount(24580),
                    style: textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontFamilyFallback: _takaFallback,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 40,
                    child: AnimatedBuilder(
                      animation: barsIntro,
                      builder: (context, _) => Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          for (var i = 0; i < _barHeights.length; i++) ...[
                            if (i > 0) const SizedBox(width: 6),
                            Expanded(
                              child: FractionallySizedBox(
                                heightFactor:
                                    _barHeights[i] * barsIntro.value + 0.04,
                                alignment: Alignment.bottomCenter,
                                child: _Bar(
                                    highlighted: i == _barHeights.length - 2),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _PreviewStat(
                          icon: Icons.south_west_rounded,
                          label: localizations.income,
                          value: amount(38200),
                          color: _emerald,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _PreviewStat(
                          icon: Icons.north_east_rounded,
                          label: localizations.expense,
                          value: amount(13620),
                          color: _rose,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.highlighted});

  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: highlighted
              ? const [Color(0xFF6EE7B7), _emerald]
              : [
                  Colors.white.withValues(alpha: 0.55),
                  Colors.white.withValues(alpha: 0.15),
                ],
        ),
      ),
    );
  }
}

class _PreviewStat extends StatelessWidget {
  const _PreviewStat({
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
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 16, color: Colors.white),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.labelSmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.65),
                  ),
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.labelLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontFamilyFallback: _PreviewCard._takaFallback,
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

class _SignInPanel extends StatelessWidget {
  const _SignInPanel({
    required this.localizations,
    required this.loading,
    required this.error,
    required this.floating,
    required this.onSignIn,
  });

  final AppLocalizations localizations;
  final bool loading;
  final String? error;

  /// Card beside the hero (wide screens) instead of a bottom sheet
  final bool floating;
  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l = localizations;
    final bottomInset = floating ? 0.0 : MediaQuery.paddingOf(context).bottom;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: floating
            ? BorderRadius.circular(32)
            : const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 32,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(24, 10, 24, 20 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!floating)
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: scheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          SizedBox(height: floating ? 12 : 16),
          Text(
            l.loginTitle,
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l.loginSubtitle,
            style: textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 20),
          _FeatureRow(
            icon: Icons.sync_rounded,
            color: _blue,
            title: l.featureSyncTitle,
            description: l.featureSyncDesc,
          ),
          const SizedBox(height: 12),
          _FeatureRow(
            icon: Icons.verified_user_rounded,
            color: _emerald,
            title: l.featureSecureTitle,
            description: l.featureSecureDesc,
          ),
          const SizedBox(height: 12),
          _FeatureRow(
            icon: Icons.insights_rounded,
            color: _violet,
            title: l.featureInsightsTitle,
            description: l.featureInsightsDesc,
          ),
          const SizedBox(height: 22),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            child: error == null
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ErrorBanner(message: error!),
                  ),
          ),
          _GoogleSignInButton(
            label: l.continueWithGoogle,
            loadingLabel: l.signingIn,
            loading: loading,
            onPressed: onSignIn,
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline_rounded,
                  size: 14, color: scheme.onSurfaceVariant),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  l.secureSignInNote,
                  textAlign: TextAlign.center,
                  style: textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
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

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: scheme.errorContainer,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline_rounded,
                size: 20, color: scheme.onErrorContainer),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onErrorContainer,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Sign-in button following Google's branding guidelines: neutral fill, the
/// four-colour "G" mark and a pill shape (light and dark variants).
class _GoogleSignInButton extends StatelessWidget {
  const _GoogleSignInButton({
    required this.label,
    required this.loadingLabel,
    required this.loading,
    required this.onPressed,
  });

  final String label;
  final String loadingLabel;
  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final fill = dark ? const Color(0xFF131314) : Colors.white;
    final border = dark ? const Color(0xFF8E918F) : const Color(0xFF747775);
    final textColor = dark ? const Color(0xFFE3E3E3) : const Color(0xFF1F1F1F);

    return Semantics(
      button: true,
      enabled: !loading,
      label: loading ? loadingLabel : label,
      excludeSemantics: true,
      child: SizedBox(
        height: 56,
        child: Material(
          color: fill,
          shape: StadiumBorder(side: BorderSide(color: border)),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: loading ? null : onPressed,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 22,
                    height: 22,
                    child: loading
                        ? CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: textColor,
                          )
                        : const CustomPaint(painter: _GoogleLogoPainter()),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      child: Text(
                        loading ? loadingLabel : label,
                        key: ValueKey(loading),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The Google "G" mark, drawn from Google's official 48×48 logo paths
class _GoogleLogoPainter extends CustomPainter {
  const _GoogleLogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 48, size.height / 48);
    final paint = Paint()..isAntiAlias = true;

    canvas.drawPath(
      Path()
        ..moveTo(24, 9.5)
        ..relativeCubicTo(3.54, 0, 6.71, 1.22, 9.21, 3.6)
        ..relativeLineTo(6.85, -6.85)
        ..cubicTo(35.9, 2.38, 30.47, 0, 24, 0)
        ..cubicTo(14.62, 0, 6.51, 5.38, 2.56, 13.22)
        ..relativeLineTo(7.98, 6.19)
        ..cubicTo(12.43, 13.72, 17.74, 9.5, 24, 9.5)
        ..close(),
      paint..color = const Color(0xFFEA4335),
    );
    canvas.drawPath(
      Path()
        ..moveTo(46.98, 24.55)
        ..relativeCubicTo(0, -1.57, -0.15, -3.09, -0.38, -4.55)
        ..lineTo(24, 20)
        ..relativeLineTo(0, 9.02)
        ..relativeLineTo(12.94, 0)
        ..relativeCubicTo(-0.58, 2.96, -2.26, 5.48, -4.78, 7.18)
        ..relativeLineTo(7.73, 6)
        ..relativeCubicTo(4.51, -4.18, 7.09, -10.36, 7.09, -17.65)
        ..close(),
      paint..color = const Color(0xFF4285F4),
    );
    canvas.drawPath(
      Path()
        ..moveTo(10.53, 28.59)
        ..relativeCubicTo(-0.48, -1.45, -0.76, -2.99, -0.76, -4.59)
        ..relativeCubicTo(0, -1.6, 0.27, -3.14, 0.76, -4.59)
        ..relativeLineTo(-7.98, -6.19)
        ..cubicTo(0.92, 16.46, 0, 20.12, 0, 24)
        ..relativeCubicTo(0, 3.88, 0.92, 7.54, 2.56, 10.78)
        ..relativeLineTo(7.97, -6.19)
        ..close(),
      paint..color = const Color(0xFFFBBC05),
    );
    canvas.drawPath(
      Path()
        ..moveTo(24, 48)
        ..relativeCubicTo(6.48, 0, 11.93, -2.13, 15.89, -5.81)
        ..relativeLineTo(-7.73, -6)
        ..relativeCubicTo(-2.15, 1.45, -4.92, 2.3, -8.16, 2.3)
        ..relativeCubicTo(-6.26, 0, -11.57, -4.22, -13.47, -9.91)
        ..relativeLineTo(-7.98, 6.19)
        ..cubicTo(6.51, 42.62, 14.62, 48, 24, 48)
        ..close(),
      paint..color = const Color(0xFF34A853),
    );
  }

  @override
  bool shouldRepaint(_GoogleLogoPainter oldDelegate) => false;
}
