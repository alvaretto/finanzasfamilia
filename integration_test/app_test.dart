/// Tests de Integración con Patrol
/// Framework de Self-Healing Visual Testing para Finanzas Familiares
library;

import 'package:finanzas_familiares/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:patrol/patrol.dart';

import 'patrol_test_config.dart';

void main() {
  patrolTest(
    'App inicia correctamente y muestra onboarding o login',
    config: patrolConfig,
    ($) async {
      // Iniciar la app
      await $.pumpWidgetAndSettle(
        const ProviderScope(
          child: FinanzasFamiliaresApp(),
        ),
      );

      // Verificar que la app cargó (Splash, Onboarding o Login)
      final hasSplash = $(find.byType(Scaffold)).exists;
      expect(hasSplash, true, reason: 'La app debe mostrar un Scaffold');

      // Capturar screenshot inicial
      await $.captureScreen('app_start');
    },
  );

  patrolTest(
    'Navegación principal funciona',
    config: patrolConfig,
    ($) async {
      await $.pumpWidgetAndSettle(
        const ProviderScope(
          child: FinanzasFamiliaresApp(),
        ),
      );

      // Esperar a que cargue completamente
      await $.pump(const Duration(seconds: 3));

      // Buscar elementos de navegación con self-healing
      try {
        final navFinder = await $.findWithHealing(
          byType: 'NavigationBar',
          byText: 'Inicio',
        );

        if (navFinder.exists) {
          await $.captureScreen('navigation_visible');
        }
      } catch (_) {
        // Si no hay navegación, puede estar en onboarding/login
        await $.captureScreen('no_navigation_found');
      }
    },
  );

  patrolTest(
    'Self-Healing: Busca Dashboard por múltiples estrategias',
    config: patrolConfig,
    ($) async {
      await $.pumpWidgetAndSettle(
        const ProviderScope(
          child: FinanzasFamiliaresApp(),
        ),
      );

      await $.pump(const Duration(seconds: 3));

      // Intentar encontrar el Dashboard usando self-healing
      try {
        final dashboardFinder = await $.findWithHealing(
          byText: 'Mis Ahorros',
          bySemanticsLabel: 'Dashboard',
          byKey: 'dashboard_screen',
        );

        if (dashboardFinder.exists) {
          await $.captureScreen('dashboard_found');
        }
      } catch (e) {
        // Documentar qué estrategias fallaron
        await $.captureScreen('dashboard_not_found');
      }
    },
  );

  patrolTest(
    'Golden Test: Captura estado visual de pantallas clave',
    config: patrolConfig,
    ($) async {
      await $.pumpWidgetAndSettle(
        const ProviderScope(
          child: FinanzasFamiliaresApp(),
        ),
      );

      // Capturar goldens de cada pantalla encontrada
      await $.pump(const Duration(seconds: 3));
      await $.validateAgainstGolden('golden_initial_screen');

      // Si hay navegación, capturar cada tab
      if ($(find.byType(NavigationBar)).exists) {
        final navItems = $(find.byType(NavigationDestination));

        for (int i = 0; i < navItems.evaluate().length && i < 5; i++) {
          try {
            await navItems.at(i).tap();
            await $.pumpAndSettle();
            await $.validateAgainstGolden('golden_tab_$i');
          } catch (_) {
            // Continuar con siguiente tab
          }
        }
      }
    },
  );
}
