import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

/// Claves de SharedPreferences
class _OnboardingKeys {
  static const hasCompletedOnboarding = 'has_completed_onboarding';
  static const currentStep = 'onboarding_current_step';
}

/// Provider que indica si es la primera vez del usuario
@riverpod
Future<bool> isFirstTimeUser(Ref ref) async {
  final prefs = await SharedPreferences.getInstance();
  final hasCompleted = prefs.getBool(_OnboardingKeys.hasCompletedOnboarding);
  return hasCompleted != true;
}

/// Servicio de onboarding
@Riverpod(keepAlive: true)
OnboardingService onboardingService(Ref ref) {
  return OnboardingService();
}

/// Servicio para manejar el estado del onboarding
class OnboardingService {
  /// Marca el onboarding como completado
  Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_OnboardingKeys.hasCompletedOnboarding, true);
  }

  /// Obtiene el paso actual del onboarding
  Future<int> getCurrentStep() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_OnboardingKeys.currentStep) ?? 0;
  }

  /// Guarda el paso actual del onboarding
  Future<void> setCurrentStep(int step) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_OnboardingKeys.currentStep, step);
  }

  /// Reinicia el estado del onboarding (útil para testing/desarrollo)
  Future<void> resetOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_OnboardingKeys.hasCompletedOnboarding);
    await prefs.remove(_OnboardingKeys.currentStep);
  }
}
