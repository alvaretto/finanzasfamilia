import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart';

import '../../data/local/database.dart';
import '../../data/local/daos/recurring_transactions_dao.dart';
import '../../data/local/tables/recurring_transactions_table.dart';
import 'database_provider.dart';

part 'recurring_transactions_provider.g.dart';

/// Provider del DAO de transacciones recurrentes
@riverpod
RecurringTransactionsDao recurringTransactionsDao(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  return RecurringTransactionsDao(db);
}

/// Provider de transacciones recurrentes activas
@riverpod
Stream<List<RecurringTransactionEntry>> activeRecurringTransactions(Ref ref) {
  final dao = ref.watch(recurringTransactionsDaoProvider);
  return dao.watchActive();
}

/// Provider de transacciones pendientes de confirmación
@riverpod
Stream<List<RecurringTransactionEntry>> pendingConfirmationTransactions(
    Ref ref) {
  final dao = ref.watch(recurringTransactionsDaoProvider);
  return dao.watchPendingConfirmation();
}

/// Provider de transacciones que deben ejecutarse
@riverpod
Future<List<RecurringTransactionEntry>> dueRecurringTransactions(Ref ref) {
  final dao = ref.watch(recurringTransactionsDaoProvider);
  return dao.getDueForExecution();
}

/// Notifier para gestionar transacciones recurrentes
@riverpod
class RecurringTransactionsNotifier extends _$RecurringTransactionsNotifier {
  @override
  Future<List<RecurringTransactionEntry>> build() async {
    final dao = ref.watch(recurringTransactionsDaoProvider);
    return dao.getActive();
  }

