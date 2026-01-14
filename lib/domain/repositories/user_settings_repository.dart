import '../entities/user_settings.dart';

/// Repositorio para gestionar la configuración persistente del usuario
abstract class UserSettingsRepository {
  /// Obtiene la configuración del usuario actual
  /// Crea una configuración por defecto si no existe
  Stream<UserSettings?> watchSettings();

  /// Obtiene la configuración actual (Future)
  Future<UserSettings?> getSettings();

  /// Actualiza la configuración
  Future<void> updateSettings(UserSettings settings);

  /// Crea la configuración inicial
  Future<void> createInitialSettings(String userId);
}
