import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'user_settings_provider.dart';

part 'onboarding_provider.g.dart';

/// Pasos del onboarding
enum OnboardingStep {
  /// Pantalla de bienvenida
  welcome,

  /// Características principales de la app
  features,

  /// Configuración inicial de cuentas
  setupAccounts,

  /// Listo para comenzar
  ready,
}

/// Provider que indica si es la primera vez del usuario
/// Delegación a UserSettings sincronizado
@riverpod
Future<bool> isFirstTimeUser(Ref ref) async {
  final settingsAsync = await ref.watch(userSettingsProvider.future);

  // Si no hay settings, es primera vez
  if (settingsAsync == null) {
    return true;
  }

  // Si onboarding no está completado, es primera vez
  return !settingsAsync.onboardingCompleted;
}

/// Servicio de onboarding
/// Delegación a UserSettingsService para persistencia sincronizada
@Riverpod(keepAlive: true)
OnboardingService onboardingService(Ref ref) {
  final userSettingsService = ref.watch(userSettingsServiceProvider);
  return OnboardingService(userSettingsService);
}

/// Servicio para manejar el estado del onboarding
/// MIGRADO: Ya no usa SharedPreferences, usa UserSettingsService
class OnboardingService {
  final dynamic _userSettingsService;

  OnboardingService(this._userSettingsService);

  /// Marca el onboarding como completado
  /// MIGRADO: Persistido en BD sincronizada
  Future<void> completeOnboarding() async {
    await _userSettingsService.updateOnboardingCompleted(true);
  }

  /// Reinicia el estado del onboarding (útil para testing/desarrollo)
  Future<void> resetOnboarding() async {
    await _userSettingsService.updateOnboardingCompleted(false);
  }
}
