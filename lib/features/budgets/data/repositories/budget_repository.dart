import 'package:drift/drift.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/network/supabase_client.dart';
import '../../domain/models/budget_model.dart';

/// Repositorio de presupuestos con soporte offline-first
class BudgetRepository {
  final AppDatabase _db;
  final SupabaseClient _supabase;

  BudgetRepository({
    AppDatabase? database,
    SupabaseClient? supabaseClient,
  })  : _db = database ?? AppDatabase(),
        _supabase = supabaseClient ?? SupabaseClientProvider.client;

  // ==================== OPERACIONES LOCALES ====================

  /// Obtener presupuestos del usuario
  Stream<List<BudgetModel>> watchBudgets(String userId) {
    final query = _db.select(_db.budgets).join([
      leftOuterJoin(
        _db.categories,
        _db.categories.id.equalsExp(_db.budgets.categoryId),
      ),
    ])
      ..where(_db.budgets.userId.equals(userId))
      ..orderBy([OrderingTerm.desc(_db.budgets.createdAt)]);

    return query.watch().map((rows) {
      return rows.map((row) {
        final budget = row.readTable(_db.budgets);
        final category = row.readTableOrNull(_db.categories);
        return _budgetFromRow(budget, category: category);
      }).toList();
    });
  }

  /// Obtener presupuesto por ID
  Future<BudgetModel?> getBudgetById(String id) async {
    final query = _db.select(_db.budgets).join([
      leftOuterJoin(
        _db.categories,
        _db.categories.id.equalsExp(_db.budgets.categoryId),
      ),
    ])
      ..where(_db.budgets.id.equals(id));

    final result = await query.getSingleOrNull();
    if (result == null) return null;

    final budget = result.readTable(_db.budgets);
    final category = result.readTableOrNull(_db.categories);
    return _budgetFromRow(budget, category: category);
  }

  /// Obtener presupuesto por categoria
  Future<BudgetModel?> getBudgetByCategory(String userId, int categoryId) async {
    final query = _db.select(_db.budgets).join([
      leftOuterJoin(
        _db.categories,
        _db.categories.id.equalsExp(_db.budgets.categoryId),
      ),
    ])
      ..where(_db.budgets.userId.equals(userId) &
          _db.budgets.categoryId.equals(categoryId));

    final result = await query.getSingleOrNull();
    if (result == null) return null;

    final budget = result.readTable(_db.budgets);
    final category = result.readTableOrNull(_db.categories);
    return _budgetFromRow(budget, category: category);
  }

  /// Crear presupuesto
  Future<BudgetModel> createBudget(BudgetModel budget) async {
    final companion = BudgetsCompanion.insert(
      id: budget.id,
      userId: budget.userId,
      familyId: Value(budget.familyId),
      categoryId: budget.categoryId,
      amount: budget.amount,
      period: Value(budget.period.name),
      startDate: budget.startDate,
      endDate: Value(budget.endDate),
      isSynced: const Value(false),
    );

    await _db.into(_db.budgets).insert(companion);
    return budget.copyWith(isSynced: false);
  }

  /// Actualizar presupuesto
  Future<void> updateBudget(BudgetModel budget) async {
    await (_db.update(_db.budgets)..where((t) => t.id.equals(budget.id)))
        .write(BudgetsCompanion(
      categoryId: Value(budget.categoryId),
      amount: Value(budget.amount),
      period: Value(budget.period.name),
      startDate: Value(budget.startDate),
      endDate: Value(budget.endDate),
      isSynced: const Value(false),
    ));
  }

  /// Eliminar presupuesto
  Future<void> deleteBudget(String id) async {
    await (_db.delete(_db.budgets)..where((t) => t.id.equals(id))).go();
  }

