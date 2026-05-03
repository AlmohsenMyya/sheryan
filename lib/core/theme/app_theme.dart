import 'package:flutter/material.dart';
import 'package:sheryan/core/theme/app_colors.dart';
import 'package:sheryan/core/theme/app_design_constants.dart';
import 'package:sheryan/core/theme/app_typography.dart';

class AppTheme {
  // ─── Pure Medical Light ───────────────────────────────────────────────────
  static ThemeData get lightTheme => _build(
    brightness: Brightness.light,
    primary: AppColors.medicalBlue,
    primaryContainer: AppColors.medicalBlueLight,
    onPrimary: Colors.white,
    scaffold: AppColors.scaffoldLight,
    surface: AppColors.surfaceLight,
    surfaceContainer: AppColors.surfaceContainerLight,
    onSurface: AppColors.textOnLight,
    onSurfaceVariant: AppColors.textOnLightSecondary,
    outline: AppColors.borderLight,
    inputFill: AppColors.fieldLight,
    dividerColor: AppColors.borderLight,
    bottomNavBg: Colors.white,
  );

  // ─── Pure Medical Dark ────────────────────────────────────────────────────
  static ThemeData get darkTheme => _build(
    brightness: Brightness.dark,
    primary: AppColors.medicalBlueDark,
    primaryContainer: const Color(0xFF0C4A6E),
    onPrimary: const Color(0xFF0F172A),
    scaffold: AppColors.scaffoldDarkNew,
    surface: AppColors.surfaceDarkNew,
    surfaceContainer: AppColors.surfaceContainerDarkNew,
    onSurface: AppColors.textOnDark,
    onSurfaceVariant: AppColors.textOnDarkSecondary,
    outline: AppColors.borderDark,
    inputFill: const Color(0xFF1E293B),
    dividerColor: AppColors.borderDark,
    bottomNavBg: const Color(0xFF1E293B),
  );

  // ─── Legacy: role-based (now returns lightTheme for all) ──────────────────
  static ThemeData getTheme(dynamic role) => lightTheme;

