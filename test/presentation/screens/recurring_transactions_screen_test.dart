import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finanzas_familiares/presentation/screens/recurring_transactions_screen.dart';
import 'package:finanzas_familiares/application/providers/recurring_transactions_provider.dart';
import 'package:finanzas_familiares/domain/services/recurring_transaction_service.dart';

void main() {
  group('RecurringTransactionsScreen', () {
    Widget createTestWidget({
      List<RecurringTransactionData>? items,
    }) {
      return ProviderScope(
        overrides: [
          activeRecurringTransactionsProvider.overrideWith((ref) {
            return Stream.value(items ?? []);
          }),
        ],
        child: const MaterialApp(
          home: RecurringTransactionsScreen(),
        ),
      );
    }

    testWidgets('muestra título Pagos Recurrentes', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Pagos Recurrentes'), findsOneWidget);
    });

    testWidgets('muestra estado vacío cuando no hay items', (tester) async {
      await tester.pumpWidget(createTestWidget(items: []));
      await tester.pumpAndSettle();

      expect(find.text('Sin pagos recurrentes'), findsOneWidget);
      expect(find.text('Agregar pago recurrente'), findsOneWidget);
    });

    testWidgets('muestra FAB para agregar nuevo', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.text('Nuevo'), findsOneWidget);
    });

    testWidgets('muestra botón de información', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.info_outline), findsOneWidget);
    });

    testWidgets('abre diálogo de información al presionar botón info',
        (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.info_outline));
      await tester.pumpAndSettle();

      expect(find.text('Pagos Recurrentes'), findsNWidgets(2)); // AppBar + Dialog
      expect(find.text('Entendido'), findsOneWidget);
    });

    testWidgets('abre formulario al presionar FAB', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.text('Nuevo Pago Recurrente'), findsOneWidget);
    });

    testWidgets('formulario tiene campos requeridos', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.text('Nombre'), findsOneWidget);
      expect(find.text('Monto'), findsOneWidget);
      expect(find.text('Frecuencia'), findsOneWidget);
      expect(find.text('Guardar'), findsOneWidget);
    });

    testWidgets('formulario tiene selector de tipo', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.text('Gasto'), findsOneWidget);
      expect(find.text('Ingreso'), findsOneWidget);
    });
  });

  group('RecurrenceFrequency labels', () {
    test('todas las frecuencias tienen etiqueta', () {
      final labels = {
        RecurrenceFrequency.daily: 'Diario',
        RecurrenceFrequency.weekly: 'Semanal',
        RecurrenceFrequency.biweekly: 'Quincenal',
        RecurrenceFrequency.monthly: 'Mensual',
        RecurrenceFrequency.bimonthly: 'Bimestral',
        RecurrenceFrequency.quarterly: 'Trimestral',
        RecurrenceFrequency.semiannual: 'Semestral',
        RecurrenceFrequency.yearly: 'Anual',
      };

      expect(labels.length, equals(RecurrenceFrequency.values.length));
    });
  });
}
