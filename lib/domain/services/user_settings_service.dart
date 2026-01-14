import 'package:shared_preferences/shared_preferences.dart';

import '../entities/user_settings.dart';
import '../repositories/user_settings_repository.dart';

/// Servicio de dominio para gestión de configuración de usuario
///
/// Responsabilidades:
/// - Orquestar migración de SharedPreferences a BD
/// - Validar configuración antes de persistir
/// - Proporcionar API de alto nivel para cambios de configuración
class UserSettingsService {
  final UserSettingsRepository _repository;

  UserSettingsService(this._repository);

  /// Obtiene la configuración del usuario actual
  /// Si no existe, crea una por defecto
  Future<UserSettings?> getSettings() async {
    return await _repository.getSettings();
  }

  /// Stream de configuración para reactividad
  Stream<UserSettings?> watchSettings() {
    return _repository.watchSettings();
  }

  /// Crea la configuración inicial del usuario
  /// Intenta migrar desde SharedPreferences si existen datos previos
  Future<void> createInitialSettings(String userId) async {
    // Verificar si ya existe configuración
    final existing = await _repository.getSettings();
    if (existing != null) {
      return; // Ya existe, no hacer nada
    }

    // Intentar migrar desde SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final migratedTheme = prefs.getString('theme_mode');
    final migratedOnboarding = prefs.getBool('onboarding_completed');

    // Crear configuración inicial (posiblemente con datos migrados)
    await _repository.createInitialSettings(userId);

    // Si había datos en SharedPreferences, actualizarlos en la BD
    if (migratedTheme != null || migratedOnboarding != null) {
      final settings = await _repository.getSettings();
      if (settings != null) {
        final updated = settings.copyWith(
          themeMode: migratedTheme ?? settings.themeMode,
          onboardingCompleted: migratedOnboarding ?? settings.onboardingCompleted,
        );
        await _repository.updateSettings(updated);

        // Limpiar SharedPreferences migrados
        await prefs.remove('theme_mode');
        await prefs.remove('onboarding_completed');
      }
    }
  }

  /// Actualiza el modo de tema
  Future<void> updateThemeMode(String themeMode) async {
    if (!_isValidThemeMode(themeMode)) {
      throw ArgumentError(
        'Tema inválido: $themeMode. Valores permitidos: light, dark, system',
      );
    }

    final settings = await _repository.getSettings();
    
    // Si no hay configuración (usuario no logueado), guardar en SharedPreferences
    if (settings == null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('theme_mode', themeMode);
      return;
    }

    await _repository.updateSettings(
      settings.copyWith(themeMode: themeMode),
    );
  }

  /// Actualiza el estado de onboarding
  Future<void> updateOnboardingCompleted(bool completed) async {
    final settings = await _repository.getSettings();
    
    // Si no hay configuración (usuario no logueado), guardar en SharedPreferences
    if (settings == null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarding_completed', completed);
      return;
    }

    await _repository.updateSettings(
      settings.copyWith(onboardingCompleted: completed),
    );
  }

  /// Actualiza las preferencias de notificaciones
  Future<void> updateNotificationPreferences({
    bool? notificationsEnabled,
    bool? budgetAlertsEnabled,
    bool? recurringRemindersEnabled,
    bool? dailyReminderEnabled,
    int? dailyReminderHour,
  }) async {
    final settings = await _repository.getSettings();
    
    // Si no hay configuración (usuario no logueado), guardar en SharedPreferences (si aplica)
    // Por simplicidad, por ahora solo persistimos en DB para notificaciones complejas,
    // pero evitamos el crash
    if (settings == null) {
      // TODO: Implementar persistencia local completa para notificaciones si es necesario offline
      return;
    }

    // Validar hora del recordatorio si se proporciona
    if (dailyReminderHour != null &&
        (dailyReminderHour < 0 || dailyReminderHour > 23)) {
      throw ArgumentError(
        'Hora de recordatorio inválida: $dailyReminderHour. Debe estar entre 0-23',
      );
    }

    await _repository.updateSettings(
      settings.copyWith(
        notificationsEnabled: notificationsEnabled,
        budgetAlertsEnabled: budgetAlertsEnabled,
        recurringRemindersEnabled: recurringRemindersEnabled,
        dailyReminderEnabled: dailyReminderEnabled,
        dailyReminderHour: dailyReminderHour,
      ),
    );
  }

  /// Valida que el tema sea válido
  bool _isValidThemeMode(String themeMode) {
    return themeMode == 'light' || themeMode == 'dark' || themeMode == 'system';
  }
}