  /// Crea una nueva transacción recurrente
  Future<void> create({
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
    final dao = ref.read(recurringTransactionsDaoProvider);
    final id = const Uuid().v4();

    final nextExecution = _calculateNextExecution(
      frequency: frequency,
      dayOfExecution: dayOfExecution,
      fromDate: startDate,
    );

    await dao.insert(RecurringTransactionsCompanion(
      id: Value(id),
      name: Value(name),
      type: Value(type),
      amount: Value(amount),
      description: Value(description),
      fromAccountId: Value(fromAccountId),
      toAccountId: Value(toAccountId),
      categoryId: Value(categoryId),
      frequency: Value(frequency.name),
      dayOfExecution: Value(dayOfExecution),
      startDate: Value(startDate),
      endDate: Value(endDate),
      nextExecutionDate: Value(nextExecution),
      requiresConfirmation: Value(requiresConfirmation),
    ));

    ref.invalidateSelf();
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
    final dao = ref.read(recurringTransactionsDaoProvider);

    await dao.updateEntry(RecurringTransactionsCompanion(
      id: Value(id),
      name: name != null ? Value(name) : const Value.absent(),
      amount: amount != null ? Value(amount) : const Value.absent(),
      description: description != null ? Value(description) : const Value.absent(),
      categoryId: categoryId != null ? Value(categoryId) : const Value.absent(),
      frequency: frequency != null ? Value(frequency.name) : const Value.absent(),
      dayOfExecution:
          dayOfExecution != null ? Value(dayOfExecution) : const Value.absent(),
      endDate: endDate != null ? Value(endDate) : const Value.absent(),
      requiresConfirmation: requiresConfirmation != null
          ? Value(requiresConfirmation)
          : const Value.absent(),
      updatedAt: Value(DateTime.now()),
    ));

    ref.invalidateSelf();
  }

  /// Activa una transacción recurrente
  Future<void> activate(String id) async {
    final dao = ref.read(recurringTransactionsDaoProvider);
    await dao.activate(id);
    ref.invalidateSelf();
  }

  /// Desactiva una transacción recurrente
  Future<void> deactivate(String id) async {
    final dao = ref.read(recurringTransactionsDaoProvider);
    await dao.deactivate(id);
    ref.invalidateSelf();
  }

  /// Elimina una transacción recurrente
  Future<void> delete(String id) async {
    final dao = ref.read(recurringTransactionsDaoProvider);
    await dao.deleteEntry(id);
    ref.invalidateSelf();
  }

  /// Calcula la próxima fecha de ejecución
  DateTime _calculateNextExecution({
    required RecurrenceFrequency frequency,
    required int dayOfExecution,
    required DateTime fromDate,
  }) {
    final now = DateTime.now();
    var next = fromDate;

    // Si la fecha de inicio ya pasó, calcular desde hoy
    if (next.isBefore(now)) {
      next = now;
    }

    switch (frequency) {
      case RecurrenceFrequency.daily:
        return DateTime(next.year, next.month, next.day + 1);

      case RecurrenceFrequency.weekly:
        // dayOfExecution: 1 = Lunes, 7 = Domingo
        var daysUntilNext = dayOfExecution - next.weekday;
        if (daysUntilNext <= 0) daysUntilNext += 7;
        return DateTime(next.year, next.month, next.day + daysUntilNext);

      case RecurrenceFrequency.biweekly:
        var daysUntilNext = dayOfExecution - next.weekday;
        if (daysUntilNext <= 0) daysUntilNext += 14;
        return DateTime(next.year, next.month, next.day + daysUntilNext);

      case RecurrenceFrequency.monthly:
        var targetMonth = next.month;
        var targetYear = next.year;
        if (next.day >= dayOfExecution) {
          targetMonth++;
          if (targetMonth > 12) {
            targetMonth = 1;
            targetYear++;
          }
        }
        final lastDayOfMonth =
            DateTime(targetYear, targetMonth + 1, 0).day;
        final day =
            dayOfExecution > lastDayOfMonth ? lastDayOfMonth : dayOfExecution;
        return DateTime(targetYear, targetMonth, day);

      case RecurrenceFrequency.bimonthly:
        var targetMonth = next.month + 2;
        var targetYear = next.year;
        if (targetMonth > 12) {
          targetMonth -= 12;
          targetYear++;
        }
        final lastDayOfMonth =
            DateTime(targetYear, targetMonth + 1, 0).day;
        final day =
            dayOfExecution > lastDayOfMonth ? lastDayOfMonth : dayOfExecution;
        return DateTime(targetYear, targetMonth, day);

      case RecurrenceFrequency.quarterly:
        var targetMonth = next.month + 3;
        var targetYear = next.year;
        while (targetMonth > 12) {
          targetMonth -= 12;
          targetYear++;
        }
        final lastDayOfMonth =
            DateTime(targetYear, targetMonth + 1, 0).day;
        final day =
            dayOfExecution > lastDayOfMonth ? lastDayOfMonth : dayOfExecution;
        return DateTime(targetYear, targetMonth, day);

      case RecurrenceFrequency.semiannual:
        var targetMonth = next.month + 6;
        var targetYear = next.year;
        while (targetMonth > 12) {
          targetMonth -= 12;
          targetYear++;
        }
        final lastDayOfMonth =
            DateTime(targetYear, targetMonth + 1, 0).day;
        final day =
            dayOfExecution > lastDayOfMonth ? lastDayOfMonth : dayOfExecution;
        return DateTime(targetYear, targetMonth, day);

      case RecurrenceFrequency.yearly:
        return DateTime(next.year + 1, next.month, dayOfExecution);
    }
  }
}

/// Servicio para ejecutar transacciones recurrentes
@riverpod
class RecurringExecutionService extends _$RecurringExecutionService {
  @override
  FutureOr<void> build() {}

  /// Ejecuta todas las transacciones recurrentes pendientes
  Future<int> executeAllDue() async {
    final dao = ref.read(recurringTransactionsDaoProvider);
    final dueTransactions = await dao.getDueForExecution();

    var executedCount = 0;

    for (final recurring in dueTransactions) {
      // Solo ejecutar si no requiere confirmación
      if (!recurring.requiresConfirmation) {
        await _executeRecurring(recurring);
        executedCount++;
      }
    }

    return executedCount;
  }

