import 'package:flutter/material.dart';
import 'app_colors.dart';

abstract final class AppTheme {
  static const String _headingFont = 'Poppins';
  static const String _bodyFont = 'Inter';

  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
      primary: AppColors.primary,
      surface: AppColors.surface,
      error: AppColors.error,
    );

    final textTheme = _textTheme;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.border),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          textStyle: textTheme.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  static TextTheme get _textTheme {
    const heading = TextStyle(
      fontFamily: _headingFont,
      color: AppColors.textPrimary,
    );
    const body = TextStyle(fontFamily: _bodyFont, color: AppColors.textPrimary);

    return TextTheme(
      displayLarge: heading,
      displayMedium: heading,
      displaySmall: heading,
      headlineLarge: heading,
      headlineMedium: heading,
      headlineSmall: heading,
      titleLarge: heading,
      titleMedium: heading,
      titleSmall: heading,
      labelLarge: heading,
      labelMedium: heading,
      labelSmall: heading,
      bodyLarge: body,
      bodyMedium: body,
      bodySmall: body,
    );
  }
}
