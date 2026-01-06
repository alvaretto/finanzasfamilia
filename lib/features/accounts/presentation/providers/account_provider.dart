import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../transactions/data/repositories/transaction_repository.dart';
import '../../data/repositories/account_repository.dart';
import '../../domain/models/account_model.dart';

/// Provider del repositorio de cuentas
final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  return AccountRepository();
});

/// Estado de las cuentas
class AccountsState {
  final List<AccountModel> accounts;
  final bool isLoading;
  final bool isSyncing;
  final String? errorMessage;
  final double totalBalance;

  const AccountsState({
    this.accounts = const [],
    this.isLoading = false,
    this.isSyncing = false,
    this.errorMessage,
    this.totalBalance = 0.0,
  });

  AccountsState copyWith({
    List<AccountModel>? accounts,
    bool? isLoading,
    bool? isSyncing,
    String? errorMessage,
    double? totalBalance,
  }) {
    return AccountsState(
      accounts: accounts ?? this.accounts,
      isLoading: isLoading ?? this.isLoading,
      isSyncing: isSyncing ?? this.isSyncing,
      errorMessage: errorMessage,
      totalBalance: totalBalance ?? this.totalBalance,
    );
  }

  /// Cuentas activas
  List<AccountModel> get activeAccounts =>
      accounts.where((a) => a.isActive).toList();

  /// Cuentas activas únicas (deduplicadas por nombre y tipo)
  /// Filtra cuentas fantasma (balance $0, nombre genérico de tipo, sin uso real)
  List<AccountModel> get uniqueActiveAccounts {
    final seen = <String>{};
    final unique = <AccountModel>[];

    // Nombres genéricos que indican cuentas fantasma/huérfanas
    // Incluye versiones con y sin acentos para matching robusto
    final genericNames = {
      // Préstamos (con y sin acento)
      'préstamos', 'prestamos', 'préstamo', 'prestamo',
      'préstamo bancario', 'prestamo bancario',
      'préstamo personal', 'prestamo personal',
      // Tarjeta de crédito
      'tarjeta de crédito', 'tarjeta de credito',
      // Cuentas por cobrar/pagar
      'me deben', 'debo pagar',
    };

    // Ordenar por balance descendente para mantener la de mayor balance
    final sorted = List<AccountModel>.from(activeAccounts)
      ..sort((a, b) => b.balance.compareTo(a.balance));

    for (final account in sorted) {
      // Filtrar cuentas fantasma: balance $0 + nombre genérico + pasivo
      final normalizedName = account.name.trim().toLowerCase();
      final isGenericName = genericNames.contains(normalizedName);
      final isEmptyLiability = account.type.isLiability && account.balance == 0;

      // Saltar cuentas fantasma (pasivos vacíos con nombres genéricos)
      if (isGenericName && isEmptyLiability) {
        continue;
      }

      final key = '${normalizedName}_${account.type.name}';
      if (!seen.contains(key)) {
        seen.add(key);
        unique.add(account);
      }
    }

    // Ordenar alfabéticamente por nombre para consistencia en UI
    unique.sort((a, b) => a.name.compareTo(b.name));
    return unique;
  }

  /// Cuentas por tipo
  Map<AccountType, List<AccountModel>> get accountsByType {
    final map = <AccountType, List<AccountModel>>{};
    for (final account in activeAccounts) {
      map.putIfAbsent(account.type, () => []).add(account);
    }
    return map;
  }

  /// Balance por tipo de cuenta
  Map<AccountType, double> get balanceByType {
    final map = <AccountType, double>{};
    for (final account in activeAccounts) {
      final current = map[account.type] ?? 0.0;
      map[account.type] = current + account.balance;
    }
    return map;
  }
}

/// Notifier de cuentas
class AccountsNotifier extends StateNotifier<AccountsState> {
  final AccountRepository _repository;
  final TransactionRepository _transactionRepository;
  final String? _userId;
  StreamSubscription<List<AccountModel>>? _accountsSubscription;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  AccountsNotifier(this._repository, this._transactionRepository, this._userId)
      : super(const AccountsState(isLoading: true)) {
    if (_userId != null) {
      _init();
    } else {
      // Si no hay usuario, no mostrar loading infinito
      state = const AccountsState(isLoading: false);
    }
  }