  /// Ejecuta una transacción recurrente específica
  Future<void> executeOne(String id) async {
    final dao = ref.read(recurringTransactionsDaoProvider);
    final recurring = await dao.getById(id);

    if (recurring != null) {
      await _executeRecurring(recurring);
    }
  }

  /// Ejecuta la lógica de una transacción recurrente
  Future<void> _executeRecurring(RecurringTransactionEntry recurring) async {
    final dao = ref.read(recurringTransactionsDaoProvider);

    // Calcular próxima fecha de ejecución
    final frequency = RecurrenceFrequency.values.firstWhere(
      (f) => f.name == recurring.frequency,
      orElse: () => RecurrenceFrequency.monthly,
    );

    final nextDate = _calculateNextExecution(
      frequency: frequency,
      dayOfExecution: recurring.dayOfExecution,
      fromDate: DateTime.now(),
    );

    // Actualizar la transacción recurrente
    await dao.markAsExecuted(recurring.id, nextDate);
    await dao.incrementExecutionCount(recurring.id);

    // Verificar si debe desactivarse (fecha fin alcanzada)
    if (recurring.endDate != null && nextDate.isAfter(recurring.endDate!)) {
      await dao.deactivate(recurring.id);
    }

    // Invalidar providers relacionados
    ref.invalidate(activeRecurringTransactionsProvider);
    ref.invalidate(dueRecurringTransactionsProvider);
  }

  DateTime _calculateNextExecution({
    required RecurrenceFrequency frequency,
    required int dayOfExecution,
    required DateTime fromDate,
  }) {
    switch (frequency) {
      case RecurrenceFrequency.daily:
        return DateTime(fromDate.year, fromDate.month, fromDate.day + 1);

      case RecurrenceFrequency.weekly:
        return DateTime(fromDate.year, fromDate.month, fromDate.day + 7);

      case RecurrenceFrequency.biweekly:
        return DateTime(fromDate.year, fromDate.month, fromDate.day + 14);

      case RecurrenceFrequency.monthly:
        var targetMonth = fromDate.month + 1;
        var targetYear = fromDate.year;
        if (targetMonth > 12) {
          targetMonth = 1;
          targetYear++;
        }
        final lastDayOfMonth = DateTime(targetYear, targetMonth + 1, 0).day;
        final day =
            dayOfExecution > lastDayOfMonth ? lastDayOfMonth : dayOfExecution;
        return DateTime(targetYear, targetMonth, day);

      case RecurrenceFrequency.bimonthly:
        var targetMonth = fromDate.month + 2;
        var targetYear = fromDate.year;
        while (targetMonth > 12) {
          targetMonth -= 12;
          targetYear++;
        }
        final lastDayOfMonth = DateTime(targetYear, targetMonth + 1, 0).day;
        final day =
            dayOfExecution > lastDayOfMonth ? lastDayOfMonth : dayOfExecution;
        return DateTime(targetYear, targetMonth, day);

      case RecurrenceFrequency.quarterly:
        var targetMonth = fromDate.month + 3;
        var targetYear = fromDate.year;
        while (targetMonth > 12) {
          targetMonth -= 12;
          targetYear++;
        }
        final lastDayOfMonth = DateTime(targetYear, targetMonth + 1, 0).day;
        final day =
            dayOfExecution > lastDayOfMonth ? lastDayOfMonth : dayOfExecution;
        return DateTime(targetYear, targetMonth, day);

      case RecurrenceFrequency.semiannual:
        var targetMonth = fromDate.month + 6;
        var targetYear = fromDate.year;
        while (targetMonth > 12) {
          targetMonth -= 12;
          targetYear++;
        }
        final lastDayOfMonth = DateTime(targetYear, targetMonth + 1, 0).day;
        final day =
            dayOfExecution > lastDayOfMonth ? lastDayOfMonth : dayOfExecution;
        return DateTime(targetYear, targetMonth, day);

      case RecurrenceFrequency.yearly:
        return DateTime(
            fromDate.year + 1, fromDate.month, dayOfExecution);
    }
  }
}
