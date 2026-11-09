import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BrandColors {
  static const orange = Color(0xFFFF6A00); // AG_UI2: один оранжевый во всём приложении
  static const blue = Color(0xFF2057DF);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceMuted = Color(0xFFF5F5F7);
  static const textPrimary = Color(0xFF1A1A1A);
  static const textSecondary = Color(0xFF6B6B6B);
  static const divider = Color(0xFFE5E5EA);

  static const orangeSoft = Color(0xFFFFF1E7);
  static const background = Color(0xFFF6F7F9);
}

ThemeData buildAppTheme() => _buildTheme(Brightness.light);

ThemeData buildDarkAppTheme() => _buildTheme(Brightness.dark);

ThemeData _buildTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;

  final background = isDark ? const Color(0xFF0F1013) : BrandColors.background;
  final surface = isDark ? const Color(0xFF181A1F) : BrandColors.surface;
  final surfaceMuted =
      isDark ? const Color(0xFF22242B) : const Color(0xFFF0F2F5);
  final textPrimary =
      isDark ? const Color(0xFFF5F5F7) : BrandColors.textPrimary;
  final textSecondary =
      isDark ? const Color(0xFFA9ABB3) : BrandColors.textSecondary;
  final divider = isDark ? const Color(0xFF2C2E36) : const Color(0xFFE6E8EC);
  final accentBlue = isDark ? const Color(0xFF7C9CFF) : BrandColors.blue;

  final colorScheme = ColorScheme.fromSeed(
    seedColor: BrandColors.orange,
    brightness: brightness,
  ).copyWith(
    primary: BrandColors.orange,
    onPrimary: Colors.white,
    secondary: BrandColors.blue,
    onSecondary: Colors.white,
    surface: surface,
    onSurface: textPrimary,
    onSurfaceVariant: textSecondary,
    outline: divider,
    outlineVariant: divider,
    surfaceContainerHighest: surfaceMuted,
    surfaceTint: Colors.transparent,
  );

  final base = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: colorScheme,
  );

  final textTheme = base.textTheme
      .apply(bodyColor: textPrimary, displayColor: textPrimary)
      .copyWith(
        headlineLarge: base.textTheme.headlineLarge?.copyWith(
          letterSpacing: -0.6,
          fontWeight: FontWeight.w800,
        ),
        headlineMedium: base.textTheme.headlineMedium?.copyWith(
          letterSpacing: -0.5,
          fontWeight: FontWeight.w800,
        ),
        headlineSmall: base.textTheme.headlineSmall?.copyWith(
          letterSpacing: -0.4,
          fontWeight: FontWeight.w800,
        ),
        titleLarge: base.textTheme.titleLarge?.copyWith(
          letterSpacing: -0.3,
          fontWeight: FontWeight.w700,
        ),
        titleMedium: base.textTheme.titleMedium?.copyWith(
          letterSpacing: -0.15,
          fontWeight: FontWeight.w700,
        ),
        titleSmall: base.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w700,
        ),
        bodyLarge: base.textTheme.bodyLarge?.copyWith(height: 1.4),
        bodyMedium: base.textTheme.bodyMedium?.copyWith(height: 1.4),
        bodySmall: base.textTheme.bodySmall?.copyWith(
          height: 1.3,
          color: textSecondary,
        ),
      );

  final buttonShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(16),
  );
  const buttonText = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.1,
  );

  return base.copyWith(
    // AG_UI2: плавные переходы между экранами + жест «назад» Android
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
      },
    ),
    scaffoldBackgroundColor: background,
    textTheme: textTheme,
    dividerColor: divider,
    splashFactory: InkRipple.splashFactory,
    splashColor: BrandColors.orange.withValues(alpha: 0.12),
    highlightColor: Colors.transparent,
    hoverColor: BrandColors.orange.withValues(alpha: 0.06),

    appBarTheme: AppBarTheme(
      backgroundColor: background,
      foregroundColor: textPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      ),
      titleTextStyle: TextStyle(
        color: textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.4,
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: BrandColors.orange,
        foregroundColor: Colors.white,
        disabledBackgroundColor: BrandColors.orange.withValues(alpha: 0.35),
        disabledForegroundColor: Colors.white.withValues(alpha: 0.7),
        minimumSize: const Size(0, 50),
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: buttonShape,
        textStyle: buttonText,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: BrandColors.orange,
        foregroundColor: Colors.white,
        minimumSize: const Size(0, 50),
        shape: buttonShape,
        textStyle: buttonText,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: accentBlue,
        minimumSize: const Size(0, 50),
        side: BorderSide(color: accentBlue.withValues(alpha: 0.4), width: 1.2),
        shape: buttonShape,
        textStyle: buttonText,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: BrandColors.orange,
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),

    cardTheme: CardThemeData(
      color: surface,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: divider, width: 1),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: isDark ? surfaceMuted : surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: divider, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: BrandColors.orange, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.6),
      ),
      labelStyle: TextStyle(color: textSecondary),
      hintStyle: TextStyle(color: textSecondary, fontSize: 14),
    ),

    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: surface,
      surfaceTintColor: Colors.transparent,
      modalBackgroundColor: surface,
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),

    dialogTheme: DialogThemeData(
      backgroundColor: surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      titleTextStyle: TextStyle(
        color: textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.3,
      ),
    ),

    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: isDark ? const Color(0xFF2A2C34) : const Color(0xFF1F2126),
      contentTextStyle: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w600,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),

    chipTheme: ChipThemeData(
      backgroundColor: surface,
      selectedColor: BrandColors.orange.withValues(alpha: 0.14),
      side: BorderSide(color: divider),
      shape: const StadiumBorder(),
      labelStyle: TextStyle(
        color: textPrimary,
        fontWeight: FontWeight.w600,
        fontSize: 13,
      ),
    ),

    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) =>
            states.contains(WidgetState.selected) ? Colors.white : textSecondary,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? BrandColors.orange
            : surfaceMuted,
      ),
      trackOutlineColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? Colors.transparent
            : divider,
      ),
    ),

    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: BrandColors.orange,
      foregroundColor: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),

    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: BrandColors.orange,
    ),

    textSelectionTheme: TextSelectionThemeData(
      cursorColor: BrandColors.orange,
      selectionHandleColor: BrandColors.orange,
      selectionColor: BrandColors.orange.withValues(alpha: 0.25),
    ),

    dividerTheme: DividerThemeData(color: divider, thickness: 1, space: 1),
  );
}