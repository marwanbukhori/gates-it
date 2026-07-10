import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'app_spacing.dart';

abstract final class AppTheme {
  static ThemeData light() {
    final base = ThemeData.light(useMaterial3: true);
    final textTheme = _buildTextTheme(base.textTheme);

    return base.copyWith(
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        primaryContainer: AppColors.primaryContainer,
        onPrimaryContainer: AppColors.textStrong,
        secondary: AppColors.secondary,
        onSecondary: Colors.white,
        secondaryContainer: AppColors.secondaryContainer,
        onSecondaryContainer: AppColors.textStrong,
        tertiary: AppColors.tertiary,
        onTertiary: AppColors.textStrong,
        surface: AppColors.surface,
        onSurface: AppColors.textStrong,
        surfaceContainerHighest: AppColors.surfaceVariant,
        onSurfaceVariant: AppColors.textMuted,
        outline: AppColors.outline,
        error: AppColors.error,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: AppColors.background,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.headlineSmall?.copyWith(
          color: AppColors.textStrong,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.surface,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusL),
          side: const BorderSide(color: AppColors.outline, width: 0.6),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.primary,
        labelStyle: textTheme.labelLarge!.copyWith(color: AppColors.textStrong),
        secondaryLabelStyle: textTheme.labelLarge!.copyWith(color: AppColors.onPrimary),
        side: const BorderSide(color: AppColors.outline),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        ),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
          ),
          textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.textStrong,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: AppColors.onPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusM)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static TextTheme _buildTextTheme(TextTheme base) {
    final display = GoogleFonts.frauncesTextTheme(base);
    final body = GoogleFonts.plusJakartaSansTextTheme(base);
    return base.copyWith(
      displayLarge:  display.displayLarge?.copyWith(color: AppColors.textStrong),
      displayMedium: display.displayMedium?.copyWith(color: AppColors.textStrong),
      displaySmall:  display.displaySmall?.copyWith(color: AppColors.textStrong),
      headlineLarge: display.headlineLarge?.copyWith(color: AppColors.textStrong, fontWeight: FontWeight.w600),
      headlineMedium: display.headlineMedium?.copyWith(color: AppColors.textStrong, fontWeight: FontWeight.w600),
      headlineSmall: display.headlineSmall?.copyWith(color: AppColors.textStrong, fontWeight: FontWeight.w600),
      titleLarge:    display.titleLarge?.copyWith(color: AppColors.textStrong, fontWeight: FontWeight.w700),
      titleMedium:   body.titleMedium?.copyWith(color: AppColors.textStrong, fontWeight: FontWeight.w600),
      titleSmall:    body.titleSmall?.copyWith(color: AppColors.textStrong),
      bodyLarge:     body.bodyLarge?.copyWith(color: AppColors.textStrong),
      bodyMedium:    body.bodyMedium?.copyWith(color: AppColors.textStrong),
      bodySmall:     body.bodySmall?.copyWith(color: AppColors.textMuted),
      labelLarge:    body.labelLarge?.copyWith(color: AppColors.textStrong, fontWeight: FontWeight.w600),
      labelMedium:   body.labelMedium?.copyWith(color: AppColors.textMuted),
      labelSmall:    body.labelSmall?.copyWith(color: AppColors.textMuted),
    );
  }
}
