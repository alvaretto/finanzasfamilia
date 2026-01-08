import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/bootstrap/app_initializer.dart';
import '../../core/database/app_database.dart';

/// Provider de la base de datos local
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

/// Provider del modo de tema
final themeModeProvider = StateProvider<ThemeMode>((ref) {
  return ThemeMode.system;
});

/// Provider para la inicialización de la app
final appInitializationProvider = FutureProvider<AppInitializationResult>((ref) async {
  return AppInitializer.initialize();
});

/// Modelo de preferencias del usuario
class UserPreferences {
  final String currency;
  final String locale;
  final int autoLockMinutes;
  final bool biometricEnabled;

  const UserPreferences({
    this.currency = 'COP',
    this.locale = 'es_CO',
    this.autoLockMinutes = 5,
    this.biometricEnabled = false,
  });

  UserPreferences copyWith({
    String? currency,
    String? locale,
    int? autoLockMinutes,
    bool? biometricEnabled,
  }) {
    return UserPreferences(
      currency: currency ?? this.currency,
      locale: locale ?? this.locale,
      autoLockMinutes: autoLockMinutes ?? this.autoLockMinutes,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
    );
  }

  /// Nombre completo de la moneda
  String get currencyName {
    const names = {
      'COP': 'Peso Colombiano',
      'USD': 'Dólar Estadounidense',
      'EUR': 'Euro',
      'MXN': 'Peso Mexicano',
      'ARS': 'Peso Argentino',
      'PEN': 'Sol Peruano',
      'CLP': 'Peso Chileno',
      'BRL': 'Real Brasileño',
    };
    return names[currency] ?? currency;
  }
}

/// Provider de preferencias del usuario
final userPreferencesProvider = StateNotifierProvider<UserPreferencesNotifier, UserPreferences>((ref) {
  return UserPreferencesNotifier();
});

class UserPreferencesNotifier extends StateNotifier<UserPreferences> {
  UserPreferencesNotifier() : super(const UserPreferences());

  void setCurrency(String currency) {
    final locales = {
      'COP': 'es_CO',
      'USD': 'en_US',
      'EUR': 'es_ES',
      'MXN': 'es_MX',
      'ARS': 'es_AR',
      'PEN': 'es_PE',
      'CLP': 'es_CL',
      'BRL': 'pt_BR',
    };
    state = state.copyWith(
      currency: currency,
      locale: locales[currency] ?? 'es_CO',
    );
  }

  void setAutoLockMinutes(int minutes) {
    state = state.copyWith(autoLockMinutes: minutes);
  }

  void setBiometricEnabled(bool enabled) {
    state = state.copyWith(biometricEnabled: enabled);
  }
}

/// Provider para cambiar el tema
final themeNotifierProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier();
});

class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.system);

  void setThemeMode(ThemeMode mode) {
    state = mode;
  }

  void toggleTheme() {
    state = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
  }
}
