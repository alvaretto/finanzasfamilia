import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finanzas_familiares/data/local/database.dart';
import 'package:finanzas_familiares/data/local/daos/daos.dart';
import 'package:finanzas_familiares/application/providers/dashboard_provider.dart';
import 'package:finanzas_familiares/application/providers/database_provider.dart';
import 'package:finanzas_familiares/application/providers/financial_indicators_provider.dart';

/// Tests para el Dashboard "¿Cómo Voy?"
/// Basado en la Guía de Modo Personal v1.1 - Sección 6.2
void main() {
  late AppDatabase database;
  late ProviderContainer container;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(database),
        categoriesDaoProvider.overrideWithValue(CategoriesDao(database)),
        transactionsDaoProvider.overrideWithValue(TransactionsDao(database)),
        budgetsDaoProvider.overrideWithValue(BudgetsDao(database)),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await database.close();
  });

  group('DashboardProvider', () {
    test('calcula resumen del mes con totales por categoría', () async {
      // Arrange - Crear categorías y transacciones de prueba
      final dashboardData = await container.read(
        dashboardSummaryProvider.future,
      );

      // Assert - Debe retornar estructura de dashboard
      expect(dashboardData, isA<DashboardSummary>());
      expect(dashboardData.totalIncome, isA<double>());
      expect(dashboardData.totalExpenses, isA<double>());
      expect(dashboardData.netBalance, isA<double>());
    });

    test('agrupa gastos por categoría maestra', () async {
      // Arrange
      final dashboardData = await container.read(
        dashboardSummaryProvider.future,
      );

      // Assert - Debe tener lista de gastos por categoría
      expect(dashboardData.expensesByCategory, isA<List<CategoryExpense>>());
    });

    test('calcula patrimonio neto (Activos - Pasivos)', () async {
      // Arrange
      final dashboardData = await container.read(
        dashboardSummaryProvider.future,
      );

      // Assert
      expect(dashboardData.netWorth, isA<double>());
      // Patrimonio = Total Activos - Total Pasivos
      expect(
        dashboardData.netWorth,
        equals(dashboardData.totalAssets - dashboardData.totalLiabilities),
      );
    });

    test('incluye indicadores financieros', () async {
      // Arrange
      final dashboardData = await container.read(
        dashboardSummaryProvider.future,
      );

      // Assert
      expect(dashboardData.availableBalance, isA<double>());
      expect(dashboardData.budgetAlerts, isA<List<BudgetAlert>>());
    });

    test('netBalance es ingresos menos gastos', () async {
      // Arrange
      final dashboardData = await container.read(
        dashboardSummaryProvider.future,
      );

      // Assert
      expect(
        dashboardData.netBalance,
        equals(dashboardData.totalIncome - dashboardData.totalExpenses),
      );
    });
  });

  group('MonthSummaryProvider', () {
    test('retorna resumen simplificado del mes', () async {
      // Arrange
      final now = DateTime.now();
      final summary = await container.read(
        monthSummaryProvider(now.month, now.year).future,
      );

      // Assert
      expect(summary, isA<MonthSummary>());
      expect(summary.month, equals(now.month));
      expect(summary.year, equals(now.year));
      expect(summary.incomeTotal, isA<double>());
      expect(summary.expenseTotal, isA<double>());
    });

    test('agrupa subcategorías en categorías maestras', () async {
      // Por ejemplo: Frutas, Verduras, Carnes -> total "Mercado"
      final now = DateTime.now();
      final summary = await container.read(
        monthSummaryProvider(now.month, now.year).future,
      );

      // Assert - Las categorías deben estar agrupadas
      expect(summary.expenseGroups, isA<List<ExpenseGroup>>());
    });

    test('netBalance es igual a ingresos menos gastos', () async {
      // Arrange
      final now = DateTime.now();
      final summary = await container.read(
        monthSummaryProvider(now.month, now.year).future,
      );

      // Assert
      expect(
        summary.netBalance,
        equals(summary.incomeTotal - summary.expenseTotal),
      );
    });
  });

  group('CategoryExpense', () {
    test('calcula porcentaje correctamente', () {
      const expense = CategoryExpense(
        categoryId: 'test',
        categoryName: 'Test',
        amount: 250000,
        percentage: 25.0,
      );

      expect(expense.percentage, equals(25.0));
    });
  });

  group('BudgetAlert', () {
    test('isOverBudget es true cuando percentage >= 100', () {
      const alert = BudgetAlert(
        categoryId: 'test',
        categoryName: 'Test',
        budgetAmount: 100000,
        spentAmount: 120000,
        percentage: 120.0,
        status: IndicatorStatus.danger,
      );

      expect(alert.isOverBudget, isTrue);
      expect(alert.isWarning, isFalse);
    });

    test('isWarning es true cuando percentage >= 80 y < 100', () {
      const alert = BudgetAlert(
        categoryId: 'test',
        categoryName: 'Test',
        budgetAmount: 100000,
        spentAmount: 85000,
        percentage: 85.0,
        status: IndicatorStatus.warning,
      );

      expect(alert.isOverBudget, isFalse);
      expect(alert.isWarning, isTrue);
    });
  });
}
