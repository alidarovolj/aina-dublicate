import 'package:flutter/material.dart';
import 'package:aina_flutter/core/styles/constants.dart';
import 'package:flutter/services.dart';

class AppTheme {
  static ThemeData get theme {
    return ThemeData(
      fontFamily: 'Inter',
      brightness: Brightness.dark,
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
      colorScheme: ColorScheme.dark(
        primary: AppColors.primary,
        surface: AppColors.primary,
        background: AppColors.primary,
      ),
      appBarTheme: const AppBarTheme(
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
          systemNavigationBarColor: Colors.black,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
      ),
      scaffoldBackgroundColor: AppColors.primary,
    );
  }
}
