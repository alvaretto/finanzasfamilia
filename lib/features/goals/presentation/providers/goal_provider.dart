import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/repositories/goal_repository.dart';
import '../../domain/models/goal_model.dart';

/// Provider del repositorio
final goalRepositoryProvider = Provider<GoalRepository>((ref) {
  return GoalRepository();
});

/// Estado de metas
class GoalsState {
  final List<GoalModel> activeGoals;
  final List<GoalModel> completedGoals;
  final bool isLoading;
  final bool isSyncing;
  final String? errorMessage;

  const GoalsState({
    this.activeGoals = const [],
    this.completedGoals = const [],
    this.isLoading = false,
    this.isSyncing = false,
    this.errorMessage,
  });

  GoalsState copyWith({
    List<GoalModel>? activeGoals,
    List<GoalModel>? completedGoals,
    bool? isLoading,
    bool? isSyncing,
    String? errorMessage,
  }) {
    return GoalsState(
      activeGoals: activeGoals ?? this.activeGoals,
      completedGoals: completedGoals ?? this.completedGoals,
      isLoading: isLoading ?? this.isLoading,
      isSyncing: isSyncing ?? this.isSyncing,
      errorMessage: errorMessage,
    );
  }

  /// Todas las metas
  List<GoalModel> get allGoals => [...activeGoals, ...completedGoals];

  /// Total ahorrado
  double get totalSaved =>
      activeGoals.fold(0, (sum, g) => sum + g.currentAmount);

  /// Total objetivo (solo metas activas)
  double get totalTarget =>
      activeGoals.fold(0, (sum, g) => sum + g.targetAmount);

  /// Progreso general
  double get overallProgress =>
      totalTarget > 0 ? (totalSaved / totalTarget * 100).clamp(0, 100) : 0;

  /// Metas próximas a vencer (en los próximos 30 días)
  List<GoalModel> get upcomingDeadlines {
    final cutoff = DateTime.now().add(const Duration(days: 30));
    return activeGoals
        .where((g) => g.targetDate != null && g.targetDate!.isBefore(cutoff))
        .toList();
  }
}

/// Notifier de metas
class GoalsNotifier extends StateNotifier<GoalsState> {
  final GoalRepository _repository;
  final String? _userId;
  StreamSubscription<List<GoalModel>>? _activeGoalsSubscription;
  StreamSubscription<List<GoalModel>>? _completedGoalsSubscription;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  GoalsNotifier(this._repository, this._userId)
      : super(const GoalsState(isLoading: true)) {
    if (_userId != null) {
      _init();
    } else {
      // Si no hay usuario, no mostrar loading infinito
      state = const GoalsState(isLoading: false);
    }
  }

  void _init() {
    final userId = _userId;
    if (userId == null) return;

    // Observar metas activas
    _activeGoalsSubscription = _repository.watchActiveGoals(userId).listen(
      (goals) {
        state = state.copyWith(
          activeGoals: goals,
          isLoading: false,
        );
      },
      onError: (error) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Error al cargar metas: $error',
        );
      },
    );

    // Observar metas completadas
    _completedGoalsSubscription = _repository.watchCompletedGoals(userId).listen(
      (goals) {
        state = state.copyWith(completedGoals: goals);
      },
    );

    // Observar conectividad
    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen((results) {
      final hasConnection = results.any((r) => r != ConnectivityResult.none);
      if (hasConnection && !state.isSyncing) {
        syncGoals();
      }
    });

    _checkAndSync();
  }

  Future<void> _checkAndSync() async {
    final results = await Connectivity().checkConnectivity();
    final hasConnection = results.any((r) => r != ConnectivityResult.none);
    if (hasConnection) {
      await syncGoals();
    }
  }

  /// Crear meta
  Future<bool> createGoal({
    required String name,
    required double targetAmount,
    double? currentAmount,
    DateTime? targetDate,
    String? icon,
    String? color,
  }) async {
    final userId = _userId;
    if (userId == null) return false;

    try {
      final goal = GoalModel.create(
        userId: userId,
        name: name,
        targetAmount: targetAmount,
        currentAmount: currentAmount,
        targetDate: targetDate,
        icon: icon,
        color: color,
      );

      await _repository.createGoal(goal);
      _trySyncInBackground();
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Error al crear meta: $e');
      return false;
    }
  }

  /// Actualizar meta
  Future<bool> updateGoal(GoalModel goal) async {
    try {
      await _repository.updateGoal(goal);
      _trySyncInBackground();
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Error al actualizar: $e');
      return false;
    }
  }

  /// Agregar ahorro a meta
  Future<bool> addSavings(String goalId, double amount) async {
    if (amount <= 0) {
      state = state.copyWith(errorMessage: 'El monto debe ser positivo');
      return false;
    }

    try {
      await _repository.addAmount(goalId, amount);
      _trySyncInBackground();
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Error al agregar ahorro: $e');
      return false;
    }
  }

  /// Retirar de meta
  Future<bool> withdrawSavings(String goalId, double amount) async {
    if (amount <= 0) {
      state = state.copyWith(errorMessage: 'El monto debe ser positivo');
      return false;
    }

    try {
      await _repository.withdrawAmount(goalId, amount);
      _trySyncInBackground();
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Error al retirar: $e');
      return false;
    }
  }

  /// Eliminar meta
  Future<bool> deleteGoal(String id) async {
    try {
      await _repository.deleteGoal(id);
      _trySyncInBackground();
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Error al eliminar: $e');
      return false;
    }
  }

  /// Sincronizar con servidor
  Future<void> syncGoals() async {
    final userId = _userId;
    if (userId == null || state.isSyncing) return;

    state = state.copyWith(isSyncing: true, errorMessage: null);

    try {
      await _repository.syncWithSupabase(userId);
      state = state.copyWith(isSyncing: false);
    } catch (e) {
      state = state.copyWith(
        isSyncing: false,
        errorMessage: 'Error de sincronización (modo offline activo)',
      );
    }
  }

  void _trySyncInBackground() async {
    final results = await Connectivity().checkConnectivity();
    final hasConnection = results.any((r) => r != ConnectivityResult.none);
    if (hasConnection) {
      syncGoals();
    }
  }

  /// Limpiar error
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  /// Obtener meta por ID
  GoalModel? getById(String id) {
    try {
      return state.allGoals.firstWhere((g) => g.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  void dispose() {
    _activeGoalsSubscription?.cancel();
    _completedGoalsSubscription?.cancel();
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}

/// Provider principal
final goalsProvider = StateNotifierProvider<GoalsNotifier, GoalsState>((ref) {
  final repository = ref.watch(goalRepositoryProvider);
  final authState = ref.watch(authProvider);
  return GoalsNotifier(repository, authState.user?.id);
});

/// Provider de metas activas
final activeGoalsProvider = Provider<List<GoalModel>>((ref) {
  return ref.watch(goalsProvider).activeGoals;
});

/// Provider de metas completadas
final completedGoalsProvider = Provider<List<GoalModel>>((ref) {
  return ref.watch(goalsProvider).completedGoals;
});

/// Provider de próximas fechas límite
final upcomingDeadlinesProvider = Provider<List<GoalModel>>((ref) {
  return ref.watch(goalsProvider).upcomingDeadlines;
});
