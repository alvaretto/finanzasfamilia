import 'package:flutter/foundation.dart';
import 'package:in_app_update/in_app_update.dart';

/// Servicio para manejar actualizaciones in-app desde Play Store.
/// Singleton que verifica y gestiona actualizaciones de la app.
class InAppUpdateService {
  static final InAppUpdateService _instance = InAppUpdateService._();
  factory InAppUpdateService() => _instance;
  InAppUpdateService._();

  AppUpdateInfo? _updateInfo;
  bool _isUpdateAvailable = false;

  /// Indica si hay una actualización disponible
  bool get isUpdateAvailable => _isUpdateAvailable;

  /// Información de la actualización disponible
  AppUpdateInfo? get updateInfo => _updateInfo;

  /// Verifica si hay una actualización disponible en Play Store.
  /// Retorna true si hay actualización, false en caso contrario.
  /// Nota: Solo funciona en dispositivos con Play Store y app instalada desde ahí.
  Future<bool> checkForUpdate() async {
    try {
      // InAppUpdate solo funciona si la app fue instalada desde Play Store
      // En desarrollo (adb install) esto lanzará una excepción
      final info = await InAppUpdate.checkForUpdate();
      _updateInfo = info;
      _isUpdateAvailable =
          info.updateAvailability == UpdateAvailability.updateAvailable;

      if (_isUpdateAvailable) {
        debugPrint(
          '[IN-APP-UPDATE] Actualización disponible: '
          'availableVersion=${info.availableVersionCode}, '
          'staleDays=${info.clientVersionStalenessDays}',
        );
      } else {
        debugPrint('[IN-APP-UPDATE] App actualizada');
      }

      return _isUpdateAvailable;
    } on Exception catch (e) {
      // Esperado en desarrollo o dispositivos sin Play Store
      debugPrint('[IN-APP-UPDATE] No disponible (dev/sin Play Store): $e');
      _updateInfo = null;
      _isUpdateAvailable = false;
      return false;
    } catch (e) {
      debugPrint('[IN-APP-UPDATE] Error inesperado: $e');
      _updateInfo = null;
      _isUpdateAvailable = false;
      return false;
    }
  }

  /// Inicia una actualización flexible (descarga en background).
  /// El usuario puede seguir usando la app mientras se descarga.
  Future<void> startFlexibleUpdate() async {
    if (!_isUpdateAvailable) return;

    try {
      debugPrint('[IN-APP-UPDATE] Iniciando actualización flexible...');
      await InAppUpdate.startFlexibleUpdate();
      debugPrint('[IN-APP-UPDATE] Descarga completada');
    } catch (e) {
      debugPrint('[IN-APP-UPDATE] Error en actualización flexible: $e');
    }
  }

  /// Completa la instalación de una actualización flexible.
  /// Debe llamarse después de que la descarga haya terminado.
  Future<void> completeFlexibleUpdate() async {
    try {
      debugPrint('[IN-APP-UPDATE] Completando instalación...');
      await InAppUpdate.completeFlexibleUpdate();
    } catch (e) {
      debugPrint('[IN-APP-UPDATE] Error completando actualización: $e');
    }
  }

  /// Inicia una actualización inmediata (bloquea la app).
  /// Usar solo para actualizaciones críticas de seguridad.
  Future<void> performImmediateUpdate() async {
    if (!_isUpdateAvailable) return;

    try {
      debugPrint('[IN-APP-UPDATE] Iniciando actualización inmediata...');
      await InAppUpdate.performImmediateUpdate();
    } catch (e) {
      debugPrint('[IN-APP-UPDATE] Error en actualización inmediata: $e');
    }
  }

  /// Determina si la actualización debe ser inmediata basándose en
  /// los días desde que la actualización está disponible.
  bool shouldForceUpdate({int staleDaysThreshold = 7}) {
    final staleDays = _updateInfo?.clientVersionStalenessDays ?? 0;
    return staleDays >= staleDaysThreshold;
  }

  /// Verifica y ejecuta actualización automáticamente.
  /// - Si staleDays >= threshold: Immediate update (obligatoria)
  /// - Si staleDays < threshold: Flexible update (opcional)
  Future<void> checkAndPromptUpdate({int staleDaysThreshold = 7}) async {
    final hasUpdate = await checkForUpdate();
    if (!hasUpdate) return;

    if (shouldForceUpdate(staleDaysThreshold: staleDaysThreshold)) {
      await performImmediateUpdate();
    } else {
      await startFlexibleUpdate();
    }
  }
}
