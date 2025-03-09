import 'package:flutter/material.dart';
import 'package:aina_flutter/core/styles/constants.dart';

class AppTheme {
  static ThemeData get theme {
    return ThemeData(
      fontFamily: 'Inter',
      textTheme: const TextTheme(
        bodyLarge: TextStyle(
          fontFamily: 'Inter',
          fontSize: 16,
          fontFamilyFallback: ['Roboto', 'Noto Sans'],
        ),
        bodyMedium: TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          fontFamilyFallback: ['Roboto', 'Noto Sans'],
        ),
        titleLarge: TextStyle(
          fontFamily: 'Inter',
          fontSize: 20,
          fontWeight: FontWeight.w500,
          fontFamilyFallback: ['Roboto', 'Noto Sans'],
        ),
      ),
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
      ),
    );
  }
}
