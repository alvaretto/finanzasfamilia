import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finanzas_familiares/presentation/widgets/traffic_light_indicator.dart';

/// Tests para el widget de semáforo de presupuesto
/// Verde: < 80%
/// Amarillo: 80-99%
/// Rojo: >= 100%
void main() {
  group('TrafficLightIndicator Widget', () {
    testWidgets('muestra verde cuando el gasto es menor al 80%',
        (WidgetTester tester) async {
      // Arrange - 50% del presupuesto usado
      const data = TrafficLightData(
        budgetAmount: 100000,
        spent: 50000,
        percentage: 50.0,
        status: TrafficLightStatus.safe,
      );

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TrafficLightIndicator(data: data),
          ),
        ),
      );

      // Assert
      final indicator = find.byType(TrafficLightIndicator);
      expect(indicator, findsOneWidget);

      // Debe mostrar color verde
      final container = tester.widget<Container>(
        find.descendant(
          of: indicator,
          matching: find.byType(Container),
        ).first,
      );

      final decoration = container.decoration as BoxDecoration?;
      expect(decoration?.color, equals(Colors.green));
    });

    testWidgets('muestra amarillo cuando el gasto está entre 80% y 99%',
        (WidgetTester tester) async {
      // Arrange - 85% del presupuesto usado
      const data = TrafficLightData(
        budgetAmount: 100000,
        spent: 85000,
        percentage: 85.0,
        status: TrafficLightStatus.warning,
      );

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TrafficLightIndicator(data: data),
          ),
        ),
      );

      // Assert
      final indicator = find.byType(TrafficLightIndicator);
      final container = tester.widget<Container>(
        find.descendant(
          of: indicator,
          matching: find.byType(Container),
        ).first,
      );

      final decoration = container.decoration as BoxDecoration?;
      expect(decoration?.color, equals(Colors.amber));
    });

    testWidgets('muestra rojo cuando el gasto supera el 100%',
        (WidgetTester tester) async {
      // Arrange - 120% del presupuesto usado
      const data = TrafficLightData(
        budgetAmount: 100000,
        spent: 120000,
        percentage: 120.0,
        status: TrafficLightStatus.exceeded,
      );

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TrafficLightIndicator(data: data),
          ),
        ),
      );

      // Assert
      final indicator = find.byType(TrafficLightIndicator);
      final container = tester.widget<Container>(
        find.descendant(
          of: indicator,
          matching: find.byType(Container),
        ).first,
      );

      final decoration = container.decoration as BoxDecoration?;
      expect(decoration?.color, equals(Colors.red));
    });

    testWidgets('muestra el porcentaje correctamente',
        (WidgetTester tester) async {
      // Arrange
      const data = TrafficLightData(
        budgetAmount: 100000,
        spent: 75000,
        percentage: 75.0,
        status: TrafficLightStatus.safe,
      );

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TrafficLightIndicator(data: data),
          ),
        ),
      );

      // Assert - Debe mostrar "75%"
      expect(find.text('75%'), findsOneWidget);
    });

    testWidgets('muestra el monto gastado y el límite',
        (WidgetTester tester) async {
      // Arrange
      const data = TrafficLightData(
        budgetAmount: 500000,
        spent: 250000,
        percentage: 50.0,
        status: TrafficLightStatus.safe,
      );

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TrafficLightIndicator(
              data: data,
              showAmounts: true,
            ),
          ),
        ),
      );

      // Assert - Debe mostrar montos formateados
      expect(find.textContaining('250'), findsWidgets);
      expect(find.textContaining('500'), findsWidgets);
    });

    testWidgets('muestra indicador compacto sin detalles',
        (WidgetTester tester) async {
      // Arrange
      const data = TrafficLightData(
        budgetAmount: 100000,
        spent: 90000,
        percentage: 90.0,
        status: TrafficLightStatus.warning,
      );

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TrafficLightIndicator(
              data: data,
              compact: true,
            ),
          ),
        ),
      );

      // Assert - En modo compacto no muestra porcentaje en texto
      expect(find.text('90%'), findsNothing);
    });

    testWidgets('factory fromPercentage calcula status correctamente',
        (WidgetTester tester) async {
      // Test del factory method
      final safeData = TrafficLightData.fromPercentage(
        spent: 70000,
        budgetAmount: 100000,
      );
      expect(safeData.status, equals(TrafficLightStatus.safe));
      expect(safeData.percentage, equals(70.0));

      final warningData = TrafficLightData.fromPercentage(
        spent: 85000,
        budgetAmount: 100000,
      );
      expect(warningData.status, equals(TrafficLightStatus.warning));

      final exceededData = TrafficLightData.fromPercentage(
        spent: 150000,
        budgetAmount: 100000,
      );
      expect(exceededData.status, equals(TrafficLightStatus.exceeded));
    });
  });
}