  // ─── Internal builder ────────────────────────────────────────────────────
  static ThemeData _build({
    required Brightness brightness,
    required Color primary,
    required Color primaryContainer,
    required Color onPrimary,
    required Color scaffold,
    required Color surface,
    required Color surfaceContainer,
    required Color onSurface,
    required Color onSurfaceVariant,
    required Color outline,
    required Color inputFill,
    required Color dividerColor,
    required Color bottomNavBg,
  }) {
    final cs = ColorScheme(
      brightness: brightness,
      primary: primary,
      onPrimary: onPrimary,
      primaryContainer: primaryContainer,
      onPrimaryContainer: brightness == Brightness.light ? AppColors.medicalBlue : AppColors.medicalBlueDark,
      secondary: AppColors.bloodRed,
      onSecondary: Colors.white,
      secondaryContainer: AppColors.bloodRedLight,
      onSecondaryContainer: AppColors.bloodRed,
      error: AppColors.error,
      onError: Colors.white,
      surface: surface,
      onSurface: onSurface,
      onSurfaceVariant: onSurfaceVariant,
      outline: outline,
      outlineVariant: outline.withOpacity(0.5),
      surfaceContainerHighest: surfaceContainer,
      surfaceContainerHigh: surfaceContainer,
      surfaceContainer: surfaceContainer,
      surfaceContainerLow: surfaceContainer,
      surfaceContainerLowest: surface,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: cs,
      scaffoldBackgroundColor: scaffold,

      // ── Text ──────────────────────────────────────────────────────────────
      textTheme: AppTypography.textTheme.apply(
        bodyColor: onSurface,
        displayColor: onSurface,
      ),

      // ── AppBar ────────────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: scaffold,
        elevation: 0,
        scrolledUnderElevation: 1,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        iconTheme: IconThemeData(color: onSurface),
        titleTextStyle: AppTypography.textTheme.titleLarge?.copyWith(color: onSurface),
        shadowColor: outline.withOpacity(0.3),
        shape: Border(bottom: BorderSide(color: outline, width: 0.5)),
      ),

      // ── Card ──────────────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppDesignConstants.borderRadiusMedium,
          side: BorderSide(color: outline, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),

      // ── Elevated Button ───────────────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: AppDesignConstants.borderRadiusMedium,
          ),
          elevation: 0,
          textStyle: AppTypography.textTheme.labelLarge,
        ),
      ),

      // ── Text Button ───────────────────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: primary),
      ),

      // ── Outlined Button ───────────────────────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: BorderSide(color: primary),
          shape: RoundedRectangleBorder(borderRadius: AppDesignConstants.borderRadiusMedium),
        ),
      ),

      // ── Input ─────────────────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFill,
        hintStyle: TextStyle(color: onSurfaceVariant),
        labelStyle: TextStyle(color: onSurfaceVariant),
        prefixIconColor: onSurfaceVariant,
        suffixIconColor: onSurfaceVariant,
        border: OutlineInputBorder(
          borderRadius: AppDesignConstants.borderRadiusMedium,
          borderSide: BorderSide(color: outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppDesignConstants.borderRadiusMedium,
          borderSide: BorderSide(color: outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppDesignConstants.borderRadiusMedium,
          borderSide: BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppDesignConstants.borderRadiusMedium,
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppDesignConstants.borderRadiusMedium,
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),

      // ── Progress ──────────────────────────────────────────────────────────
      progressIndicatorTheme: ProgressIndicatorThemeData(color: primary),

      // ── Divider ───────────────────────────────────────────────────────────
      dividerTheme: DividerThemeData(
        color: dividerColor,
        thickness: 1,
        indent: 0,
        endIndent: 0,
      ),

      // ── Bottom Navigation Bar ─────────────────────────────────────────────
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: bottomNavBg,
        selectedItemColor: primary,
        unselectedItemColor: onSurfaceVariant,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
        showUnselectedLabels: true,
      ),

      // ── Bottom App Bar ─────────────────────────────────────────────────────
      bottomAppBarTheme: BottomAppBarThemeData(color: bottomNavBg),

      // ── ListTile ──────────────────────────────────────────────────────────
      listTileTheme: ListTileThemeData(
        tileColor: surface,
        textColor: onSurface,
        iconColor: onSurfaceVariant,
        shape: RoundedRectangleBorder(
          borderRadius: AppDesignConstants.borderRadiusMedium,
        ),
      ),

      // ── Switch ────────────────────────────────────────────────────────────
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primary;
          return onSurfaceVariant;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primary.withOpacity(0.4);
          return outline;
        }),
      ),

      // ── Dialog ────────────────────────────────────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titleTextStyle: AppTypography.textTheme.titleMedium?.copyWith(color: onSurface),
        contentTextStyle: AppTypography.textTheme.bodyMedium?.copyWith(color: onSurfaceVariant),
      ),

      // ── SnackBar ──────────────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: brightness == Brightness.light ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
        contentTextStyle: TextStyle(color: brightness == Brightness.light ? Colors.white : const Color(0xFF0F172A)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        behavior: SnackBarBehavior.floating,
      ),

      // ── Tab Bar ───────────────────────────────────────────────────────────
      tabBarTheme: TabBarThemeData(
        labelColor: primary,
        unselectedLabelColor: onSurfaceVariant,
        indicatorColor: primary,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        unselectedLabelStyle: const TextStyle(fontSize: 14),
      ),

      // ── Chip ──────────────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: surfaceContainer,
        selectedColor: primaryContainer,
        labelStyle: TextStyle(color: onSurface),
        side: BorderSide(color: outline),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),

      // ── Popup Menu ────────────────────────────────────────────────────────
      popupMenuTheme: PopupMenuThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: outline),
        ),
        textStyle: TextStyle(color: onSurface),
      ),

      // ── Bottom Sheet ──────────────────────────────────────────────────────
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
    );
  }
}
