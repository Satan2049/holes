import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Black / blue / white palette — minimal, professional.
abstract final class AppColors {
  static const background = Color(0xFF000000);
  static const surface = Color(0xFF0A0A0C);
  static const surfaceRaised = Color(0xFF12141A);
  static const border = Color(0xFF1E2A3A);
  static const borderFocus = Color(0xFF38BDF8);

  static const primary = Color(0xFF2563EB);
  static const accent = Color(0xFF38BDF8);
  static const accentDim = Color(0xFF1D4ED8);

  static const onBackground = Color(0xFFF8FAFC);
  static const onSurfaceMuted = Color(0xFF94A3B8);
  static const onSurfaceDim = Color(0xFF64748B);

  static const error = Color(0xFFF87171);
  static const success = Color(0xFF34D399);

  // Legacy names used across screens
  static const void950 = background;
  static const void900 = surfaceRaised;
  static const cyber400 = onSurfaceMuted;
  static const cyber500 = primary;
  static const neonCyan = accent;
  static const neonMagenta = error;
  static const neonGreen = success;
}

ThemeData buildAppTheme(Brightness brightness) {
  const scheme = ColorScheme.dark(
    surface: AppColors.surface,
    onSurface: AppColors.onBackground,
    primary: AppColors.primary,
    onPrimary: AppColors.onBackground,
    secondary: AppColors.accent,
    onSecondary: AppColors.background,
    error: AppColors.error,
    onError: AppColors.onBackground,
    outline: AppColors.border,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: scheme,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.onBackground,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: AppColors.surfaceRaised,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      titleTextStyle: TextStyle(
        color: AppColors.onBackground,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
      ),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: AppColors.onBackground, height: 1.45),
      bodyMedium: TextStyle(color: AppColors.onSurfaceMuted, height: 1.4),
      bodySmall: TextStyle(color: AppColors.onSurfaceDim, fontSize: 12),
      titleMedium: TextStyle(
        color: AppColors.onBackground,
        fontWeight: FontWeight.w600,
        fontSize: 16,
      ),
      labelLarge: TextStyle(
        color: AppColors.onBackground,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      ),
    ),
    iconTheme: const IconThemeData(color: AppColors.onSurfaceMuted),
    dividerTheme: const DividerThemeData(color: AppColors.border, thickness: 1),
    cardTheme: CardThemeData(
      color: AppColors.surfaceRaised,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onBackground,
        disabledBackgroundColor: AppColors.border,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.accent,
        side: const BorderSide(color: AppColors.borderFocus),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: AppColors.accent),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return AppColors.accent;
        return AppColors.onSurfaceDim;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.primary.withValues(alpha: 0.45);
        }
        return AppColors.border;
      }),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return AppColors.primary;
        return Colors.transparent;
      }),
      checkColor: WidgetStateProperty.all(AppColors.onBackground),
      side: const BorderSide(color: AppColors.border, width: 1.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      hintStyle: const TextStyle(color: AppColors.onSurfaceDim),
      labelStyle: const TextStyle(color: AppColors.onSurfaceMuted),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.borderFocus, width: 1.5),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.surface,
      modalBackgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.accent,
    ),
  );
}