  void _init() {
    final userId = _userId;
    if (userId == null) return;

    // Limpiar cuentas fantasma al iniciar (antes de observar)
    _cleanGhostAccounts(userId);

    // Observar cuentas locales
    _accountsSubscription = _repository.watchAccounts(userId).listen(
      (accounts) async {
        final total = await _repository.getTotalBalance(userId);
        state = state.copyWith(
          accounts: accounts,
          isLoading: false,
          totalBalance: total,
        );

        // No crear cuentas por defecto - el usuario las crea manualmente
      },
      onError: (error) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Error al cargar cuentas: $error',
        );
      },
    );

    // Observar conectividad para sincronizar (silenciosamente)
    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen((results) {
      final hasConnection = results.any((r) => r != ConnectivityResult.none);
      if (hasConnection && !state.isSyncing) {
        syncAccounts(showError: false);
      }
    });

    // Sincronizar al iniciar si hay conexión
    _checkAndSync();
  }

  /// Limpia cuentas fantasma silenciosamente al iniciar
  Future<void> _cleanGhostAccounts(String userId) async {
    try {
      await _repository.removeGhostAccounts(userId);
    } catch (_) {
      // Ignorar errores - es limpieza opcional
    }
  }

  Future<void> _checkAndSync() async {
    final results = await Connectivity().checkConnectivity();
    final hasConnection = results.any((r) => r != ConnectivityResult.none);
    if (hasConnection) {
      await syncAccounts(showError: false);
    }
  }

  /// Crear nueva cuenta
  Future<bool> createAccount({
    required String name,
    required AccountType type,
    String currency = 'COP',
    double balance = 0.0,
    String? familyId,
    String? color,
    String? icon,
    String? bankName,
    String? lastFourDigits,
    double creditLimit = 0.0,
  }) async {
    final userId = _userId;
    if (userId == null) return false;

    try {
      final account = AccountModel.create(
        userId: userId,
        name: name,
        type: type,
        currency: currency,
        balance: balance,
        familyId: familyId,
        color: color,
        icon: icon,
        bankName: bankName,
        lastFourDigits: lastFourDigits,
        creditLimit: creditLimit,
      );

      await _repository.createAccount(account);

      // Intentar sincronizar
      _trySyncInBackground();

      return true;
    } on DuplicateAccountException catch (e) {
      state = state.copyWith(errorMessage: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Error al crear cuenta: $e');
      return false;
    }
  }

  /// Actualizar cuenta
  Future<bool> updateAccount(AccountModel account) async {
    try {
      await _repository.updateAccount(account);
      _trySyncInBackground();
      return true;
    } on DuplicateAccountException catch (e) {
      state = state.copyWith(errorMessage: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Error al actualizar cuenta: $e');
      return false;
    }
  }

  /// Eliminar cuenta (soft delete)
  /// Solo permite eliminar si la cuenta no tiene movimientos asociados
  Future<bool> deleteAccount(String id) async {
    try {
      // Verificar si la cuenta tiene transacciones
      final transactionCount = await _transactionRepository.countTransactionsByAccount(id);

      if (transactionCount > 0) {
        state = state.copyWith(
          errorMessage: 'No se puede eliminar una cuenta con movimientos. '
              'Esta cuenta tiene $transactionCount movimiento${transactionCount == 1 ? '' : 's'}.',
        );
        return false;
      }

      await _repository.deleteAccount(id);
      _trySyncInBackground();
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Error al eliminar cuenta: $e');
      return false;
    }
  }

  /// Actualizar balance
  Future<bool> updateBalance(String id, double newBalance) async {
    try {
      await _repository.updateBalance(id, newBalance);
      _trySyncInBackground();
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Error al actualizar balance: $e');
      return false;
    }
  }

  /// Limpiar cuentas duplicadas y fantasma
  /// Retorna el número de cuentas eliminadas (duplicados + fantasma)
  Future<int> cleanDuplicates() async {
    final userId = _userId;
    if (userId == null) return 0;

    try {
      // Limpiar duplicados
      final duplicatesRemoved = await _repository.removeDuplicateAccounts(userId);

      // Limpiar cuentas fantasma (pasivos vacíos con nombres genéricos)
      final ghostsRemoved = await _repository.removeGhostAccounts(userId);

      final totalRemoved = duplicatesRemoved + ghostsRemoved;
      if (totalRemoved > 0) {
        _trySyncInBackground();
      }
      return totalRemoved;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Error al limpiar cuentas: $e');
      return 0;
    }
  }

  /// Sincronizar con servidor
  /// [showError] - Si es false, los errores de sync se ignoran silenciosamente (para syncs automaticos)
  Future<void> syncAccounts({bool showError = true}) async {
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
        errorMessage: showError ? 'Error de sincronización (modo offline activo)' : null,
      );
    }
  }

  void _trySyncInBackground() async {
    final results = await Connectivity().checkConnectivity();
    final hasConnection = results.any((r) => r != ConnectivityResult.none);
    if (hasConnection) {
      syncAccounts(showError: false);
    }
  }

  /// Limpiar error
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  /// Obtener cuenta por ID
  AccountModel? getAccountById(String id) {
    try {
      return state.accounts.firstWhere((a) => a.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  void dispose() {
    _accountsSubscription?.cancel();
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}

/// Provider principal de cuentas
final accountsProvider =
    StateNotifierProvider<AccountsNotifier, AccountsState>((ref) {
  final repository = ref.watch(accountRepositoryProvider);
  final transactionRepository = TransactionRepository();
  final authState = ref.watch(authProvider);
  final userId = authState.user?.id;

  return AccountsNotifier(repository, transactionRepository, userId);
});

/// Provider del balance total
final totalBalanceProvider = Provider<double>((ref) {
  return ref.watch(accountsProvider).totalBalance;
});

/// Provider de cuentas activas
final activeAccountsProvider = Provider<List<AccountModel>>((ref) {
  return ref.watch(accountsProvider).activeAccounts;
});

/// Provider de cuentas activas únicas (sin duplicados)
final uniqueActiveAccountsProvider = Provider<List<AccountModel>>((ref) {
  return ref.watch(accountsProvider).uniqueActiveAccounts;
});

/// Provider de cuentas por tipo
final accountsByTypeProvider =
    Provider<Map<AccountType, List<AccountModel>>>((ref) {
  return ref.watch(accountsProvider).accountsByType;
});

/// Provider para una cuenta específica
final accountByIdProvider =
    Provider.family<AccountModel?, String>((ref, id) {
  return ref.watch(accountsProvider.notifier).getAccountById(id);
});
