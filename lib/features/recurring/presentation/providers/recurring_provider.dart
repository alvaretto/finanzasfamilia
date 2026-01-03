import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/repositories/recurring_repository.dart';
import '../../domain/models/recurring_model.dart';

/// Provider del repositorio
final recurringRepositoryProvider = Provider<RecurringRepository>((ref) {
  return RecurringRepository();
});

/// Estado de transacciones recurrentes
class RecurringState {
  final List<RecurringModel> items;
  final List<RecurringModel> pending;
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;

  const RecurringState({
    this.items = const [],
    this.pending = const [],
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
  });

  /// Total mensual estimado de ingresos
  double get monthlyIncome {
    double total = 0;
    for (final item in items.where((i) => i.isActive && i.type == RecurringType.income)) {
      switch (item.frequency) {
        case RecurringFrequency.daily:
          total += item.amount * 30;
        case RecurringFrequency.weekly:
          total += item.amount * 4;
        case RecurringFrequency.monthly:
          total += item.amount;
        case RecurringFrequency.yearly:
          total += item.amount / 12;
      }
    }
    return total;
  }

  /// Total mensual estimado de gastos
  double get monthlyExpense {
    double total = 0;
    for (final item in items.where((i) => i.isActive && i.type == RecurringType.expense)) {
      switch (item.frequency) {
        case RecurringFrequency.daily:
          total += item.amount * 30;
        case RecurringFrequency.weekly:
          total += item.amount * 4;
        case RecurringFrequency.monthly:
          total += item.amount;
        case RecurringFrequency.yearly:
          total += item.amount / 12;
      }
    }
    return total;
  }

  RecurringState copyWith({
    List<RecurringModel>? items,
    List<RecurringModel>? pending,
    bool? isLoading,
    String? errorMessage,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return RecurringState(
      items: items ?? this.items,
      pending: pending ?? this.pending,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }
}

/// Notifier de transacciones recurrentes
class RecurringNotifier extends StateNotifier<RecurringState> {
  final RecurringRepository _repository;
  final String? _userId;
  StreamSubscription? _subscription;

  RecurringNotifier(this._repository, this._userId)
      : super(const RecurringState()) {
    if (_userId != null) {
      _load();
      _startWatching();
    }
  }

  void _startWatching() {
    final userId = _userId;
    if (userId == null) return;

    _subscription = _repository.watchRecurring(userId).listen(
      (items) {
        final pending = items.where((i) => i.isActive && (i.isDueToday || i.isOverdue)).toList();
        state = state.copyWith(items: items, pending: pending, clearError: true);
      },
      onError: (e) {
        state = state.copyWith(errorMessage: 'Error al observar: $e');
      },
    );
  }

  Future<void> _load() async {
    final userId = _userId;
    if (userId == null) return;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final items = await _repository.getRecurring(userId);
      final pending = items.where((i) => i.isActive && (i.isDueToday || i.isOverdue)).toList();
      state = state.copyWith(items: items, pending: pending, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error al cargar: $e',
      );
    }
  }

  /// Crear transacción recurrente
  Future<bool> create(RecurringModel recurring) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _repository.createRecurring(recurring);
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Transacción recurrente creada',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error al crear: $e',
      );
      return false;
    }
  }

  /// Actualizar
  Future<bool> update(RecurringModel recurring) async {
    try {
      await _repository.updateRecurring(recurring);
      state = state.copyWith(successMessage: 'Actualizado');
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Error al actualizar: $e');
      return false;
    }
  }

  /// Ejecutar (crear transacción real)
  Future<bool> execute(RecurringModel recurring) async {
    try {
      await _repository.executeRecurring(recurring);
      state = state.copyWith(
        successMessage: 'Transacción registrada',
      );
      await _load();
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Error al ejecutar: $e');
      return false;
    }
  }

  /// Saltar ocurrencia
  Future<bool> skip(RecurringModel recurring) async {
    try {
      await _repository.skipOccurrence(recurring);
      state = state.copyWith(successMessage: 'Omitido');
      await _load();
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Error: $e');
      return false;
    }
  }

  /// Pausar/Reanudar
  Future<bool> toggleActive(String id, bool isActive) async {
    try {
      await _repository.toggleActive(id, isActive);
      state = state.copyWith(
        successMessage: isActive ? 'Reanudado' : 'Pausado',
      );
      await _load();
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Error: $e');
      return false;
    }
  }

  /// Eliminar
  Future<bool> delete(String id) async {
    try {
      await _repository.deleteRecurring(id);
      state = state.copyWith(successMessage: 'Eliminado');
      await _load();
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Error al eliminar: $e');
      return false;
    }
  }

  /// Limpiar mensajes
  void clearMessages() {
    state = state.copyWith(clearError: true, clearSuccess: true);
  }

  /// Refrescar
  Future<void> refresh() => _load();

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

/// Provider principal
final recurringProvider =
    StateNotifierProvider<RecurringNotifier, RecurringState>((ref) {
  final repository = ref.watch(recurringRepositoryProvider);
  final authState = ref.watch(authProvider);
  return RecurringNotifier(repository, authState.user?.id);
});

/// Provider de lista de recurrentes
final recurringListProvider = Provider<List<RecurringModel>>((ref) {
  return ref.watch(recurringProvider).items;
});

/// Provider de pendientes
final pendingRecurringProvider = Provider<List<RecurringModel>>((ref) {
  return ref.watch(recurringProvider).pending;
});

/// Provider de estimado mensual
final monthlyEstimateProvider = Provider<(double income, double expense)>((ref) {
  final state = ref.watch(recurringProvider);
  return (state.monthlyIncome, state.monthlyExpense);
});
