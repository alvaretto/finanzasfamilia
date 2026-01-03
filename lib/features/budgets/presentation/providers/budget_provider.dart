import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../transactions/domain/models/transaction_model.dart';
import '../../../transactions/presentation/providers/transaction_provider.dart';
import '../../data/repositories/budget_repository.dart';
import '../../domain/models/budget_model.dart';

/// Provider del repositorio
final budgetRepositoryProvider = Provider<BudgetRepository>((ref) {
  return BudgetRepository();
});

/// Estado de presupuestos
class BudgetsState {
  final List<BudgetModel> budgets;
  final List<CategoryModel> expenseCategories;
  final bool isLoading;
  final bool isSyncing;
  final String? errorMessage;

  const BudgetsState({
    this.budgets = const [],
    this.expenseCategories = const [],
    this.isLoading = false,
    this.isSyncing = false,
    this.errorMessage,
  });

  BudgetsState copyWith({
    List<BudgetModel>? budgets,
    List<CategoryModel>? expenseCategories,
    bool? isLoading,
    bool? isSyncing,
    String? errorMessage,
  }) {
    return BudgetsState(
      budgets: budgets ?? this.budgets,
      expenseCategories: expenseCategories ?? this.expenseCategories,
      isLoading: isLoading ?? this.isLoading,
      isSyncing: isSyncing ?? this.isSyncing,
      errorMessage: errorMessage,
    );
  }

  /// Total presupuestado
  double get totalBudgeted => budgets.fold(0, (sum, b) => sum + b.amount);

  /// Total gastado
  double get totalSpent => budgets.fold(0, (sum, b) => sum + b.spent);

  /// Presupuestos excedidos
  List<BudgetModel> get overBudgets => budgets.where((b) => b.isOverBudget).toList();

  /// Presupuestos cerca del límite
  List<BudgetModel> get nearLimitBudgets => budgets.where((b) => b.isNearLimit).toList();

  /// Categorias sin presupuesto asignado
  List<CategoryModel> get categoriesWithoutBudget {
    final budgetedCategoryIds = budgets.map((b) => b.categoryId).toSet();
    return expenseCategories.where((c) => !budgetedCategoryIds.contains(c.id)).toList();
  }
}

/// Notifier de presupuestos
class BudgetsNotifier extends StateNotifier<BudgetsState> {
  final BudgetRepository _repository;
  final String? _userId;
  StreamSubscription<List<BudgetModel>>? _budgetsSubscription;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  BudgetsNotifier(this._repository, this._userId)
      : super(const BudgetsState(isLoading: true)) {
    if (_userId != null) {
      _init();
    } else {
      // Si no hay usuario, no mostrar loading infinito
      state = const BudgetsState(isLoading: false);
    }
  }

  void _init() {
    final userId = _userId;
    if (userId == null) return;

    // Observar presupuestos con gastos
    _budgetsSubscription = _repository.watchBudgetsWithSpent(userId).listen(
      (budgets) {
        state = state.copyWith(
          budgets: budgets,
          isLoading: false,
        );
      },
      onError: (error) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Error al cargar presupuestos: $error',
        );
      },
    );

    // Observar conectividad (sync silencioso)
    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen((results) {
      final hasConnection = results.any((r) => r != ConnectivityResult.none);
      if (hasConnection && !state.isSyncing) {
        syncBudgets(showError: false);
      }
    });

    _checkAndSync();
  }

  /// Actualizar categorias de gasto
  void updateExpenseCategories(List<CategoryModel> categories) {
    state = state.copyWith(expenseCategories: categories);
  }

  Future<void> _checkAndSync() async {
    final results = await Connectivity().checkConnectivity();
    final hasConnection = results.any((r) => r != ConnectivityResult.none);
    if (hasConnection) {
      await syncBudgets(showError: false);
    }
  }

  /// Crear presupuesto
  Future<bool> createBudget({
    required int categoryId,
    required double amount,
    required BudgetPeriod period,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final userId = _userId;
    if (userId == null) return false;

    // Verificar si ya existe presupuesto para esta categoria
    final existing = await _repository.getBudgetByCategory(userId, categoryId);
    if (existing != null) {
      state = state.copyWith(
        errorMessage: 'Ya existe un presupuesto para esta categoría',
      );
      return false;
    }

    try {
      final budget = BudgetModel.create(
        userId: userId,
        categoryId: categoryId,
        amount: amount,
        period: period,
        startDate: startDate,
        endDate: endDate,
      );

      await _repository.createBudget(budget);
      _trySyncInBackground();
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Error al crear presupuesto: $e');
      return false;
    }
  }

  /// Actualizar presupuesto
  Future<bool> updateBudget(BudgetModel budget) async {
    try {
      await _repository.updateBudget(budget);
      _trySyncInBackground();
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Error al actualizar: $e');
      return false;
    }
  }

  /// Eliminar presupuesto
  Future<bool> deleteBudget(String id) async {
    try {
      await _repository.deleteBudget(id);
      _trySyncInBackground();
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Error al eliminar: $e');
      return false;
    }
  }

  /// Sincronizar con servidor
  /// [showError] - Si es false, los errores se ignoran silenciosamente
  Future<void> syncBudgets({bool showError = true}) async {
    final userId = _userId;
    if (userId == null || state.isSyncing) return;

    state = state.copyWith(isSyncing: true, errorMessage: null);

    try {
      await _repository.syncWithSupabase(userId);
      state = state.copyWith(isSyncing: false);
    } catch (e) {
      state = state.copyWith(
        isSyncing: false,
        errorMessage: showError ? 'Error de sincronización (modo offline activo)' : null,
      );
    }
  }

  void _trySyncInBackground() async {
    final results = await Connectivity().checkConnectivity();
    final hasConnection = results.any((r) => r != ConnectivityResult.none);
    if (hasConnection) {
      syncBudgets(showError: false);
    }
  }

  /// Limpiar error
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  /// Obtener presupuesto por ID
  BudgetModel? getById(String id) {
    try {
      return state.budgets.firstWhere((b) => b.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  void dispose() {
    _budgetsSubscription?.cancel();
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}

/// Provider principal
final budgetsProvider =
    StateNotifierProvider<BudgetsNotifier, BudgetsState>((ref) {
  final repository = ref.watch(budgetRepositoryProvider);
  final authState = ref.watch(authProvider);

  final notifier = BudgetsNotifier(repository, authState.user?.id);

  // Escuchar categorias de gasto
  ref.listen(
    expenseCategoriesProvider,
    (_, categories) => notifier.updateExpenseCategories(categories),
  );

  return notifier;
});

/// Provider de presupuestos excedidos
final overBudgetsProvider = Provider<List<BudgetModel>>((ref) {
  return ref.watch(budgetsProvider).overBudgets;
});

/// Provider de presupuestos cerca del límite
final nearLimitBudgetsProvider = Provider<List<BudgetModel>>((ref) {
  return ref.watch(budgetsProvider).nearLimitBudgets;
});
