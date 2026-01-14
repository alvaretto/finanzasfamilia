import 'package:drift/drift.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/services/recurring_transaction_service.dart';
import '../local/daos/recurring_transactions_dao.dart';
import '../local/database.dart';

/// Implementación de RecurringTransactionRepository usando Drift
class DriftRecurringTransactionRepository
    implements RecurringTransactionRepository {
  final RecurringTransactionsDao _dao;

  DriftRecurringTransactionRepository(this._dao);

  /// Obtiene el userId del usuario autenticado actual
  /// Retorna null si Supabase no está inicializado (en tests)
  String? get _currentUserId {
    try {
      return Supabase.instance.client.auth.currentUser?.id;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<RecurringTransactionData>> getActive() async {
    final entries = await _dao.getActive();
    return entries.map(_toData).toList();
  }

  @override
  Future<List<RecurringTransactionData>> getDueForExecution() async {
    final entries = await _dao.getDueForExecution();
    return entries.map(_toData).toList();
  }

  @override
  Future<List<RecurringTransactionData>> getPendingConfirmation() async {
    final entries = await _dao.getPendingConfirmation();
    return entries.map(_toData).toList();
  }

  @override
  Future<RecurringTransactionData?> getById(String id) async {
    final entry = await _dao.getById(id);
    return entry != null ? _toData(entry) : null;
  }

  @override
  Future<void> insert(RecurringTransactionData data) async {
    await _dao.insert(_toCompanion(data));
  }

  @override
  Future<void> update(RecurringTransactionData data) async {
    await _dao.updateEntry(_toCompanion(data));
  }

  @override
  Future<void> delete(String id) async {
    await _dao.deleteEntry(id);
  }

  @override
  Future<void> activate(String id) async {
    await _dao.activate(id);
  }

  @override
  Future<void> deactivate(String id) async {
    await _dao.deactivate(id);
  }

  @override
  Future<void> markAsExecuted(String id, DateTime nextDate) async {
    await _dao.markAsExecuted(id, nextDate);
  }

  @override
  Future<void> incrementExecutionCount(String id) async {
    await _dao.incrementExecutionCount(id);
  }

  @override
  Stream<List<RecurringTransactionData>> watchActive() {
    return _dao.watchActive().map(
          (entries) => entries.map(_toData).toList(),
        );
  }

  @override
  Stream<List<RecurringTransactionData>> watchPendingConfirmation() {
    return _dao.watchPendingConfirmation().map(
          (entries) => entries.map(_toData).toList(),
        );
  }

  RecurringTransactionData _toData(RecurringTransactionEntry entry) {
    return RecurringTransactionData(
      id: entry.id,
      name: entry.name,
      type: entry.type,
      amount: entry.amount,
      description: entry.description,
      fromAccountId: entry.fromAccountId,
      toAccountId: entry.toAccountId,
      categoryId: entry.categoryId,
      frequency: entry.frequency,
      dayOfExecution: entry.dayOfExecution ?? 1,
      startDate: entry.startDate,
      endDate: entry.endDate,
      nextExecutionDate: entry.nextExecutionDate,
      lastExecutedAt: entry.lastExecutedAt,
      executionCount: entry.executionCount ?? 0,
      isActive: entry.isActive ?? true,
      requiresConfirmation: entry.requiresConfirmation ?? false,
      createdAt: entry.createdAt ?? DateTime.now(),
      updatedAt: entry.updatedAt ?? DateTime.now(),
    );
  }

  RecurringTransactionsCompanion _toCompanion(RecurringTransactionData data) {
    return RecurringTransactionsCompanion(
      id: Value(data.id),
      userId: Value(_currentUserId),
      name: Value(data.name),
      type: Value(data.type),
      amount: Value(data.amount),
      description: Value(data.description),
      fromAccountId: Value(data.fromAccountId),
      toAccountId: Value(data.toAccountId),
      categoryId: Value(data.categoryId),
      frequency: Value(data.frequency),
      dayOfExecution: Value(data.dayOfExecution),
      startDate: Value(data.startDate),
      endDate: Value(data.endDate),
      nextExecutionDate: data.nextExecutionDate != null
          ? Value(data.nextExecutionDate!)
          : const Value.absent(),
      lastExecutedAt: Value(data.lastExecutedAt),
      executionCount: Value(data.executionCount),
      isActive: Value(data.isActive),
      requiresConfirmation: Value(data.requiresConfirmation),
      createdAt: Value(data.createdAt),
      updatedAt: Value(data.updatedAt),
    );
  }
}
