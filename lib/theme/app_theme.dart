import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Brand colours shared by every screen (the sign-in screen uses the same
/// navy-to-blue gradient)
class AppColors {
  static const navy = Color(0xFF0B1437);
  static const indigo = Color(0xFF1E3A8A);
  static const blue = Color(0xFF2563EB);
  static const sky = Color(0xFF60A5FA);
  static const violet = Color(0xFF8B5CF6);

  static const heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [navy, indigo, blue],
    stops: [0, 0.6, 1],
  );
}

/// Semantic colours that Material's ColorScheme has no slot for
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.income,
    required this.expense,
    required this.warning,
    required this.violet,
    required this.onAccent,
  });

  final Color income;
  final Color expense;
  final Color warning;
  final Color violet;

  /// Text/icons on a filled button of an accent colour above (dark mode's
  /// lighter accents need dark text to stay readable)
  final Color onAccent;

  static const light = AppPalette(
    income: Color(0xFF059669),
    expense: Color(0xFFE11D48),
    warning: Color(0xFFD97706),
    violet: Color(0xFF7C3AED),
    onAccent: Colors.white,
  );

  static const dark = AppPalette(
    income: Color(0xFF34D399),
    expense: Color(0xFFFB7185),
    warning: Color(0xFFFBBF24),
    violet: Color(0xFFA78BFA),
    onAccent: AppColors.navy,
  );

  static AppPalette of(BuildContext context) =>
      Theme.of(context).extension<AppPalette>() ?? light;

  @override
  AppPalette copyWith({
    Color? income,
    Color? expense,
    Color? warning,
    Color? violet,
    Color? onAccent,
  }) {
    return AppPalette(
      income: income ?? this.income,
      expense: expense ?? this.expense,
      warning: warning ?? this.warning,
      violet: violet ?? this.violet,
      onAccent: onAccent ?? this.onAccent,
    );
  }

  @override
  AppPalette lerp(AppPalette? other, double t) {
    if (other == null) return this;
    return AppPalette(
      income: Color.lerp(income, other.income, t)!,
      expense: Color.lerp(expense, other.expense, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      violet: Color.lerp(violet, other.violet, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
    );
  }
}

class AppTheme {
  static const radius = 20.0;
  static const fieldRadius = 14.0;

  static ThemeData light(String languageCode) =>
      _build(Brightness.light, languageCode);

  static ThemeData dark(String languageCode) =>
      _build(Brightness.dark, languageCode);

  /// Status bar and navigation bar icons that stay visible on the theme's
  /// background (dark icons on light screens, light icons on dark ones)
  static SystemUiOverlayStyle overlayStyle(Brightness brightness) {
    final scheme = _scheme(brightness);
    final isDark = brightness == Brightness.dark;
    return (isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark)
        .copyWith(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: scheme.surface,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness:
          isDark ? Brightness.light : Brightness.dark,
    );
  }

  static ColorScheme _scheme(Brightness brightness) {
    if (brightness == Brightness.light) {
      return const ColorScheme(
        brightness: Brightness.light,
        primary: AppColors.blue,
        onPrimary: Colors.white,
        primaryContainer: Color(0xFFDBEAFE),
        onPrimaryContainer: Color(0xFF1E3A8A),
        secondary: Color(0xFF475569),
        onSecondary: Colors.white,
        secondaryContainer: Color(0xFFE2E8F0),
        onSecondaryContainer: Color(0xFF0F172A),
        tertiary: Color(0xFF7C3AED),
        onTertiary: Colors.white,
        tertiaryContainer: Color(0xFFEDE9FE),
        onTertiaryContainer: Color(0xFF4C1D95),
        error: Color(0xFFDC2626),
        onError: Colors.white,
        errorContainer: Color(0xFFFEE2E2),
        onErrorContainer: Color(0xFF7F1D1D),
        surface: Colors.white,
        onSurface: Color(0xFF0F172A),
        onSurfaceVariant: Color(0xFF64748B),
        surfaceDim: Color(0xFFE2E8F0),
        surfaceBright: Colors.white,
        surfaceContainerLowest: Colors.white,
        surfaceContainerLow: Color(0xFFF8FAFC),
        surfaceContainer: Color(0xFFF1F5F9),
        surfaceContainerHigh: Color(0xFFE9EEF5),
        surfaceContainerHighest: Color(0xFFE2E8F0),
        outline: Color(0xFFCBD5E1),
        outlineVariant: Color(0xFFE5EAF1),
        shadow: Colors.black,
        scrim: Colors.black,
        inverseSurface: Color(0xFF0F172A),
        onInverseSurface: Color(0xFFF1F5F9),
        inversePrimary: AppColors.sky,
        surfaceTint: Colors.transparent,
      );
    }
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xFF60A5FA),
      onPrimary: Color(0xFF0B1437),
      primaryContainer: Color(0xFF1E3A8A),
      onPrimaryContainer: Color(0xFFDBEAFE),
      secondary: Color(0xFF94A3B8),
      onSecondary: Color(0xFF0F172A),
      secondaryContainer: Color(0xFF1E293B),
      onSecondaryContainer: Color(0xFFE2E8F0),
      tertiary: Color(0xFFA78BFA),
      onTertiary: Color(0xFF2E1065),
      tertiaryContainer: Color(0xFF4C1D95),
      onTertiaryContainer: Color(0xFFEDE9FE),
      error: Color(0xFFF87171),
      onError: Color(0xFF450A0A),
      errorContainer: Color(0xFF4C1D1D),
      onErrorContainer: Color(0xFFFECACA),
      surface: Color(0xFF111A2B),
      onSurface: Color(0xFFE5E9F0),
      onSurfaceVariant: Color(0xFF94A3B8),
      surfaceDim: Color(0xFF0A1220),
      surfaceBright: Color(0xFF1E2A40),
      surfaceContainerLowest: Color(0xFF0A1220),
      surfaceContainerLow: Color(0xFF0F1828),
      surfaceContainer: Color(0xFF162033),
      surfaceContainerHigh: Color(0xFF1C2740),
      surfaceContainerHighest: Color(0xFF243049),
      outline: Color(0xFF334155),
      outlineVariant: Color(0xFF1F2A3D),
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: Color(0xFFE5E9F0),
      onInverseSurface: Color(0xFF0F172A),
      inversePrimary: AppColors.blue,
      surfaceTint: Colors.transparent,
    );
  }

  static ThemeData _build(Brightness brightness, String languageCode) {
    final scheme = _scheme(brightness);
    final isDark = brightness == Brightness.dark;
    final background = isDark ? const Color(0xFF0A1220) : const Color(0xFFF4F6FA);

    // Bengali text uses the bundled font; each language falls back to the
    // other's font for characters it lacks (৳ in Roboto, Latin in Bengali)
    final bengali = languageCode == 'bn';
    // Sizes come from the type scale; colours from the theme
    final typography = Typography.material2021();
    final base = (bengali ? typography.tall : typography.englishLike)
        .merge(isDark ? typography.white : typography.black)
        .apply(
      fontFamily: bengali ? 'NotoSansBengali' : null,
      fontFamilyFallback: bengali ? const ['Roboto'] : const ['NotoSansBengali'],
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    );
    final text = base.copyWith(
      headlineLarge: base.headlineLarge?.copyWith(fontWeight: FontWeight.w700),
      headlineMedium: base.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
      headlineSmall: base.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
      titleLarge: base.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      titleMedium: base.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      titleSmall: base.titleSmall?.copyWith(fontWeight: FontWeight.w600),
      labelLarge: base.labelLarge?.copyWith(fontWeight: FontWeight.w600),
    );

    // Filled fields: rounded, no outline, label floating inside the fill,
    // and a coloured line along the bottom when focused
    final fieldBorder = UnderlineInputBorder(
      borderRadius: BorderRadius.circular(fieldRadius),
      borderSide: BorderSide.none,
    );
    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(fieldRadius),
    );
    const buttonPadding = EdgeInsets.symmetric(horizontal: 20, vertical: 16);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      canvasColor: background,
      textTheme: text,
      extensions: [isDark ? AppPalette.dark : AppPalette.light],
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleSpacing: 20,
        titleTextStyle: text.titleLarge?.copyWith(color: scheme.onSurface),
        iconTheme: IconThemeData(color: scheme.onSurface),
        actionsIconTheme: IconThemeData(color: scheme.onSurface),
        systemOverlayStyle: overlayStyle(brightness),
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: scheme.onSurfaceVariant,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        titleTextStyle: text.bodyLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: scheme.onSurface,
        ),
        subtitleTextStyle:
            text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? scheme.surfaceContainer : scheme.surfaceContainer,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: fieldBorder,
        enabledBorder: fieldBorder,
        disabledBorder: fieldBorder,
        focusedBorder: fieldBorder.copyWith(
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        errorBorder: fieldBorder.copyWith(
          borderSide: BorderSide(color: scheme.error, width: 1.5),
        ),
        focusedErrorBorder: fieldBorder.copyWith(
          borderSide: BorderSide(color: scheme.error, width: 2),
        ),
        labelStyle: TextStyle(color: scheme.onSurfaceVariant),
        floatingLabelStyle: TextStyle(color: scheme.primary),
        hintStyle: TextStyle(
            color: scheme.onSurfaceVariant.withValues(alpha: 0.7)),
        prefixIconColor: scheme.onSurfaceVariant,
        suffixIconColor: scheme.onSurfaceVariant,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: buttonShape,
          padding: buttonPadding,
          minimumSize: const Size(64, 52),
          textStyle: text.titleSmall,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          elevation: 0,
          shape: buttonShape,
          padding: buttonPadding,
          minimumSize: const Size(64, 52),
          textStyle: text.titleSmall,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.onSurface,
          side: BorderSide(color: scheme.outline),
          shape: buttonShape,
          padding: buttonPadding,
          minimumSize: const Size(64, 52),
          textStyle: text.titleSmall,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          textStyle: text.labelLarge,
          shape: buttonShape,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 2,
        highlightElevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        extendedTextStyle: text.titleSmall,
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 68,
        elevation: 0,
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: scheme.primaryContainer,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => text.labelMedium?.copyWith(
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
            color: states.contains(WidgetState.selected)
                ? scheme.onSurface
                : scheme.onSurfaceVariant,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? scheme.onPrimaryContainer
                : scheme.onSurfaceVariant,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surface,
        selectedColor: scheme.primaryContainer,
        side: BorderSide(color: scheme.outlineVariant),
        shape: const StadiumBorder(),
        labelStyle: text.labelLarge?.copyWith(color: scheme.onSurface),
        secondaryLabelStyle:
            text.labelLarge?.copyWith(color: scheme.onPrimaryContainer),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        showCheckmark: false,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          backgroundColor: scheme.surface,
          selectedBackgroundColor: scheme.primaryContainer,
          selectedForegroundColor: scheme.onPrimaryContainer,
          foregroundColor: scheme.onSurfaceVariant,
          side: BorderSide(color: scheme.outlineVariant),
          textStyle: text.labelLarge,
          shape: buttonShape,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titleTextStyle: text.titleLarge?.copyWith(color: scheme.onSurface),
        contentTextStyle:
            text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: scheme.outline,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle:
            text.bodyMedium?.copyWith(color: scheme.onInverseSurface),
        actionTextColor: scheme.inversePrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: scheme.outlineVariant),
        ),
        textStyle: text.bodyMedium?.copyWith(color: scheme.onSurface),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.surfaceContainerHighest,
        circularTrackColor: scheme.surfaceContainerHighest,
      ),
      switchTheme: SwitchThemeData(
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Colors.transparent
              : scheme.outline,
        ),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        headerBackgroundColor: scheme.primary,
        headerForegroundColor: scheme.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: scheme.primary,
        unselectedLabelColor: scheme.onSurfaceVariant,
        indicatorColor: scheme.primary,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: scheme.outlineVariant,
        labelStyle: text.titleSmall,
        unselectedLabelStyle: text.titleSmall,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: scheme.inverseSurface,
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: text.bodySmall?.copyWith(color: scheme.onInverseSurface),
      ),
    );
  }
}
