// FinancialIndicatorsService - Lógica de negocio para indicadores financieros
// Extraído de financial_indicators_provider.dart

import '../entities/indicators/financial_indicators.dart';

/// Interfaz de repositorio para obtener datos de cuentas
abstract class AccountDataRepository {
  Future<List<AccountBalance>> getAllAccountBalances();
  Future<List<CategoryInfo>> getCategoriesByType(String type);
}

/// Datos mínimos de cuenta para cálculos
class AccountBalance {
  final String id;
  final String? categoryId;
  final double balance;

  const AccountBalance({
    required this.id,
    this.categoryId,
    required this.balance,
  });
}

/// Información de categoría
class CategoryInfo {
  final String id;
  final String name;
  final String type;

  const CategoryInfo({
    required this.id,
    required this.name,
    required this.type,
  });
}

/// Servicio de dominio para cálculo de indicadores financieros
class FinancialIndicatorsService {
  final AccountDataRepository repository;

  const FinancialIndicatorsService({required this.repository});

  /// Calcula el indicador de cobertura de deuda
  Future<DebtCoverageIndicator> calculateDebtCoverage() async {
    final accounts = await repository.getAllAccountBalances();

    double availableCash = 0;
    double immediateDebts = 0;

    for (final account in accounts) {
      if (account.balance >= 0) {
        availableCash += account.balance;
      } else {
        immediateDebts += account.balance.abs();
      }
    }

    return DebtCoverageIndicator(
      availableCash: availableCash,
      immediateDebts: immediateDebts,
    );
  }

  /// Calcula el indicador de saldo disponible real
  Future<AvailableBalanceIndicator> calculateAvailableBalance() async {
    final accounts = await repository.getAllAccountBalances();
    final assetCategories = await repository.getCategoriesByType('asset');
    final liabilityCategories = await repository.getCategoriesByType('liability');

    double cashBalance = 0;
    double bankBalance = 0;
    double immediatePayables = 0;

    // Identificar categorías por nombre (patrón colombiano)
    final cashCategoryIds = assetCategories
        .where((c) => _isCashCategory(c.name))
        .map((c) => c.id)
        .toSet();

    final bankCategoryIds = assetCategories
        .where((c) => _isBankCategory(c.name))
        .map((c) => c.id)
        .toSet();

    final payableCategoryIds = liabilityCategories
        .where((c) => _isPayableCategory(c.name))
        .map((c) => c.id)
        .toSet();

    for (final account in accounts) {
      if (cashCategoryIds.contains(account.categoryId)) {
        cashBalance += account.balance;
      } else if (bankCategoryIds.contains(account.categoryId)) {
        bankBalance += account.balance;
      } else if (payableCategoryIds.contains(account.categoryId)) {
        immediatePayables += account.balance.abs();
      }
    }

    return AvailableBalanceIndicator(
      cashBalance: cashBalance,
      bankBalance: bankBalance,
      immediatePayables: immediatePayables,
    );
  }

  /// Calcula el resumen de todos los indicadores
  Future<FinancialIndicatorsSummary> calculateSummary() async {
    final debtCoverage = await calculateDebtCoverage();
    final availableBalance = await calculateAvailableBalance();

    return FinancialIndicatorsSummary(
      debtCoverage: debtCoverage,
      availableBalance: availableBalance,
    );
  }

  // Helpers para clasificación de categorías (patrón colombiano)

  bool _isCashCategory(String name) {
    final lower = name.toLowerCase();
    return lower.contains('efectivo') || lower.contains('billetera');
  }

  bool _isBankCategory(String name) {
    final lower = name.toLowerCase();
    return lower.contains('banco') ||
        lower.contains('digital') ||
        lower.contains('nequi') ||
        lower.contains('davi') ||
        lower.contains('ahorro');
  }

  bool _isPayableCategory(String name) {
    final lower = name.toLowerCase();
    return lower.contains('tarjeta') || lower.contains('pagar');
  }
}
