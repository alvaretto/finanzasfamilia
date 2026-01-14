import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/repositories/drift_financial_indicators_repository.dart';
import '../../domain/entities/indicators/financial_indicators.dart';
import '../../domain/services/financial_indicators_service.dart';
import 'database_provider.dart';

// Re-export para compatibilidad con código existente
export '../../domain/entities/dashboard/indicator_status.dart';
export '../../domain/entities/indicators/financial_indicators.dart';

part 'financial_indicators_provider.g.dart';

// ============================================================
// PROVIDERS DE INFRAESTRUCTURA
// ============================================================

/// Provider del repositorio para indicadores financieros
@riverpod
AccountDataRepository accountDataRepository(Ref ref) {
  return DriftAccountDataRepository(
    accountsDao: ref.watch(accountsDaoProvider),
    categoriesDao: ref.watch(categoriesDaoProvider),
  );
}

/// Provider del servicio de indicadores financieros
@riverpod
FinancialIndicatorsService financialIndicatorsService(Ref ref) {
  final repository = ref.watch(accountDataRepositoryProvider);
  return FinancialIndicatorsService(repository: repository);
}

// ============================================================
// PROVIDERS DE DOMINIO
// ============================================================

/// Provider del indicador de cobertura de deuda
@riverpod
Future<DebtCoverageIndicator> debtCoverageIndicator(Ref ref) async {
  final service = ref.watch(financialIndicatorsServiceProvider);
  return service.calculateDebtCoverage();
}

/// Provider del saldo disponible real
@riverpod
Future<AvailableBalanceIndicator> availableBalanceIndicator(Ref ref) async {
  final service = ref.watch(financialIndicatorsServiceProvider);
  return service.calculateAvailableBalance();
}

/// Provider de todos los indicadores financieros
@riverpod
Future<FinancialIndicatorsSummary> financialIndicatorsSummary(Ref ref) async {
  final service = ref.watch(financialIndicatorsServiceProvider);
  return service.calculateSummary();
}
