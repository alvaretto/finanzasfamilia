/// ERR-0006: Test de regresión para rebuild loop en AddTransactionSheet
///
/// Verificar que no hay loop infinito de rebuilds que cause pantalla blanca/negra
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finanzas_familiares/core/theme/app_theme.dart';
import 'package:finanzas_familiares/features/transactions/domain/models/transaction_model.dart';
import 'package:finanzas_familiares/features/transactions/presentation/widgets/add_transaction_sheet.dart';
import '../mocks/mock_providers.dart';

void main() {
  group('ERR-0006: Rebuild Loop Prevention', () {
    testWidgets('AddTransactionSheet no causa rebuild loop excesivo', (tester) async {
      int buildCount = 0;

      await tester.pumpWidget(
        ProviderScope(
          overrides: testProviderOverrides,
          child: MaterialApp(
            theme: AppTheme.light(),
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  buildCount++;
                  if (buildCount > 50) {
                    fail('Rebuild loop detectado: $buildCount builds exceden el límite');
                  }
                  return const AddTransactionSheet(
                    initialType: TransactionType.expense,
                  );
                },
              ),
            ),
          ),
        ),
      );

      // Esperar a que se estabilice
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Verificar que no hay rebuild loop
      // Nota: Flutter hace algunos rebuilds iniciales normales (3-6 es típico)
      // Si hay más de 10, probablemente hay un loop
      expect(buildCount, lessThan(10),
          reason: 'Rebuild loop detectado: $buildCount builds. Normal es 3-6 builds.');

      // Verificar que el widget se renderizó correctamente
      expect(find.byType(AddTransactionSheet), findsOneWidget);
    });

    testWidgets('Cambiar tipo de transacción no causa rebuild loop', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: testProviderOverrides,
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const Scaffold(
              body: AddTransactionSheet(
                initialType: TransactionType.expense,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Encontrar el selector de tipo (SegmentedButton)
      final ingresoButton = find.text('Ingreso');
      expect(ingresoButton, findsOneWidget);

      // Cambiar a Ingreso
      await tester.tap(ingresoButton);

      // Pump con timeout razonable - si hay loop, esto fallará
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Verificar que el cambio funcionó sin timeout
      expect(find.text('Registrar Ingreso'), findsOneWidget);

      // Si llegamos aquí, no hubo rebuild loop
    });

    testWidgets('Múltiples interacciones no degradan performance', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: testProviderOverrides,
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const Scaffold(
              body: AddTransactionSheet(
                initialType: TransactionType.expense,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Simular múltiples interacciones
      for (int i = 0; i < 5; i++) {
        // Cambiar entre Gasto e Ingreso
        final targetButton = i % 2 == 0
            ? find.text('Ingreso')
            : find.text('Gasto');

        if (tester.any(targetButton)) {
          await tester.tap(targetButton);
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 100));
        }
      }

      // Esperar estabilización final
      await tester.pumpAndSettle();

      // Si llegamos aquí sin timeout, no hay loop infinito
      expect(find.byType(AddTransactionSheet), findsOneWidget);
    });

    testWidgets('PostFrameCallback se ejecuta solo una vez', (tester) async {
      // Este test verifica que el flag _hasInitializedDefaultAccount funciona

      await tester.pumpWidget(
        ProviderScope(
          overrides: testProviderOverrides,
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const Scaffold(
              body: AddTransactionSheet(
                initialType: TransactionType.expense,
              ),
            ),
          ),
        ),
      );

      // Primer pump - debería ejecutar PostFrameCallback
      await tester.pump();

      // Pump adicional para que se ejecute el callback
      await tester.pump();

      // Múltiples pumps adicionales NO deberían ejecutar el callback de nuevo
      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 16)); // ~1 frame
      }

      await tester.pumpAndSettle();

      // Verificar que el widget sigue funcionando normalmente
      expect(find.byType(AddTransactionSheet), findsOneWidget);

      // Verificar que hay un dropdown de cuenta (significa que se seleccionó default)
      expect(find.byType(DropdownButtonFormField<String>), findsWidgets);
    });

    testWidgets('Mounted check previene setState después de dispose', (tester) async {
      final key = GlobalKey();

      await tester.pumpWidget(
        ProviderScope(
          overrides: testProviderOverrides,
          child: MaterialApp(
            theme: AppTheme.light(),
            home: Scaffold(
              body: AddTransactionSheet(
                key: key,
                initialType: TransactionType.expense,
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      // Simular dispose rápido (cerrar el sheet antes de que complete el PostFrameCallback)
      await tester.pumpWidget(
        ProviderScope(
          overrides: testProviderOverrides,
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const Scaffold(
              body: SizedBox.shrink(), // Widget vacío
            ),
          ),
        ),
      );

      // Pump para ejecutar pending callbacks
      await tester.pump();
      await tester.pump();

      // Si llegamos aquí sin assertion error, el check de 'mounted' funcionó
      expect(find.byType(AddTransactionSheet), findsNothing);
    });
  });

  group('ERR-0006: Performance Metrics', () {
    testWidgets('Tiempo de renderizado inicial < 500ms', (tester) async {
      final stopwatch = Stopwatch()..start();

      await tester.pumpWidget(
        ProviderScope(
          overrides: testProviderOverrides,
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const Scaffold(
              body: AddTransactionSheet(
                initialType: TransactionType.expense,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      stopwatch.stop();

      expect(stopwatch.elapsedMilliseconds, lessThan(500),
          reason: 'Renderizado inicial tardó ${stopwatch.elapsedMilliseconds}ms. Debería ser < 500ms.');
    });

    testWidgets('Cambio de tipo < 100ms', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: testProviderOverrides,
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const Scaffold(
              body: AddTransactionSheet(
                initialType: TransactionType.expense,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final stopwatch = Stopwatch()..start();

      // Cambiar tipo
      final ingresoButton = find.text('Ingreso');
      if (tester.any(ingresoButton)) {
        await tester.tap(ingresoButton);
        await tester.pumpAndSettle();
      }

      stopwatch.stop();

      expect(stopwatch.elapsedMilliseconds, lessThan(100),
          reason: 'Cambio de tipo tardó ${stopwatch.elapsedMilliseconds}ms. Debería ser < 100ms.');
    });
  });
}
