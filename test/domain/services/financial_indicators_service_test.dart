import 'package:flutter_test/flutter_test.dart';

import 'package:finanzas_familiares/domain/entities/dashboard/indicator_status.dart';
import 'package:finanzas_familiares/domain/entities/indicators/financial_indicators.dart';
import 'package:finanzas_familiares/domain/services/financial_indicators_service.dart';

/// In-memory implementation of AccountDataRepository for testing
class InMemoryAccountDataRepository implements AccountDataRepository {
  final List<AccountBalance> _accounts;
  final List<CategoryInfo> _categories;

  InMemoryAccountDataRepository({
    List<AccountBalance>? accounts,
    List<CategoryInfo>? categories,
  })  : _accounts = accounts ?? [],
        _categories = categories ?? [];

  @override
  Future<List<AccountBalance>> getAllAccountBalances() async => _accounts;

  @override
  Future<List<CategoryInfo>> getCategoriesByType(String type) async =>
      _categories.where((c) => c.type == type).toList();
}

void main() {
  group('DebtCoverageIndicator', () {
    test('ratio es infinity cuando no hay deudas', () {
      const indicator = DebtCoverageIndicator(
        availableCash: 1000000,
        immediateDebts: 0,
      );

      expect(indicator.ratio, double.infinity);
      expect(indicator.hasFullCoverage, isTrue);
      expect(indicator.status, IndicatorStatus.good);
    });

    test('ratio calcula correctamente con deudas', () {
      const indicator = DebtCoverageIndicator(
        availableCash: 1500000,
        immediateDebts: 1000000,
      );

      expect(indicator.ratio, 1.5);
      expect(indicator.hasFullCoverage, isTrue);
      expect(indicator.status, IndicatorStatus.good);
    });

    test('status es warning cuando ratio < 1.5 pero >= 0.8', () {
      const indicator = DebtCoverageIndicator(
        availableCash: 900000,
        immediateDebts: 1000000,
      );

      expect(indicator.ratio, 0.9);
      expect(indicator.hasFullCoverage, isFalse);
      expect(indicator.status, IndicatorStatus.warning);
    });

    test('status es danger cuando ratio < 0.8', () {
      const indicator = DebtCoverageIndicator(
        availableCash: 500000,
        immediateDebts: 1000000,
      );

      expect(indicator.ratio, 0.5);
      expect(indicator.hasFullCoverage, isFalse);
      expect(indicator.status, IndicatorStatus.danger);
    });

    test('message indica cuántas veces puede cubrir deudas', () {
      const indicator = DebtCoverageIndicator(
        availableCash: 2000000,
        immediateDebts: 1000000,
      );

      expect(indicator.message, contains('2.0x'));
    });

    test('message indica faltante cuando no cubre deudas', () {
      const indicator = DebtCoverageIndicator(
        availableCash: 500000,
        immediateDebts: 1000000,
      );

      expect(indicator.message, contains('falta'));
      expect(indicator.message, contains('500000'));
    });
  });

  group('FoodWeightIndicator', () {
    test('percentage calcula correctamente', () {
      const indicator = FoodWeightIndicator(
        totalIncome: 5000000,
        foodExpenses: 1500000,
      );

      expect(indicator.percentage, 30);
    });

    test('percentage es 0 cuando no hay ingresos', () {
      const indicator = FoodWeightIndicator(
        totalIncome: 0,
        foodExpenses: 100000,
      );

      expect(indicator.percentage, 0);
    });

    test('status es good cuando <= 30%', () {
      const indicator = FoodWeightIndicator(
        totalIncome: 5000000,
        foodExpenses: 1500000,
      );

      expect(indicator.status, IndicatorStatus.good);
    });

    test('status es warning cuando > 30% y <= 40%', () {
      const indicator = FoodWeightIndicator(
        totalIncome: 5000000,
        foodExpenses: 1750000,
      );

      expect(indicator.percentage, 35);
      expect(indicator.status, IndicatorStatus.warning);
    });

    test('status es danger cuando > 40%', () {
      const indicator = FoodWeightIndicator(
        totalIncome: 5000000,
        foodExpenses: 2500000,
      );

      expect(indicator.percentage, 50);
      expect(indicator.status, IndicatorStatus.danger);
    });
  });

  group('HealthyIndexIndicator', () {
    test('ratio es infinity cuando no hay gasto no saludable', () {
      const indicator = HealthyIndexIndicator(
        healthySpending: 500000,
        unhealthySpending: 0,
      );

      expect(indicator.ratio, double.infinity);
      expect(indicator.isHealthy, isTrue);
      expect(indicator.status, IndicatorStatus.good);
    });

    test('status es good cuando ratio >= 2', () {
      const indicator = HealthyIndexIndicator(
        healthySpending: 400000,
        unhealthySpending: 200000,
      );

      expect(indicator.ratio, 2.0);
      expect(indicator.status, IndicatorStatus.good);
    });

    test('status es warning cuando ratio >= 1 y < 2', () {
      const indicator = HealthyIndexIndicator(
        healthySpending: 300000,
        unhealthySpending: 200000,
      );

      expect(indicator.ratio, 1.5);
      expect(indicator.status, IndicatorStatus.warning);
    });

    test('status es danger cuando ratio < 1', () {
      const indicator = HealthyIndexIndicator(
        healthySpending: 150000,
        unhealthySpending: 300000,
      );

      expect(indicator.ratio, 0.5);
      expect(indicator.isHealthy, isFalse);
      expect(indicator.status, IndicatorStatus.danger);
    });

    test('message describe gasto saludable cuando isHealthy', () {
      const indicator = HealthyIndexIndicator(
        healthySpending: 300000,
        unhealthySpending: 100000,
      );

      expect(indicator.message, contains('3.0x'));
      expect(indicator.message, contains('saludable'));
    });

    test('message advierte sobre mecato cuando no isHealthy', () {
      const indicator = HealthyIndexIndicator(
        healthySpending: 100000,
        unhealthySpending: 300000,
      );

      expect(indicator.message, contains('mecato'));
    });
  });

  group('FinancialCostIndicator', () {
    test('totalCost suma GMF e intereses', () {
      const indicator = FinancialCostIndicator(
        gmfCost: 20000,
        creditCardInterest: 80000,
        totalIncome: 5000000,
      );

      expect(indicator.totalCost, 100000);
    });

    test('percentageOfIncome calcula correctamente', () {
      const indicator = FinancialCostIndicator(
        gmfCost: 20000,
        creditCardInterest: 80000,
        totalIncome: 5000000,
      );

      expect(indicator.percentageOfIncome, 2);
    });

    test('percentageOfIncome es 0 cuando no hay ingresos', () {
      const indicator = FinancialCostIndicator(
        gmfCost: 20000,
        creditCardInterest: 80000,
        totalIncome: 0,
      );

      expect(indicator.percentageOfIncome, 0);
    });

    test('status es good cuando <= 2%', () {
      const indicator = FinancialCostIndicator(
        gmfCost: 50000,
        creditCardInterest: 50000,
        totalIncome: 5000000,
      );

      expect(indicator.percentageOfIncome, 2);
      expect(indicator.status, IndicatorStatus.good);
    });

    test('status es warning cuando > 2% y <= 5%', () {
      const indicator = FinancialCostIndicator(
        gmfCost: 100000,
        creditCardInterest: 100000,
        totalIncome: 5000000,
      );

      expect(indicator.percentageOfIncome, 4);
      expect(indicator.status, IndicatorStatus.warning);
    });

    test('status es danger cuando > 5%', () {
      const indicator = FinancialCostIndicator(
        gmfCost: 150000,
        creditCardInterest: 150000,
        totalIncome: 5000000,
      );

      expect(indicator.percentageOfIncome, 6);
      expect(indicator.status, IndicatorStatus.danger);
    });
  });

  group('AvailableBalanceIndicator', () {
    test('grossBalance suma efectivo y bancos', () {
      const indicator = AvailableBalanceIndicator(
        cashBalance: 500000,
        bankBalance: 1500000,
        immediatePayables: 0,
      );

      expect(indicator.grossBalance, 2000000);
    });

    test('netBalance resta cuentas por pagar', () {
      const indicator = AvailableBalanceIndicator(
        cashBalance: 500000,
        bankBalance: 1500000,
        immediatePayables: 800000,
      );

      expect(indicator.netBalance, 1200000);
    });

    test('hasPositiveBalance es true cuando netBalance > 0', () {
      const indicator = AvailableBalanceIndicator(
        cashBalance: 500000,
        bankBalance: 500000,
        immediatePayables: 900000,
      );

      expect(indicator.netBalance, 100000);
      expect(indicator.hasPositiveBalance, isTrue);
    });

    test('hasPositiveBalance es false cuando netBalance <= 0', () {
      const indicator = AvailableBalanceIndicator(
        cashBalance: 500000,
        bankBalance: 500000,
        immediatePayables: 1100000,
      );

      expect(indicator.netBalance, -100000);
      expect(indicator.hasPositiveBalance, isFalse);
    });

    test('status es good cuando netBalance > 0', () {
      const indicator = AvailableBalanceIndicator(
        cashBalance: 500000,
        bankBalance: 500000,
        immediatePayables: 500000,
      );

      expect(indicator.status, IndicatorStatus.good);
    });

    test('status es warning cuando netBalance >= -100000', () {
      const indicator = AvailableBalanceIndicator(
        cashBalance: 500000,
        bankBalance: 500000,
        immediatePayables: 1050000,
      );

      expect(indicator.netBalance, -50000);
      expect(indicator.status, IndicatorStatus.warning);
    });

    test('status es danger cuando netBalance < -100000', () {
      const indicator = AvailableBalanceIndicator(
        cashBalance: 500000,
        bankBalance: 500000,
        immediatePayables: 1200000,
      );

      expect(indicator.netBalance, -200000);
      expect(indicator.status, IndicatorStatus.danger);
    });

    test('message indica disponibilidad cuando positivo', () {
      const indicator = AvailableBalanceIndicator(
        cashBalance: 500000,
        bankBalance: 1500000,
        immediatePayables: 0,
      );

      expect(indicator.message, contains('disponibles'));
      expect(indicator.message, contains('2000000'));
    });

    test('message indica "en rojo" cuando negativo', () {
      const indicator = AvailableBalanceIndicator(
        cashBalance: 500000,
        bankBalance: 500000,
        immediatePayables: 1200000,
      );

      expect(indicator.message, contains('rojo'));
    });
  });

  group('FinancialIndicatorsSummary', () {
    test('overallStatus es danger si alguno es danger', () {
      const summary = FinancialIndicatorsSummary(
        debtCoverage: DebtCoverageIndicator(
          availableCash: 2000000,
          immediateDebts: 1000000, // good
        ),
        availableBalance: AvailableBalanceIndicator(
          cashBalance: 100000,
          bankBalance: 100000,
          immediatePayables: 500000, // danger
        ),
      );

      expect(summary.overallStatus, IndicatorStatus.danger);
    });

    test('overallStatus es warning si alguno es warning y ninguno danger', () {
      const summary = FinancialIndicatorsSummary(
        debtCoverage: DebtCoverageIndicator(
          availableCash: 2000000,
          immediateDebts: 1000000, // good
        ),
        availableBalance: AvailableBalanceIndicator(
          cashBalance: 100000,
          bankBalance: 100000,
          immediatePayables: 250000, // warning
        ),
      );

      expect(summary.overallStatus, IndicatorStatus.warning);
    });

    test('overallStatus es good si todos son good', () {
      const summary = FinancialIndicatorsSummary(
        debtCoverage: DebtCoverageIndicator(
          availableCash: 2000000,
          immediateDebts: 1000000, // good
        ),
        availableBalance: AvailableBalanceIndicator(
          cashBalance: 500000,
          bankBalance: 1000000,
          immediatePayables: 500000, // good
        ),
      );

      expect(summary.overallStatus, IndicatorStatus.good);
    });
  });

  group('FinancialIndicatorsService - calculateDebtCoverage', () {
    test('calcula cobertura con cuentas positivas y negativas', () async {
      final repository = InMemoryAccountDataRepository(
        accounts: [
          const AccountBalance(id: 'a1', categoryId: 'c1', balance: 1000000),
          const AccountBalance(id: 'a2', categoryId: 'c2', balance: 500000),
          const AccountBalance(id: 'a3', categoryId: 'c3', balance: -300000),
          const AccountBalance(id: 'a4', categoryId: 'c4', balance: -200000),
        ],
      );

      final service = FinancialIndicatorsService(repository: repository);
      final result = await service.calculateDebtCoverage();

      expect(result.availableCash, 1500000);
      expect(result.immediateDebts, 500000);
      expect(result.ratio, 3.0);
      expect(result.status, IndicatorStatus.good);
    });

    test('maneja caso sin deudas', () async {
      final repository = InMemoryAccountDataRepository(
        accounts: [
          const AccountBalance(id: 'a1', categoryId: 'c1', balance: 1000000),
        ],
      );

      final service = FinancialIndicatorsService(repository: repository);
      final result = await service.calculateDebtCoverage();

      expect(result.availableCash, 1000000);
      expect(result.immediateDebts, 0);
      expect(result.ratio, double.infinity);
    });

    test('maneja caso sin cuentas', () async {
      final repository = InMemoryAccountDataRepository();

      final service = FinancialIndicatorsService(repository: repository);
      final result = await service.calculateDebtCoverage();

      expect(result.availableCash, 0);
      expect(result.immediateDebts, 0);
    });
  });

  group('FinancialIndicatorsService - calculateAvailableBalance', () {
    test('calcula saldo disponible con categorías colombianas', () async {
      final repository = InMemoryAccountDataRepository(
        accounts: [
          const AccountBalance(id: 'a1', categoryId: 'efectivo', balance: 200000),
          const AccountBalance(id: 'a2', categoryId: 'banco', balance: 1000000),
          const AccountBalance(id: 'a3', categoryId: 'tarjeta', balance: 300000),
        ],
        categories: [
          const CategoryInfo(id: 'efectivo', name: 'Efectivo', type: 'asset'),
          const CategoryInfo(id: 'banco', name: 'Banco Ahorros', type: 'asset'),
          const CategoryInfo(id: 'tarjeta', name: 'Tarjeta Crédito', type: 'liability'),
        ],
      );

      final service = FinancialIndicatorsService(repository: repository);
      final result = await service.calculateAvailableBalance();

      expect(result.cashBalance, 200000);
      expect(result.bankBalance, 1000000);
      expect(result.immediatePayables, 300000);
      expect(result.netBalance, 900000);
    });

    test('detecta billetera como efectivo (cash)', () async {
      // El servicio clasifica "billetera" como efectivo
      final repository = InMemoryAccountDataRepository(
        accounts: [
          const AccountBalance(id: 'billetera', categoryId: 'bil', balance: 300000),
        ],
        categories: [
          const CategoryInfo(id: 'bil', name: 'Billetera', type: 'asset'),
        ],
      );

      final service = FinancialIndicatorsService(repository: repository);
      final result = await service.calculateAvailableBalance();

      expect(result.cashBalance, 300000);
    });

    test('detecta Nequi como banco', () async {
      // El servicio clasifica "nequi" como banco
      final repository = InMemoryAccountDataRepository(
        accounts: [
          const AccountBalance(id: 'nequi', categoryId: 'nequi-cat', balance: 500000),
        ],
        categories: [
          const CategoryInfo(id: 'nequi-cat', name: 'Nequi', type: 'asset'),
        ],
      );

      final service = FinancialIndicatorsService(repository: repository);
      final result = await service.calculateAvailableBalance();

      expect(result.bankBalance, 500000);
    });

    test('detecta cuenta por pagar como payable', () async {
      final repository = InMemoryAccountDataRepository(
        accounts: [
          const AccountBalance(id: 'deuda', categoryId: 'pagar', balance: 150000),
        ],
        categories: [
          const CategoryInfo(id: 'pagar', name: 'Cuentas por Pagar', type: 'liability'),
        ],
      );

      final service = FinancialIndicatorsService(repository: repository);
      final result = await service.calculateAvailableBalance();

      expect(result.immediatePayables, 150000);
    });
  });

  group('FinancialIndicatorsService - calculateSummary', () {
    test('genera resumen con todos los indicadores', () async {
      final repository = InMemoryAccountDataRepository(
        accounts: [
          const AccountBalance(id: 'a1', categoryId: 'c1', balance: 1000000),
          const AccountBalance(id: 'a2', categoryId: 'c2', balance: -500000),
        ],
        categories: [
          const CategoryInfo(id: 'c1', name: 'Banco', type: 'asset'),
          const CategoryInfo(id: 'c2', name: 'Tarjeta', type: 'liability'),
        ],
      );

      final service = FinancialIndicatorsService(repository: repository);
      final result = await service.calculateSummary();

      expect(result.debtCoverage.availableCash, 1000000);
      expect(result.debtCoverage.immediateDebts, 500000);
      expect(result.availableBalance, isNotNull);
    });
  });

  group('calculateIndicatorStatus helper', () {
    test('retorna good cuando percentage < 80', () {
      expect(calculateIndicatorStatus(0), IndicatorStatus.good);
      expect(calculateIndicatorStatus(50), IndicatorStatus.good);
      expect(calculateIndicatorStatus(79.9), IndicatorStatus.good);
    });

    test('retorna warning cuando percentage >= 80 y < 100', () {
      expect(calculateIndicatorStatus(80), IndicatorStatus.warning);
      expect(calculateIndicatorStatus(90), IndicatorStatus.warning);
      expect(calculateIndicatorStatus(99.9), IndicatorStatus.warning);
    });

    test('retorna danger cuando percentage >= 100', () {
      expect(calculateIndicatorStatus(100), IndicatorStatus.danger);
      expect(calculateIndicatorStatus(150), IndicatorStatus.danger);
      expect(calculateIndicatorStatus(200), IndicatorStatus.danger);
    });
  });
}
