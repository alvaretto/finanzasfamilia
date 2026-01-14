import 'package:flutter/material.dart';

/// Definición centralizada de temas de la aplicación
class AppTheme {
  AppTheme._();

  /// Color semilla para generar el esquema de colores (verde oscuro)
  static const Color seedColor = Color(0xFF1B5E20);

  /// Color verde claro para indicadores en modo oscuro
  static const Color _lightGreen = Color(0xFF4CAF50);

  /// Tema claro
  static ThemeData light() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: seedColor,
        brightness: Brightness.light,
      ),
      useMaterial3: true,
      cardTheme: const CardThemeData(
        elevation: 2,
      ),
      navigationBarTheme: NavigationBarThemeData(
        indicatorColor: seedColor.withValues(alpha: 0.2),
      ),
    );
  }

  /// Tema oscuro
  static ThemeData dark() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: seedColor,
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
      cardTheme: const CardThemeData(
        elevation: 2,
      ),
      navigationBarTheme: NavigationBarThemeData(
        indicatorColor: _lightGreen.withValues(alpha: 0.3),
      ),
    );
  }
}
