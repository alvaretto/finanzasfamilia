import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../../../../shared/services/budget_alert_service.dart';
import '../../../accounts/data/repositories/account_repository.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../budgets/data/repositories/budget_repository.dart';
import '../../data/repositories/transaction_repository.dart';
import '../../domain/models/transaction_model.dart';

/// Provider del repositorio
final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepository();
});

/// Estado de transacciones
class TransactionsState {
  final List<TransactionModel> transactions;
  final List<CategoryModel> categories;
  final bool isLoading;
  final bool isSyncing;
  final String? errorMessage;
  final DateTime? fromDate;
  final DateTime? toDate;
  final String? filterAccountId;
  final int? filterCategoryId;
  final TransactionType? filterType;

  const TransactionsState({
    this.transactions = const [],
    this.categories = const [],
    this.isLoading = false,
    this.isSyncing = false,
    this.errorMessage,
    this.fromDate,
    this.toDate,
    this.filterAccountId,
    this.filterCategoryId,
    this.filterType,
  });

  TransactionsState copyWith({
    List<TransactionModel>? transactions,
    List<CategoryModel>? categories,
    bool? isLoading,
    bool? isSyncing,
    String? errorMessage,
    DateTime? fromDate,
    DateTime? toDate,
    String? filterAccountId,
    int? filterCategoryId,
    TransactionType? filterType,
  }) {
    return TransactionsState(
      transactions: transactions ?? this.transactions,
      categories: categories ?? this.categories,
      isLoading: isLoading ?? this.isLoading,
      isSyncing: isSyncing ?? this.isSyncing,
      errorMessage: errorMessage,
      fromDate: fromDate ?? this.fromDate,
      toDate: toDate ?? this.toDate,
      filterAccountId: filterAccountId ?? this.filterAccountId,
      filterCategoryId: filterCategoryId ?? this.filterCategoryId,
      filterType: filterType ?? this.filterType,
    );
  }

  /// Total de ingresos
  double get totalIncome => transactions
      .where((t) => t.type == TransactionType.income)
      .fold(0, (sum, t) => sum + t.amount);

  /// Total de gastos
  double get totalExpenses => transactions
      .where((t) => t.type == TransactionType.expense)
      .fold(0, (sum, t) => sum + t.amount);

  /// Balance del periodo
  double get periodBalance => totalIncome - totalExpenses;

  /// Categorias de gasto
  List<CategoryModel> get expenseCategories =>
      categories.where((c) => c.isExpense).toList();

  /// Categorias de ingreso
  List<CategoryModel> get incomeCategories =>
      categories.where((c) => c.isIncome).toList();
}

/// Notifier de transacciones
class TransactionsNotifier extends StateNotifier<TransactionsState> {
  final TransactionRepository _repository;
  final BudgetRepository _budgetRepository;
  final AccountRepository _accountRepository;
  final String? _userId;
  StreamSubscription<List<TransactionModel>>? _transactionsSubscription;
  StreamSubscription<List<CategoryModel>>? _categoriesSubscription;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  TransactionsNotifier(
    this._repository,
    this._budgetRepository,
    this._accountRepository,
    this._userId,
  ) : super(const TransactionsState(isLoading: true)) {
    if (_userId != null) {
      _init();
    } else {
      // Si no hay usuario, no mostrar loading infinito
      state = const TransactionsState(isLoading: false);
    }
  }

  void _init() {
    final userId = _userId;
    if (userId == null) return;

    // Cargar categorias
    _categoriesSubscription = _repository.watchCategories().listen(
      (categories) {
        state = state.copyWith(categories: categories);
      },
    );

    // Cargar transacciones (ultimo mes por defecto)
    final now = DateTime.now();
    final fromDate = DateTime(now.year, now.month, 1);
    final toDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    state = state.copyWith(fromDate: fromDate, toDate: toDate);
    _loadTransactions(userId, fromDate, toDate);

    // Observar conectividad (sync silencioso)
    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen((results) {
      final hasConnection = results.any((r) => r != ConnectivityResult.none);
      if (hasConnection && !state.isSyncing) {
        syncTransactions(showError: false);
      }
    });

    _checkAndSync();
  }

  void _loadTransactions(String userId, DateTime? from, DateTime? to) {
    _transactionsSubscription?.cancel();
    _transactionsSubscription = _repository
        .watchTransactions(
          userId,
          fromDate: from,
          toDate: to,
          accountId: state.filterAccountId,
          categoryId: state.filterCategoryId,
          type: state.filterType,
        )
        .listen(
          (transactions) {
            state = state.copyWith(
              transactions: transactions,
              isLoading: false,
            );
          },
          onError: (error) {
            state = state.copyWith(
              isLoading: false,
              errorMessage: 'Error al cargar transacciones: $error',
            );
          },
        );
  }

  Future<void> _checkAndSync() async {
    final results = await Connectivity().checkConnectivity();
    final hasConnection = results.any((r) => r != ConnectivityResult.none);
    if (hasConnection) {
      await syncTransactions(showError: false);
    }
  }

  /// Crear transaccion
  Future<bool> createTransaction({
    required String accountId,
    required double amount,
    required TransactionType type,
    int? categoryId,
    String? description,
    DateTime? date,
    String? notes,
    List<String>? tags,
    String? transferToAccountId,
  }) async {
    final userId = _userId;
    if (userId == null) return false;

    try {
      final transaction = TransactionModel.create(
        userId: userId,
        accountId: accountId,
        amount: amount,
        type: type,
        categoryId: categoryId,
        description: description,
        date: date,
        notes: notes,
        tags: tags,
        transferToAccountId: transferToAccountId,
      );

      // Validar transacción antes de crear
      if (!transaction.isValid) {
        final errors = transaction.validationErrors.join(', ');
        state = state.copyWith(errorMessage: errors);
        return false;
      }

      await _repository.createTransaction(transaction);

      // Verificar alertas automáticas después de crear la transacción
      await _checkAlerts(transaction);

      _trySyncInBackground();
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Error al crear transaccion: $e');
      return false;
    }
  }

