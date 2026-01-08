import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:finanzas_familiares/application/providers/onboarding_provider.dart';

void main() {
  group('OnboardingProvider', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('isFirstTimeUser retorna true si no hay valor guardado', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final isFirstTime = await container.read(isFirstTimeUserProvider.future);
      expect(isFirstTime, isTrue);
    });

    test('isFirstTimeUser retorna false si ya completó onboarding', () async {
      SharedPreferences.setMockInitialValues({
        'has_completed_onboarding': true,
      });

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final isFirstTime = await container.read(isFirstTimeUserProvider.future);
      expect(isFirstTime, isFalse);
    });

    test('completeOnboarding marca como completado', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Inicialmente es primera vez
      var isFirstTime = await container.read(isFirstTimeUserProvider.future);
      expect(isFirstTime, isTrue);

      // Completar onboarding
      await container.read(onboardingServiceProvider).completeOnboarding();

      // Invalidar el provider para forzar re-lectura
      container.invalidate(isFirstTimeUserProvider);

      // Ya no es primera vez
      isFirstTime = await container.read(isFirstTimeUserProvider.future);
      expect(isFirstTime, isFalse);
    });

    test('getCurrentOnboardingStep retorna 0 inicialmente', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final step =
          await container.read(onboardingServiceProvider).getCurrentStep();
      expect(step, equals(0));
    });

    test('setCurrentStep guarda y recupera el step', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final service = container.read(onboardingServiceProvider);

      await service.setCurrentStep(2);
      final step = await service.getCurrentStep();

      expect(step, equals(2));
    });

    test('resetOnboarding limpia el estado', () async {
      SharedPreferences.setMockInitialValues({
        'has_completed_onboarding': true,
        'onboarding_current_step': 3,
      });

      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(onboardingServiceProvider).resetOnboarding();
      container.invalidate(isFirstTimeUserProvider);

      final isFirstTime = await container.read(isFirstTimeUserProvider.future);
      expect(isFirstTime, isTrue);

      final step =
          await container.read(onboardingServiceProvider).getCurrentStep();
      expect(step, equals(0));
    });
  });

  group('OnboardingSteps', () {
    test('tiene los pasos correctos definidos', () {
      expect(OnboardingStep.values.length, equals(4));
      expect(OnboardingStep.welcome.index, equals(0));
      expect(OnboardingStep.features.index, equals(1));
      expect(OnboardingStep.setupAccounts.index, equals(2));
      expect(OnboardingStep.ready.index, equals(3));
    });
  });
}
