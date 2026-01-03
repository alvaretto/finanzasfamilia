import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/repositories/report_repository.dart';
import '../../domain/models/report_model.dart';

/// Provider del repositorio
final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  return ReportRepository();
});

/// Estado de reportes
class ReportState {
  final ReportPeriod selectedPeriod;
  final DateTime fromDate;
  final DateTime toDate;
  final ReportSummary? summary;
  final bool isLoading;
  final String? errorMessage;

  const ReportState({
    this.selectedPeriod = ReportPeriod.month,
    required this.fromDate,
    required this.toDate,
    this.summary,
    this.isLoading = false,
    this.errorMessage,
  });

  factory ReportState.initial() {
    final dates = ReportPeriod.month.getDateRange();
    return ReportState(
      fromDate: dates.$1,
      toDate: dates.$2,
    );
  }

  ReportState copyWith({
    ReportPeriod? selectedPeriod,
    DateTime? fromDate,
    DateTime? toDate,
    ReportSummary? summary,
    bool? isLoading,
    String? errorMessage,
  }) {
    return ReportState(
      selectedPeriod: selectedPeriod ?? this.selectedPeriod,
      fromDate: fromDate ?? this.fromDate,
      toDate: toDate ?? this.toDate,
      summary: summary ?? this.summary,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

/// Notifier de reportes
class ReportNotifier extends StateNotifier<ReportState> {
  final ReportRepository _repository;
  final String? _userId;

  ReportNotifier(this._repository, this._userId)
      : super(ReportState.initial()) {
    if (_userId != null) {
      loadReport();
    }
  }

  /// Cargar reporte
  Future<void> loadReport() async {
    final userId = _userId;
    if (userId == null) return;

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final summary = await _repository.getReportSummary(
        userId,
        fromDate: state.fromDate,
        toDate: state.toDate,
      );

      state = state.copyWith(
        summary: summary,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error al cargar reporte: $e',
      );
    }
  }

  /// Cambiar periodo
  void setPeriod(ReportPeriod period) {
    final dates = period.getDateRange();
    state = state.copyWith(
      selectedPeriod: period,
      fromDate: dates.$1,
      toDate: dates.$2,
    );
    loadReport();
  }

  /// Establecer rango personalizado
  void setCustomRange(DateTime from, DateTime to) {
    state = state.copyWith(
      selectedPeriod: ReportPeriod.custom,
      fromDate: from,
      toDate: to,
    );
    loadReport();
  }

  /// Limpiar error
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

/// Provider principal
final reportProvider =
    StateNotifierProvider<ReportNotifier, ReportState>((ref) {
  final repository = ref.watch(reportRepositoryProvider);
  final authState = ref.watch(authProvider);
  return ReportNotifier(repository, authState.user?.id);
});

/// Provider de resumen (conveniencia)
final reportSummaryProvider = Provider<ReportSummary?>((ref) {
  return ref.watch(reportProvider).summary;
});

/// Provider de categorías de gasto
final topExpenseCategoriesProvider = Provider<List<CategoryData>>((ref) {
  return ref.watch(reportProvider).summary?.topExpenseCategories ?? [];
});

/// Provider de flujo mensual
final monthlyFlowProvider = Provider<List<MonthlyFlowData>>((ref) {
  return ref.watch(reportProvider).summary?.monthlyFlow ?? [];
});

/// Provider de tendencia diaria
final dailyTrendProvider = Provider<List<DailyTrendData>>((ref) {
  return ref.watch(reportProvider).summary?.dailyTrend ?? [];
});
