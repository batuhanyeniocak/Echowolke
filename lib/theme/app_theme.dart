import 'package:flutter/material.dart';

class AppTheme {
  static final ColorScheme _lightColorScheme = const ColorScheme.light(
    primary: Color(0xFFFF5500),
    onPrimary: Colors.white,
    secondary: Color(0xFFFF5500),
    onSecondary: Colors.white,
    surface: Colors.white,
    onSurface: Color(0xFF333333),
    background: Colors.white,
    onBackground: Color(0xFF333333),
    error: Color(0xFFE53935),
    onError: Colors.white,
    brightness: Brightness.light,
  );

  static final ColorScheme _darkColorScheme = const ColorScheme.dark(
    primary: Color(0xFFFF5500),
    onPrimary: Colors.white,
    secondary: Color(0xFFFF5500),
    onSecondary: Colors.white,
    surface: Color(0xFF1A1A1A),
    onSurface: Colors.white,
    background: Color(0xFF000000),
    onBackground: Colors.white,
    error: Color(0xFFEF5350),
    onError: Colors.white,
    brightness: Brightness.dark,
  );

  static ThemeData get lightTheme {
    return ThemeData(
      colorScheme: _lightColorScheme,
      scaffoldBackgroundColor: _lightColorScheme.background,
      fontFamily: 'Roboto',
      appBarTheme: AppBarTheme(
        backgroundColor: _lightColorScheme.surface,
        foregroundColor: _lightColorScheme.onSurface,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: _lightColorScheme.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(color: _lightColorScheme.onSurface),
        displayMedium: TextStyle(color: _lightColorScheme.onSurface),
        displaySmall: TextStyle(color: _lightColorScheme.onSurface),
        headlineLarge: TextStyle(color: _lightColorScheme.onSurface),
        headlineMedium: TextStyle(color: _lightColorScheme.onSurface),
        headlineSmall: TextStyle(color: _lightColorScheme.onSurface),
        titleLarge: TextStyle(color: _lightColorScheme.onSurface),
        titleMedium: TextStyle(color: _lightColorScheme.onSurface),
        titleSmall: TextStyle(color: _lightColorScheme.onSurface),
        bodyLarge: TextStyle(color: _lightColorScheme.onSurface),
        bodyMedium:
            TextStyle(color: _lightColorScheme.onSurface.withOpacity(0.7)),
        bodySmall:
            TextStyle(color: _lightColorScheme.onSurface.withOpacity(0.5)),
        labelLarge: TextStyle(color: _lightColorScheme.onPrimary),
        labelMedium: TextStyle(color: _lightColorScheme.onPrimary),
        labelSmall: TextStyle(color: _lightColorScheme.onPrimary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _lightColorScheme.primary,
          foregroundColor: _lightColorScheme.onPrimary,
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
          foregroundColor: _lightColorScheme.primary,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: _lightColorScheme.primary,
        foregroundColor: _lightColorScheme.onPrimary,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: _lightColorScheme.primary,
        inactiveTrackColor: _lightColorScheme.primary.withOpacity(0.3),
        thumbColor: _lightColorScheme.primary,
        overlayColor: _lightColorScheme.primary.withOpacity(0.2),
        trackHeight: 4.0,
      ),
      iconTheme: IconThemeData(
        color: _lightColorScheme.onSurface.withOpacity(0.7),
        size: 24,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: _lightColorScheme.surface,
        selectedItemColor: _lightColorScheme.primary,
        unselectedItemColor: _lightColorScheme.onSurface.withOpacity(0.6),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      colorScheme: _darkColorScheme,
      scaffoldBackgroundColor: _darkColorScheme.background,
      fontFamily: 'Roboto',
      appBarTheme: AppBarTheme(
        backgroundColor: _darkColorScheme.surface,
        foregroundColor: _darkColorScheme.onSurface,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: _darkColorScheme.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(color: _darkColorScheme.onSurface),
        displayMedium: TextStyle(color: _darkColorScheme.onSurface),
        displaySmall: TextStyle(color: _darkColorScheme.onSurface),
        headlineLarge: TextStyle(color: _darkColorScheme.onSurface),
        headlineMedium: TextStyle(color: _darkColorScheme.onSurface),
        headlineSmall: TextStyle(color: _darkColorScheme.onSurface),
        titleLarge: TextStyle(color: _darkColorScheme.onSurface),
        titleMedium: TextStyle(color: _darkColorScheme.onSurface),
        titleSmall: TextStyle(color: _darkColorScheme.onSurface),
        bodyLarge: TextStyle(color: _darkColorScheme.onSurface),
        bodyMedium:
            TextStyle(color: _darkColorScheme.onSurface.withOpacity(0.7)),
        bodySmall:
            TextStyle(color: _darkColorScheme.onSurface.withOpacity(0.5)),
        labelLarge: TextStyle(color: _darkColorScheme.onPrimary),
        labelMedium: TextStyle(color: _darkColorScheme.onPrimary),
        labelSmall: TextStyle(color: _darkColorScheme.onPrimary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _darkColorScheme.primary,
          foregroundColor: _darkColorScheme.onPrimary,
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
          foregroundColor: _darkColorScheme.primary,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: _darkColorScheme.primary,
        foregroundColor: _darkColorScheme.onPrimary,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: _darkColorScheme.primary,
        inactiveTrackColor: _darkColorScheme.primary.withOpacity(0.3),
        thumbColor: _darkColorScheme.primary,
        overlayColor: _darkColorScheme.primary.withOpacity(0.2),
        trackHeight: 4.0,
      ),
      iconTheme: IconThemeData(
        color: _darkColorScheme.onSurface.withOpacity(0.7),
        size: 24,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: _darkColorScheme.surface,
        selectedItemColor: _darkColorScheme.primary,
        unselectedItemColor: _darkColorScheme.onSurface.withOpacity(0.6),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }
}
