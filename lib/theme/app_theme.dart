import 'package:flutter/material.dart';

class AppTheme {
  static final ColorScheme _appColorScheme = const ColorScheme.light(
    primary: Color(0xFF03A9F4),
    onPrimary: Colors.white,
    secondary: Color(0xFF4DD0E1),
    onSecondary: Colors.white,
    surface: Colors.white,
    onSurface: Color(0xFF424242),
    background: Colors.white,
    onBackground: Color(0xFF424242),
    error: Colors.red,
    onError: Colors.white,
    brightness: Brightness.light,
  );

  static ThemeData get lightTheme {
    return ThemeData(
      colorScheme: _appColorScheme,
      scaffoldBackgroundColor: const Color(0xFFF5F5F5),
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Color(0xFF424242),
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: Color(0xFF424242),
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: Color(0xFF424242)),
        displayMedium: TextStyle(color: Color(0xFF424242)),
        displaySmall: TextStyle(color: Color(0xFF424242)),
        headlineLarge: TextStyle(color: Color(0xFF424242)),
        headlineMedium: TextStyle(color: Color(0xFF424242)),
        headlineSmall: TextStyle(color: Color(0xFF424242)),
        titleLarge: TextStyle(color: Color(0xFF424242)),
        titleMedium: TextStyle(color: Color(0xFF424242)),
        titleSmall: TextStyle(color: Color(0xFF424242)),
        bodyLarge: TextStyle(color: Color(0xFF424242)),
        bodyMedium: TextStyle(color: Color(0xFF757575)),
        bodySmall: TextStyle(color: Color(0xFFBDBDBD)),
        labelLarge: TextStyle(color: Colors.white),
        labelMedium: TextStyle(color: Colors.white),
        labelSmall: TextStyle(color: Colors.white),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _appColorScheme.primary,
          foregroundColor: _appColorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _appColorScheme.primary,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: _appColorScheme.primary,
        foregroundColor: _appColorScheme.onPrimary,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: _appColorScheme.primary,
        inactiveTrackColor: _appColorScheme.primary.withOpacity(0.3),
        thumbColor: _appColorScheme.primary,
        overlayColor: _appColorScheme.primary.withOpacity(0.2),
        trackHeight: 4.0,
      ),
      cardTheme: CardThemeData(
        color: _appColorScheme.surface,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      iconTheme: const IconThemeData(
        color: Color(0xFF757575),
        size: 24,
      ),
    );
  }
}