  /// Verificar alertas automáticas de presupuesto, gastos grandes y saldo bajo
  Future<void> _checkAlerts(TransactionModel transaction) async {
    try {
      final userId = _userId;
      if (userId == null) return;

      // Obtener cuenta actualizada
      final account = await _accountRepository.getAccountById(transaction.accountId);
      if (account == null) return;

      // Obtener presupuestos activos del mes actual
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0);

      // Obtener presupuestos del repositorio (usar watchBudgetsWithSpent que ya calcula spent)
      final allBudgets = await _budgetRepository.watchBudgetsWithSpent(userId).first;

      // Filtrar presupuestos activos en el periodo actual
      final activeBudgets = allBudgets.where((b) {
        return b.startDate.isBefore(endOfMonth) &&
            (b.endDate == null || b.endDate!.isAfter(startOfMonth));
      }).toList();

      // Verificar alertas
      await BudgetAlertService.checkAlertsAfterTransaction(
        transaction: transaction,
        budgets: activeBudgets,
        account: account,
        sendNotifications: true,
      );
    } catch (e) {
      // No fallar si las alertas no funcionan, solo log
      // print('Error checking alerts: $e');
    }
  }

  /// Actualizar transaccion
  Future<bool> updateTransaction(
    TransactionModel oldTx,
    TransactionModel newTx,
  ) async {
    try {
      // Validar transacción antes de actualizar
      if (!newTx.isValid) {
        final errors = newTx.validationErrors.join(', ');
        state = state.copyWith(errorMessage: errors);
        return false;
      }

      await _repository.updateTransaction(oldTx, newTx);
      _trySyncInBackground();
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Error al actualizar: $e');
      return false;
    }
  }

  /// Eliminar transaccion
  Future<bool> deleteTransaction(TransactionModel transaction) async {
    try {
      await _repository.deleteTransaction(transaction);
      _trySyncInBackground();
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Error al eliminar: $e');
      return false;
    }
  }

  /// Cambiar periodo de fechas
  void setDateRange(DateTime from, DateTime to) {
    final userId = _userId;
    if (userId == null) return;

    state = state.copyWith(
      fromDate: from,
      toDate: to,
      isLoading: true,
    );
    _loadTransactions(userId, from, to);
  }

  /// Aplicar filtros
  void setFilters({
    String? accountId,
    int? categoryId,
    TransactionType? type,
  }) {
    final userId = _userId;
    if (userId == null) return;

    state = state.copyWith(
      filterAccountId: accountId,
      filterCategoryId: categoryId,
      filterType: type,
      isLoading: true,
    );
    _loadTransactions(userId, state.fromDate, state.toDate);
  }

  /// Limpiar filtros
  void clearFilters() {
    final userId = _userId;
    if (userId == null) return;

    state = TransactionsState(
      categories: state.categories,
      fromDate: state.fromDate,
      toDate: state.toDate,
      isLoading: true,
    );
    _loadTransactions(userId, state.fromDate, state.toDate);
  }

  /// Sincronizar con servidor
  /// [showError] - Si es false, los errores se ignoran silenciosamente (para syncs automaticos)
  Future<void> syncTransactions({bool showError = true}) async {
    final userId = _userId;
    if (userId == null || state.isSyncing) return;

    state = state.copyWith(isSyncing: true, errorMessage: null);

    try {
      await _repository.syncWithSupabase(userId);
      state = state.copyWith(isSyncing: false);
    } catch (e) {
      // Solo mostrar error si el usuario solicito sync manualmente
      state = state.copyWith(
        isSyncing: false,
        errorMessage: showError ? 'Error de sincronizacion (modo offline activo)' : null,
      );
    }
  }

  void _trySyncInBackground() async {
    final results = await Connectivity().checkConnectivity();
    final hasConnection = results.any((r) => r != ConnectivityResult.none);
    if (hasConnection) {
      syncTransactions(showError: false);
    }
  }

  /// Limpiar error
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  /// Obtener transaccion por ID
  TransactionModel? getById(String id) {
    try {
      return state.transactions.firstWhere((t) => t.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Obtener categoria por ID
  CategoryModel? getCategoryById(int id) {
    try {
      return state.categories.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  void dispose() {
    _transactionsSubscription?.cancel();
    _categoriesSubscription?.cancel();
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}

/// Provider principal
final transactionsProvider =
    StateNotifierProvider<TransactionsNotifier, TransactionsState>((ref) {
  final repository = ref.watch(transactionRepositoryProvider);
  final budgetRepository = BudgetRepository();
  final accountRepository = AccountRepository();
  final authState = ref.watch(authProvider);
  return TransactionsNotifier(
    repository,
    budgetRepository,
    accountRepository,
    authState.user?.id,
  );
});

/// Provider de categorias
final categoriesProvider = Provider<List<CategoryModel>>((ref) {
  return ref.watch(transactionsProvider).categories;
});

/// Provider de categorias de gasto
final expenseCategoriesProvider = Provider<List<CategoryModel>>((ref) {
  return ref.watch(transactionsProvider).expenseCategories;
});

/// Provider de categorias de ingreso
final incomeCategoriesProvider = Provider<List<CategoryModel>>((ref) {
  return ref.watch(transactionsProvider).incomeCategories;
});

/// Provider de transacciones recientes (para dashboard)
final recentTransactionsProvider = Provider<List<TransactionModel>>((ref) {
  final transactions = ref.watch(transactionsProvider).transactions;
  return transactions.take(5).toList();
});
