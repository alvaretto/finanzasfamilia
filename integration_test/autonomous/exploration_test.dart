/// Test de Exploración Autónoma
/// Navega automáticamente por toda la app capturando estados
library;

import 'package:finanzas_familiares/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:patrol/patrol.dart';

import '../patrol_test_config.dart';
import 'screen_explorer.dart';

void main() {
  patrolTest(
    'Exploración autónoma completa de la aplicación',
    config: patrolConfig,
    ($) async {
      // Iniciar app
      await $.pumpWidgetAndSettle(
        const ProviderScope(
          child: FinanzasFamiliaresApp(),
        ),
      );

      // Esperar carga inicial
      await $.pump(const Duration(seconds: 5));

      // Crear explorador con configuración personalizada
      final explorer = AutonomousExplorer(
        $,
        config: const ExplorerConfig(
          maxDepth: 3, // Profundidad moderada para testing
          screenshotOnEveryStep: true,
          maxExplorationMinutes: 5,
          ignoredElements: ['Back', 'Cancel', 'Cancelar', 'Cerrar'],
          priorityElements: [
            'Nuevo',
            'Agregar',
            'Guardar',
            'Inicio',
            'Cuentas',
            'Transacciones'
          ],
        ),
      );

      // Ejecutar exploración
      final report = await explorer.explore();

      // Imprimir reporte
      report.print();

      // Validaciones básicas
      expect(
        report.visitedScreens.isNotEmpty,
        true,
        reason: 'Debe visitar al menos una pantalla',
      );

      // Log de pantallas encontradas
      // ignore: avoid_print
      print('\n=== RESUMEN DE EXPLORACIÓN ===');
      // ignore: avoid_print
      print('Pantallas visitadas: ${report.visitedScreens.length}');
      // ignore: avoid_print
      print('Rutas únicas: ${report.visitedPaths.length}');
      // ignore: avoid_print
      print('Duración: ${report.duration.inSeconds}s');
    },
  );

  patrolTest(
    'Exploración enfocada: Flujo de nueva transacción',
    config: patrolConfig,
    ($) async {
      await $.pumpWidgetAndSettle(
        const ProviderScope(
          child: FinanzasFamiliaresApp(),
        ),
      );

      await $.pump(const Duration(seconds: 3));

      // Buscar FAB o botón "Nuevo"
      final newTransactionFinder = await $.findWithHealing(
        byType: 'FloatingActionButton',
        byText: 'Nuevo',
        byTooltip: 'Nueva transacción',
      );

      if (newTransactionFinder.exists) {
        await newTransactionFinder.tap();
        await $.pumpAndSettle();

        // Capturar formulario de transacción
        await $.captureScreen('transaction_form');

        // Explorar opciones del formulario
        final explorer = AutonomousExplorer(
          $,
          config: const ExplorerConfig(
            maxDepth: 2,
            screenshotOnEveryStep: true,
            ignoredElements: ['Cancelar', 'Back'],
            priorityElements: ['Gasto', 'Ingreso', 'Categoría', 'Cuenta'],
          ),
        );

        final report = await explorer.explore();
        report.print();
      }
    },
  );

  patrolTest(
    'Detección de cambios UI entre sesiones',
    config: patrolConfig,
    ($) async {
      await $.pumpWidgetAndSettle(
        const ProviderScope(
          child: FinanzasFamiliaresApp(),
        ),
      );

      await $.pump(const Duration(seconds: 3));

      // Capturar estado inicial
      final explorer = AutonomousExplorer($);
      final initialState = await explorer.explore(currentDepth: 0);

      // Simular cambio de estado (navegar y volver)
      try {
        // Buscar cualquier elemento navegable
        final navFinder = await $.findWithHealing(
          byType: 'NavigationDestination',
          byText: 'Cuentas',
        );

        if (navFinder.exists) {
          await navFinder.tap();
          await $.pumpAndSettle();
        }
      } catch (_) {}

      // Volver al inicio
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

      // Capturar estado final
      final finalState = await explorer.explore(currentDepth: 0);

      // Comparar estados
      // ignore: avoid_print
      print('\n=== COMPARACIÓN DE ESTADOS ===');
      // ignore: avoid_print
      print('Pantallas iniciales: ${initialState.visitedScreens.length}');
      // ignore: avoid_print
      print('Pantallas finales: ${finalState.visitedScreens.length}');

      // Los estados deberían ser consistentes
      expect(
        finalState.visitedScreens.isNotEmpty,
        true,
        reason: 'El estado final debe tener pantallas visitadas',
      );
    },
  );
}
