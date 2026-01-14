import 'package:flutter_test/flutter_test.dart';
import 'package:finanzas_familiares/application/providers/financial_indicators_provider.dart';

/// Tests para los indicadores financieros personales
/// Basados en la Guía de Modo Personal v1.1 - Sección 7
void main() {
  group('FinancialIndicators', () {
    group('Cobertura de Deuda', () {
      test('calcula correctamente cuando hay suficiente liquidez', () {
        // Arrange
        const indicator = DebtCoverageIndicator(
          availableCash: 5000000, // 5M en efectivo/bancos
          immediateDebts: 2000000, // 2M en tarjetas/cuentas por pagar
        );

        // Assert
        expect(indicator.ratio, equals(2.5)); // 5M / 2M = 2.5
        expect(indicator.hasFullCoverage, isTrue);
        expect(indicator.status, equals(IndicatorStatus.good));
      });

      test('indica advertencia cuando cobertura es baja pero >= 0.8', () {
        // Arrange - ratio 0.9 (warning zone: 0.8 - 1.5)
        const indicator = DebtCoverageIndicator(
          availableCash: 1800000,
          immediateDebts: 2000000,
        );

        // Assert
        expect(indicator.ratio, equals(0.9));
        expect(indicator.hasFullCoverage, isFalse);
        expect(indicator.status, equals(IndicatorStatus.warning));
      });

      test('indica peligro cuando no hay cobertura', () {
        // Arrange
        const indicator = DebtCoverageIndicator(
          availableCash: 500000,
          immediateDebts: 2000000,
        );

        // Assert
        expect(indicator.ratio, equals(0.25));
        expect(indicator.hasFullCoverage, isFalse);
        expect(indicator.status, equals(IndicatorStatus.danger));
      });

      test('maneja caso sin deudas', () {
        // Arrange
        const indicator = DebtCoverageIndicator(
          availableCash: 5000000,
          immediateDebts: 0,
        );

        // Assert
        expect(indicator.ratio, equals(double.infinity));
        expect(indicator.hasFullCoverage, isTrue);
        expect(indicator.status, equals(IndicatorStatus.good));
      });
    });

    group('Peso del Mercado (Alimentación)', () {
      test('calcula porcentaje de ingresos en alimentación', () {
        // Arrange
        const indicator = FoodWeightIndicator(
          totalIncome: 4000000, // 4M de ingresos
          foodExpenses: 800000, // 800K en alimentación
        );

        // Assert
        expect(indicator.percentage, equals(20.0)); // 800K / 4M = 20%
        expect(indicator.status, equals(IndicatorStatus.good));
      });

      test('indica advertencia cuando supera 30%', () {
        // Arrange
        const indicator = FoodWeightIndicator(
          totalIncome: 4000000,
          foodExpenses: 1400000, // 35%
        );

        // Assert
        expect(indicator.percentage, equals(35.0));
        expect(indicator.status, equals(IndicatorStatus.warning));
      });

      test('indica peligro cuando supera 40%', () {
        // Arrange
        const indicator = FoodWeightIndicator(
          totalIncome: 4000000,
          foodExpenses: 2000000, // 50%
        );

        // Assert
        expect(indicator.percentage, equals(50.0));
        expect(indicator.status, equals(IndicatorStatus.danger));
      });
    });

    group('Índice Saludable', () {
      test('calcula ratio saludable vs no saludable', () {
        // Arrange - Más gasto en frutas/verduras que en mecato/domicilios
        const indicator = HealthyIndexIndicator(
          healthySpending: 300000, // Frutas, verduras, etc.
          unhealthySpending: 100000, // Mecato, domicilios
        );

        // Assert
        expect(indicator.ratio, equals(3.0)); // 3:1 saludable
        expect(indicator.isHealthy, isTrue);
        expect(indicator.status, equals(IndicatorStatus.good));
      });

      test('indica advertencia cuando ratio es cercano a 1', () {
        // Arrange
        const indicator = HealthyIndexIndicator(
          healthySpending: 150000,
          unhealthySpending: 150000,
        );

        // Assert
        expect(indicator.ratio, equals(1.0));
        expect(indicator.isHealthy, isFalse);
        expect(indicator.status, equals(IndicatorStatus.warning));
      });

      test('indica peligro cuando gasto no saludable supera al saludable', () {
        // Arrange
        const indicator = HealthyIndexIndicator(
          healthySpending: 100000,
          unhealthySpending: 300000,
        );

        // Assert
        expect(indicator.ratio, closeTo(0.33, 0.01));
        expect(indicator.isHealthy, isFalse);
        expect(indicator.status, equals(IndicatorStatus.danger));
      });
    });

    group('Costo Financiero', () {
      test('suma 4x1000 e intereses de tarjetas', () {
        // Arrange
        const indicator = FinancialCostIndicator(
          gmfCost: 40000, // 4x1000 del mes
          creditCardInterest: 150000, // Intereses TC
          totalIncome: 4000000,
        );

        // Assert
        expect(indicator.totalCost, equals(190000));
        expect(indicator.percentageOfIncome, closeTo(4.75, 0.01));
        expect(indicator.status, equals(IndicatorStatus.warning));
      });

      test('indica buen estado cuando costo es menor al 2%', () {
        // Arrange
        const indicator = FinancialCostIndicator(
          gmfCost: 20000,
          creditCardInterest: 0,
          totalIncome: 4000000,
        );

        // Assert
        expect(indicator.totalCost, equals(20000));
        expect(indicator.percentageOfIncome, equals(0.5));
        expect(indicator.status, equals(IndicatorStatus.good));
      });

      test('indica peligro cuando costo supera 5%', () {
        // Arrange
        const indicator = FinancialCostIndicator(
          gmfCost: 50000,
          creditCardInterest: 200000,
          totalIncome: 4000000,
        );

        // Assert
        expect(indicator.totalCost, equals(250000));
        expect(indicator.percentageOfIncome, equals(6.25));
        expect(indicator.status, equals(IndicatorStatus.danger));
      });
    });

    group('Saldo Disponible Real', () {
      test('calcula correctamente (Efectivo + Bancos) - Deudas Inmediatas', () {
        // Arrange
        const indicator = AvailableBalanceIndicator(
          cashBalance: 500000,
          bankBalance: 3000000,
          immediatePayables: 800000,
        );

        // Assert
        expect(indicator.grossBalance, equals(3500000));
        expect(indicator.netBalance, equals(2700000));
        expect(indicator.hasPositiveBalance, isTrue);
      });

      test('indica saldo negativo cuando deudas superan disponible', () {
        // Arrange
        const indicator = AvailableBalanceIndicator(
          cashBalance: 200000,
          bankBalance: 500000,
          immediatePayables: 1000000,
        );

        // Assert
        expect(indicator.grossBalance, equals(700000));
        expect(indicator.netBalance, equals(-300000));
        expect(indicator.hasPositiveBalance, isFalse);
        expect(indicator.status, equals(IndicatorStatus.danger));
      });
    });
  });
}
