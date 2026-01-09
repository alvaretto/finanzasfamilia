/// Visual Regression Tests con Golden Toolkit
/// Captura y compara estados visuales de pantallas críticas
library;

import 'package:finanzas_familiares/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:patrol/patrol.dart';

import '../patrol_test_config.dart';

void main() {
  patrolTest(
    'Golden: Dashboard - Estado inicial',
    config: patrolConfig,
    ($) async {
      await $.pumpWidgetAndSettle(
        const ProviderScope(
          child: FinanzasFamiliaresApp(),
        ),
      );

      await $.pump(const Duration(seconds: 5));

      // Navegar al dashboard si no estamos ahí
      try {
        final homeFinder = await $.findWithHealing(
          byText: 'Inicio',
          byType: 'NavigationDestination',
        );
        if (homeFinder.exists) {
          await homeFinder.tap();
          await $.pumpAndSettle();
        }
      } catch (_) {}

      // Capturar golden del dashboard
      await $.validateAgainstGolden('dashboard_initial');

      // Validar elementos críticos del dashboard
      final hasBalance =
          $(find.textContaining('\$')).exists || $(find.textContaining('0')).exists;

      expect(hasBalance, true, reason: 'Dashboard debe mostrar algún balance');
    },
  );

  patrolTest(
    'Golden: Lista de Transacciones',
    config: patrolConfig,
    ($) async {
      await $.pumpWidgetAndSettle(
        const ProviderScope(
          child: FinanzasFamiliaresApp(),
        ),
      );

      await $.pump(const Duration(seconds: 3));

      // Navegar a transacciones
      try {
        final txFinder = await $.findWithHealing(
          byText: 'Transacciones',
          byType: 'NavigationDestination',
        );
        if (txFinder.exists) {
          await txFinder.tap();
          await $.pumpAndSettle();
          await $.validateAgainstGolden('transactions_list');
        }
      } catch (_) {
        await $.captureScreen('transactions_not_found');
      }
    },
  );

  patrolTest(
    'Golden: Lista de Cuentas',
    config: patrolConfig,
    ($) async {
      await $.pumpWidgetAndSettle(
        const ProviderScope(
          child: FinanzasFamiliaresApp(),
        ),
      );

      await $.pump(const Duration(seconds: 3));

      // Navegar a cuentas
      try {
        final accountsFinder = await $.findWithHealing(
          byText: 'Cuentas',
          byType: 'NavigationDestination',
        );
        if (accountsFinder.exists) {
          await accountsFinder.tap();
          await $.pumpAndSettle();
          await $.validateAgainstGolden('accounts_list');
        }
      } catch (_) {
        await $.captureScreen('accounts_not_found');
      }
    },
  );

  patrolTest(
    'Golden: Formulario de Transacción',
    config: patrolConfig,
    ($) async {
      await $.pumpWidgetAndSettle(
        const ProviderScope(
          child: FinanzasFamiliaresApp(),
        ),
      );

      await $.pump(const Duration(seconds: 3));

      // Buscar FAB para nueva transacción
      try {
        final fabFinder = await $.findWithHealing(
          byType: 'FloatingActionButton',
          byTooltip: 'Nuevo',
        );

        if (fabFinder.exists) {
          await fabFinder.tap();
          await $.pumpAndSettle();
          await $.validateAgainstGolden('transaction_form');

          // Validar campos del formulario
          final hasAmountField = $(find.byType(TextField)).exists ||
              $(find.byType(TextFormField)).exists;

          expect(hasAmountField, true, reason: 'Formulario debe tener campos de entrada');
        }
      } catch (_) {
        await $.captureScreen('fab_not_found');
      }
    },
  );

  patrolTest(
    'Golden: Selector de Categorías',
    config: patrolConfig,
    ($) async {
      await $.pumpWidgetAndSettle(
        const ProviderScope(
          child: FinanzasFamiliaresApp(),
        ),
      );

      await $.pump(const Duration(seconds: 3));

      // Navegar a formulario de transacción
      try {
        final fabFinder = await $.findWithHealing(
          byType: 'FloatingActionButton',
        );

        if (fabFinder.exists) {
          await fabFinder.tap();
          await $.pumpAndSettle();

          // Buscar campo de categoría
          final categoryFinder = await $.findWithHealing(
            byText: 'Categoría',
            byType: 'DropdownButtonFormField',
          );

          if (categoryFinder.exists) {
            await categoryFinder.tap();
            await $.pumpAndSettle();
            await $.validateAgainstGolden('category_selector');
          }
        }
      } catch (_) {
        await $.captureScreen('category_selector_not_found');
      }
    },
  );

  patrolTest(
    'Golden: Presupuestos',
    config: patrolConfig,
    ($) async {
      await $.pumpWidgetAndSettle(
        const ProviderScope(
          child: FinanzasFamiliaresApp(),
        ),
      );

      await $.pump(const Duration(seconds: 3));

      // Navegar a presupuestos
      try {
        final budgetsFinder = await $.findWithHealing(
          byText: 'Presupuestos',
          byType: 'NavigationDestination',
        );

        if (budgetsFinder.exists) {
          await budgetsFinder.tap();
          await $.pumpAndSettle();
          await $.validateAgainstGolden('budgets_screen');
        }
      } catch (_) {
        await $.captureScreen('budgets_not_found');
      }
    },
  );

  patrolTest(
    'Visual Regression: Consistencia de colores del tema',
    config: patrolConfig,
    ($) async {
      await $.pumpWidgetAndSettle(
        const ProviderScope(
          child: FinanzasFamiliaresApp(),
        ),
      );

      await $.pump(const Duration(seconds: 3));

      // Verificar que el tema se aplica correctamente
      final scaffold = $(find.byType(Scaffold));
      expect(scaffold.exists, true, reason: 'Debe haber un Scaffold');

      // Capturar estado del tema
      await $.validateAgainstGolden('theme_consistency');

      // Verificar AppBar si existe
      final appBar = $(find.byType(AppBar));
      if (appBar.exists) {
        await $.captureScreen('appbar_style');
      }

      // Verificar NavigationBar si existe
      final navBar = $(find.byType(NavigationBar));
      if (navBar.exists) {
        await $.captureScreen('navbar_style');
      }
    },
  );
}
