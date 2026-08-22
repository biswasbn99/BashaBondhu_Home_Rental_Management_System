import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorSchemeSeed: AppColors.themeColor,
    scaffoldBackgroundColor: const Color(0xFFF4F7F6),
    cardColor: Colors.white,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
    ),
    progressIndicatorTheme: _progressIndicatorThemeData,
    textTheme: _textTheme,
    inputDecorationTheme: _inputDecorationTheme,
    filledButtonTheme: _filledButtonThemeData,
  );

  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorSchemeSeed: AppColors.themeColor,
    scaffoldBackgroundColor: const Color(0xFF0E1615),
    cardColor: const Color(0xFF162120),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF162120),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
    ),
    progressIndicatorTheme: _progressIndicatorThemeData,
    textTheme: _textTheme,
    inputDecorationTheme: _inputDecorationTheme,
    filledButtonTheme: _filledButtonThemeData,
  );

  static final ProgressIndicatorThemeData _progressIndicatorThemeData =
      const ProgressIndicatorThemeData(color: AppColors.themeColor);

  static const TextTheme _textTheme = TextTheme(
    titleLarge: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w600,
    ),
    labelLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      color: Colors.grey,
    ),
  );

  static const InputDecorationTheme _inputDecorationTheme = InputDecorationTheme(
    contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    border: OutlineInputBorder(
      borderSide: BorderSide(color: AppColors.themeColor),
    ),
    enabledBorder: OutlineInputBorder(
      borderSide: BorderSide(color: Color(0xFFB5D0CB)),
    ),
    focusedBorder: OutlineInputBorder(
      borderSide: BorderSide(color: AppColors.themeColor, width: 2),
    ),
  );

  static final FilledButtonThemeData _filledButtonThemeData = FilledButtonThemeData(
    style: FilledButton.styleFrom(
      foregroundColor: Colors.white,
      backgroundColor: AppColors.themeColor,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      textStyle: const TextStyle(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        fontSize: 15,
      ),
    ),
  );
}