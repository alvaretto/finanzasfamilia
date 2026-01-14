import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/local/daos/recurring_transactions_dao.dart';
import '../../data/repositories/drift_recurring_transaction_repository.dart';
import '../../domain/services/recurring_transaction_service.dart';
import 'database_provider.dart';

part 'recurring_transactions_provider.g.dart';

/// Provider del DAO de transacciones recurrentes
@riverpod
RecurringTransactionsDao recurringTransactionsDao(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  return RecurringTransactionsDao(db);
}

/// Provider del repositorio de transacciones recurrentes
@riverpod
RecurringTransactionRepository recurringTransactionRepository(Ref ref) {
  final dao = ref.watch(recurringTransactionsDaoProvider);
  return DriftRecurringTransactionRepository(dao);
}

/// Provider del servicio de dominio de transacciones recurrentes
@riverpod
RecurringTransactionService recurringTransactionService(Ref ref) {
  final repository = ref.watch(recurringTransactionRepositoryProvider);
  return RecurringTransactionService(repository: repository);
}

/// Provider de transacciones recurrentes activas (Stream)
@riverpod
Stream<List<RecurringTransactionData>> activeRecurringTransactions(Ref ref) {
  final repository = ref.watch(recurringTransactionRepositoryProvider);
  return repository.watchActive();
}

/// Provider de transacciones pendientes de confirmación (Stream)
@riverpod
Stream<List<RecurringTransactionData>> pendingConfirmationTransactions(
    Ref ref) {
  final repository = ref.watch(recurringTransactionRepositoryProvider);
  return repository.watchPendingConfirmation();
}

/// Provider de transacciones que deben ejecutarse
@riverpod
Future<List<RecurringTransactionData>> dueRecurringTransactions(Ref ref) {
  final repository = ref.watch(recurringTransactionRepositoryProvider);
  return repository.getDueForExecution();
}

/// Notifier para gestionar transacciones recurrentes
/// Delega toda la lógica de negocio a RecurringTransactionService
@riverpod
class RecurringTransactionsNotifier extends _$RecurringTransactionsNotifier {
  @override
  Future<List<RecurringTransactionData>> build() async {
    final repository = ref.watch(recurringTransactionRepositoryProvider);
    return repository.getActive();
  }

  RecurringTransactionService get _service =>
      ref.read(recurringTransactionServiceProvider);

  /// Crea una nueva transacción recurrente
  Future<String> create({
    required String name,
    required String type,
    required double amount,
    required String categoryId,
    required RecurrenceFrequency frequency,
    required int dayOfExecution,
    required DateTime startDate,
    String? description,
    String? fromAccountId,
    String? toAccountId,
    DateTime? endDate,
    bool requiresConfirmation = false,
  }) async {
    final id = await _service.create(
      name: name,
      type: type,
      amount: amount,
      categoryId: categoryId,
      frequency: frequency,
      dayOfExecution: dayOfExecution,
      startDate: startDate,
      description: description,
      fromAccountId: fromAccountId,
      toAccountId: toAccountId,
      endDate: endDate,
      requiresConfirmation: requiresConfirmation,
    );
    ref.invalidateSelf();
    return id;
  }

  /// Actualiza una transacción recurrente
  Future<void> updateRecurring({
    required String id,
    String? name,
    double? amount,
    String? description,
    String? categoryId,
    RecurrenceFrequency? frequency,
    int? dayOfExecution,
    DateTime? endDate,
    bool? requiresConfirmation,
  }) async {
    await _service.update(
      id: id,
      name: name,
      amount: amount,
      description: description,
      categoryId: categoryId,
      frequency: frequency,
      dayOfExecution: dayOfExecution,
      endDate: endDate,
      requiresConfirmation: requiresConfirmation,
    );
    ref.invalidateSelf();
  }

  /// Activa una transacción recurrente
  Future<void> activate(String id) async {
    await _service.activate(id);
    ref.invalidateSelf();
  }

  /// Desactiva una transacción recurrente
  Future<void> deactivate(String id) async {
    await _service.deactivate(id);
    ref.invalidateSelf();
  }

  /// Elimina una transacción recurrente
  Future<void> delete(String id) async {
    await _service.delete(id);
    ref.invalidateSelf();
  }
}

/// Notifier para ejecutar transacciones recurrentes
/// Delega toda la lógica de ejecución a RecurringTransactionService
@riverpod
class RecurringExecutionNotifier extends _$RecurringExecutionNotifier {
  @override
  FutureOr<void> build() {}

  RecurringTransactionService get _service =>
      ref.read(recurringTransactionServiceProvider);

  /// Ejecuta todas las transacciones recurrentes pendientes
  Future<ExecutionResult> executeAllDue() async {
    final result = await _service.executeAllDue();

    // Invalidar providers relacionados
    ref.invalidate(activeRecurringTransactionsProvider);
    ref.invalidate(dueRecurringTransactionsProvider);
    ref.invalidate(recurringTransactionsNotifierProvider);

    return result;
  }

  /// Ejecuta una transacción recurrente específica
  Future<void> executeOne(String id) async {
    await _service.executeOne(id);

    // Invalidar providers relacionados
    ref.invalidate(activeRecurringTransactionsProvider);
    ref.invalidate(dueRecurringTransactionsProvider);
    ref.invalidate(recurringTransactionsNotifierProvider);
  }
}
