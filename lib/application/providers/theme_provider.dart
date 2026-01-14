import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/services/user_settings_service.dart';
import 'user_settings_provider.dart';

part 'theme_provider.g.dart';

/// Modos de tema disponibles
enum AppThemeMode {
  /// Tema claro
  light,

  /// Tema oscuro
  dark,

  /// Seguir configuración del sistema
  system,
}

/// Provider para gestionar el tema de la aplicación con persistencia
/// Delegación a UserSettingsService para sincronización entre dispositivos
@Riverpod(keepAlive: true)
class ThemeNotifier extends _$ThemeNotifier {
  UserSettingsService get _service => ref.read(userSettingsServiceProvider);

  @override
  AppThemeMode build() {
    // Escuchar cambios en UserSettings y sincronizar con el tema
    ref.listen(userSettingsProvider, (previous, next) {
      next.whenData((settings) {
        if (settings != null) {
          final mode = _stringToThemeMode(settings.themeMode);
          if (state != mode) {
            state = mode;
          }
        }
      });
    });

    // Estado inicial desde UserSettings
    final settingsAsync = ref.read(userSettingsProvider);
    return settingsAsync.maybeWhen(
      data: (settings) =>
          settings != null ? _stringToThemeMode(settings.themeMode) : AppThemeMode.system,
      orElse: () => AppThemeMode.system,
    );
  }

  /// Cambia el tema y lo persiste en la BD
  Future<void> setTheme(AppThemeMode mode) async {
    state = mode;
    try {
      await _service.updateThemeMode(_themeModeToString(mode));
    } catch (e) {
      // Revertir el estado si falla la persistencia
      final settingsAsync = ref.read(userSettingsProvider);
      settingsAsync.whenData((settings) {
        if (settings != null) {
          state = _stringToThemeMode(settings.themeMode);
        }
      });
      rethrow;
    }
  }

  /// Alterna entre light y dark (ignora system)
  Future<void> toggleTheme() async {
    final newMode =
        state == AppThemeMode.dark ? AppThemeMode.light : AppThemeMode.dark;
    await setTheme(newMode);
  }

  /// Convierte String a AppThemeMode
  AppThemeMode _stringToThemeMode(String mode) {
    return AppThemeMode.values.firstWhere(
      (m) => m.name == mode,
      orElse: () => AppThemeMode.system,
    );
  }

  /// Convierte AppThemeMode a String
  String _themeModeToString(AppThemeMode mode) => mode.name;
}

/// Convierte AppThemeMode a ThemeMode de Flutter
ThemeMode appThemeModeToFlutter(AppThemeMode mode) {
  switch (mode) {
    case AppThemeMode.light:
      return ThemeMode.light;
    case AppThemeMode.dark:
      return ThemeMode.dark;
    case AppThemeMode.system:
      return ThemeMode.system;
  }
}

/// Extensión para obtener el nombre legible del tema
extension AppThemeModeExtension on AppThemeMode {
  String get displayName {
    switch (this) {
      case AppThemeMode.light:
        return 'Claro';
      case AppThemeMode.dark:
        return 'Oscuro';
      case AppThemeMode.system:
        return 'Sistema';
    }
  }

  IconData get icon {
    switch (this) {
      case AppThemeMode.light:
        return Icons.light_mode;
      case AppThemeMode.dark:
        return Icons.dark_mode;
      case AppThemeMode.system:
        return Icons.brightness_auto;
    }
  }
}
