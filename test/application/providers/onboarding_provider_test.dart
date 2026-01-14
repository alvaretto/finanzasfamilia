import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finanzas_familiares/application/providers/onboarding_provider.dart';
import 'package:finanzas_familiares/application/providers/user_settings_provider.dart';
import 'package:finanzas_familiares/domain/entities/user_settings.dart';

void main() {
  group('OnboardingProvider', () {
    test('isFirstTimeUser retorna true si no hay UserSettings', () async {
      final container = ProviderContainer(
        overrides: [
          // Mock: usuario sin settings
          userSettingsProvider.overrideWith((ref) => Stream.value(null)),
        ],
      );
      addTearDown(container.dispose);

      final isFirstTime = await container.read(isFirstTimeUserProvider.future);
      expect(isFirstTime, isTrue);
    });

    test('isFirstTimeUser retorna true si onboarding no completado', () async {
      final mockSettings = UserSettings(
        id: 'user123',
        userId: 'user123',
        themeMode: 'system',
        onboardingCompleted: false, // NO completado
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final container = ProviderContainer(
        overrides: [
          userSettingsProvider.overrideWith((ref) => Stream.value(mockSettings)),
        ],
      );
      addTearDown(container.dispose);

      final isFirstTime = await container.read(isFirstTimeUserProvider.future);
      expect(isFirstTime, isTrue);
    });

    test('isFirstTimeUser retorna false si onboarding completado', () async {
      final mockSettings = UserSettings(
        id: 'user123',
        userId: 'user123',
        themeMode: 'system',
        onboardingCompleted: true, // COMPLETADO
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final container = ProviderContainer(
        overrides: [
          userSettingsProvider.overrideWith((ref) => Stream.value(mockSettings)),
        ],
      );
      addTearDown(container.dispose);

      final isFirstTime = await container.read(isFirstTimeUserProvider.future);
      expect(isFirstTime, isFalse);
    });

    test('OnboardingService puede ser instanciado', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final service = container.read(onboardingServiceProvider);
      expect(service, isA<OnboardingService>());
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
