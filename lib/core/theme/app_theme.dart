import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get dark => ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.darkBackground,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.primary,
          secondary: AppColors.primaryLight,
          surface: AppColors.darkSurface,
          onPrimary: Colors.white,
          onSurface: AppColors.textOnDark,
        ),
        textTheme: _buildTextTheme(
          primary: AppColors.textOnDark,
          subtle: AppColors.textSubtleOnDark,
        ),
      );

  static ThemeData get light => ThemeData(
        brightness: Brightness.light,
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.lightBackground,
        colorScheme: const ColorScheme.light(
          primary: AppColors.primaryDark,
          secondary: AppColors.primary,
          surface: AppColors.lightSurface,
          onPrimary: Colors.white,
          onSurface: AppColors.textOnLight,
        ),
        textTheme: _buildTextTheme(
          primary: AppColors.textOnLight,
          subtle: AppColors.textSubtleOnLight,
        ),
      );

  static TextTheme _buildTextTheme({
    required Color primary,
    required Color subtle,
  }) =>
      TextTheme(
        displayLarge: TextStyle(
          color: primary,
          fontSize: 36,
          fontWeight: FontWeight.w300,
          letterSpacing: 12,
        ),
        labelSmall: TextStyle(
          color: subtle,
          fontSize: 11,
          fontWeight: FontWeight.w400,
          letterSpacing: 3.5,
        ),
      );
}
