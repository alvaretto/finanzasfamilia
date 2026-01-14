import 'package:drift/drift.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/repositories/budget_repository.dart';
import '../local/daos/budgets_dao.dart';
import '../local/daos/transactions_dao.dart';
import '../local/database.dart';

/// Implementación Drift del repositorio de presupuestos.
class DriftBudgetRepository implements BudgetRepository {
  final BudgetsDao _dao;

  DriftBudgetRepository(this._dao);

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
  Future<List<BudgetData>> getActiveBudgets() async {
    final entries = await _dao.getActiveBudgets();
    return entries.map(_toData).toList();
  }

  @override
  Future<List<BudgetData>> getBudgetsForMonth(int month, int year) async {
    final entries = await _dao.getBudgetsForMonth(month, year);
    return entries.map(_toData).toList();
  }

  @override
  Future<BudgetData?> getBudgetForCategory(
    String categoryId,
    int month,
    int year,
  ) async {
    final entry = await _dao.getBudgetForCategory(categoryId, month, year);
    return entry != null ? _toData(entry) : null;
  }

  @override
  Future<void> createBudget(String id, CreateBudgetData data) async {
    final now = DateTime.now();
    await _dao.insertBudget(BudgetsCompanion.insert(
      id: id,
      userId: Value(_currentUserId),
      categoryId: data.categoryId,
      amount: data.amount,
      month: data.month,
      year: data.year,
      isActive: const Value(true),
      createdAt: Value(now),
      updatedAt: Value(now),
    ));
  }

  @override
  Future<void> updateBudgetAmount(String id, double amount) async {
    final now = DateTime.now();
    await _dao.updateBudget(BudgetsCompanion(
      id: Value(id),
      amount: Value(amount),
      updatedAt: Value(now),
    ));
  }

  @override
  Future<void> deleteBudget(String id) async {
    await _dao.deleteBudget(id);
  }

  @override
  Stream<List<BudgetData>> watchCurrentMonthBudgets() {
    return _dao.watchCurrentMonthBudgets().map(
          (entries) => entries.map(_toData).toList(),
        );
  }

  BudgetData _toData(BudgetEntry entry) => BudgetData(
        id: entry.id,
        categoryId: entry.categoryId,
        amount: entry.amount,
        month: entry.month,
        year: entry.year,
        isActive: entry.isActive ?? true,
        createdAt: entry.createdAt ?? DateTime.now(),
        updatedAt: entry.updatedAt ?? DateTime.now(),
      );
}

/// Implementación Drift del repositorio de gastos por categoría.
class DriftCategorySpendingRepository implements CategorySpendingRepository {
  final TransactionsDao _dao;

  DriftCategorySpendingRepository(this._dao);

  @override
  Future<double> getTotalSpentInPeriod(
    String categoryId,
    DateTime start,
    DateTime end,
  ) async {
    return _dao.getTotalByCategoryInPeriod(categoryId, start, end);
  }
}