  /// Obtener gasto por categoria en periodo
  Future<double> getSpentByCategory(
    String userId,
    int categoryId, {
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    final query = _db.select(_db.transactions)
      ..where((t) =>
          t.userId.equals(userId) &
          t.categoryId.equals(categoryId) &
          t.type.equals('expense') &
          t.date.isBiggerOrEqualValue(fromDate) &
          t.date.isSmallerOrEqualValue(toDate));

    final results = await query.get();
    double total = 0;
    for (final tx in results) {
      total += tx.amount;
    }
    return total;
  }

  /// Obtener presupuestos con gastos actuales
  Stream<List<BudgetModel>> watchBudgetsWithSpent(String userId) {
    return watchBudgets(userId).asyncMap((budgets) async {
      final results = <BudgetModel>[];

      for (final budget in budgets) {
        final (from, to) = _getPeriodDates(budget.period, budget.startDate);
        final spent = await getSpentByCategory(
          userId,
          budget.categoryId,
          fromDate: from,
          toDate: to,
        );
        results.add(budget.copyWith(spent: spent));
      }

      return results;
    });
  }

  /// Calcular fechas del periodo
  (DateTime, DateTime) _getPeriodDates(BudgetPeriod period, DateTime start) {
    final now = DateTime.now();
    switch (period) {
      case BudgetPeriod.weekly:
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        return (
          DateTime(weekStart.year, weekStart.month, weekStart.day),
          DateTime(weekStart.year, weekStart.month, weekStart.day + 6, 23, 59, 59),
        );
      case BudgetPeriod.monthly:
        return (
          DateTime(now.year, now.month, 1),
          DateTime(now.year, now.month + 1, 0, 23, 59, 59),
        );
      case BudgetPeriod.yearly:
        return (
          DateTime(now.year, 1, 1),
          DateTime(now.year, 12, 31, 23, 59, 59),
        );
    }
  }

  /// Obtener no sincronizados
  Future<List<BudgetModel>> getUnsyncedBudgets() async {
    final query = _db.select(_db.budgets)
      ..where((t) => t.isSynced.equals(false));
    final results = await query.get();
    return results.map((b) => _budgetFromRow(b)).toList();
  }

  /// Marcar como sincronizado
  Future<void> markAsSynced(String id) async {
    await (_db.update(_db.budgets)..where((t) => t.id.equals(id)))
        .write(const BudgetsCompanion(isSynced: Value(true)));
  }

  // ==================== SYNC ====================

  /// Sincronizar con Supabase
  Future<void> syncWithSupabase(String userId) async {
    try {
      // Subir no sincronizados
      final unsynced = await getUnsyncedBudgets();
      for (final budget in unsynced) {
        await _upsertToSupabase(budget);
        await markAsSynced(budget.id);
      }

      // Descargar del servidor
      final remote = await _fetchFromSupabase(userId);
      for (final remoteBudget in remote) {
        final local = await getBudgetById(remoteBudget.id);
        if (local == null) {
          await _insertFromRemote(remoteBudget);
        } else if (!local.isSynced) {
          await _upsertToSupabase(local);
          await markAsSynced(local.id);
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _upsertToSupabase(BudgetModel budget) async {
    await _supabase.from('budgets').upsert(budget.toSupabaseMap());
  }

  Future<List<BudgetModel>> _fetchFromSupabase(String userId) async {
    final response = await _supabase
        .from('budgets')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => BudgetModel.fromSupabase(json as Map<String, dynamic>))
        .toList();
  }

  Future<void> _insertFromRemote(BudgetModel budget) async {
    final companion = BudgetsCompanion.insert(
      id: budget.id,
      userId: budget.userId,
      familyId: Value(budget.familyId),
      categoryId: budget.categoryId,
      amount: budget.amount,
      period: Value(budget.period.name),
      startDate: budget.startDate,
      endDate: Value(budget.endDate),
      isSynced: const Value(true),
      createdAt: Value(budget.createdAt ?? DateTime.now()),
    );

    await _db.into(_db.budgets).insertOnConflictUpdate(companion);
  }

  // ==================== HELPERS ====================

  BudgetModel _budgetFromRow(Budget row, {Category? category}) {
    return BudgetModel(
      id: row.id,
      userId: row.userId,
      familyId: row.familyId,
      categoryId: row.categoryId,
      amount: row.amount,
      period: BudgetPeriod.values.firstWhere(
        (e) => e.name == row.period,
        orElse: () => BudgetPeriod.monthly,
      ),
      startDate: row.startDate,
      endDate: row.endDate,
      isSynced: row.isSynced,
      createdAt: row.createdAt,
      categoryName: category?.name,
      categoryIcon: category?.icon,
      categoryColor: category?.color,
    );
  }
}
