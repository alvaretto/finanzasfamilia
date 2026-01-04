import 'package:drift/drift.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/network/supabase_client.dart';
import '../../domain/models/goal_model.dart';

/// Repositorio de metas con soporte offline-first
class GoalRepository {
  final AppDatabase _db;
  final SupabaseClient? _supabase;

  GoalRepository({
    AppDatabase? database,
    SupabaseClient? supabaseClient,
  })  : _db = database ?? AppDatabase(),
        _supabase = supabaseClient ?? SupabaseClientProvider.clientOrNull;

  /// Verifica si Supabase está disponible
  bool get _isOnline => _supabase != null && SupabaseClientProvider.isInitialized;

  // ==================== OPERACIONES LOCALES ====================

  /// Obtener metas del usuario
  Stream<List<GoalModel>> watchGoals(String userId) {
    final query = _db.select(_db.goals)
      ..where((t) => t.userId.equals(userId))
      ..orderBy([(t) => OrderingTerm.asc(t.completedAt)]);

    return query.watch().map((rows) => rows.map(_goalFromRow).toList());
  }

  /// Obtener metas activas (no completadas)
  Stream<List<GoalModel>> watchActiveGoals(String userId) {
    final query = _db.select(_db.goals)
      ..where((t) => t.userId.equals(userId) & t.completedAt.isNull())
      ..orderBy([(t) => OrderingTerm.asc(t.targetDate)]);

    return query.watch().map((rows) => rows.map(_goalFromRow).toList());
  }

  /// Obtener metas completadas
  Stream<List<GoalModel>> watchCompletedGoals(String userId) {
    final query = _db.select(_db.goals)
      ..where((t) => t.userId.equals(userId) & t.completedAt.isNotNull())
      ..orderBy([(t) => OrderingTerm.desc(t.completedAt)]);

    return query.watch().map((rows) => rows.map(_goalFromRow).toList());
  }

  /// Obtener meta por ID
  Future<GoalModel?> getGoalById(String id) async {
    final query = _db.select(_db.goals)..where((t) => t.id.equals(id));
    final result = await query.getSingleOrNull();
    return result != null ? _goalFromRow(result) : null;
  }

  /// Crear meta
  Future<GoalModel> createGoal(GoalModel goal) async {
    final companion = GoalsCompanion.insert(
      id: goal.id,
      userId: goal.userId,
      familyId: Value(goal.familyId),
      name: goal.name,
      targetAmount: goal.targetAmount,
      currentAmount: Value(goal.currentAmount),
      targetDate: Value(goal.targetDate),
      icon: Value(goal.icon),
      color: Value(goal.color),
      isSynced: const Value(false),
      completedAt: Value(goal.completedAt),
    );

    await _db.into(_db.goals).insert(companion);
    return goal.copyWith(isSynced: false);
  }

  /// Actualizar meta
  Future<void> updateGoal(GoalModel goal) async {
    await (_db.update(_db.goals)..where((t) => t.id.equals(goal.id)))
        .write(GoalsCompanion(
      name: Value(goal.name),
      targetAmount: Value(goal.targetAmount),
      currentAmount: Value(goal.currentAmount),
      targetDate: Value(goal.targetDate),
      icon: Value(goal.icon),
      color: Value(goal.color),
      completedAt: Value(goal.completedAt),
      isSynced: const Value(false),
    ));
  }

  /// Agregar monto a meta
  Future<GoalModel?> addAmount(String id, double amount) async {
    final goal = await getGoalById(id);
    if (goal == null) return null;

    final newAmount = goal.currentAmount + amount;
    final isNowComplete = newAmount >= goal.targetAmount;

    await (_db.update(_db.goals)..where((t) => t.id.equals(id)))
        .write(GoalsCompanion(
      currentAmount: Value(newAmount),
      completedAt: isNowComplete && goal.completedAt == null
          ? Value(DateTime.now())
          : Value(goal.completedAt),
      isSynced: const Value(false),
    ));

    return await getGoalById(id);
  }

  /// Retirar monto de meta
  Future<GoalModel?> withdrawAmount(String id, double amount) async {
    final goal = await getGoalById(id);
    if (goal == null) return null;

    final newAmount = (goal.currentAmount - amount).clamp(0.0, double.infinity);

    await (_db.update(_db.goals)..where((t) => t.id.equals(id)))
        .write(GoalsCompanion(
      currentAmount: Value(newAmount),
      completedAt: const Value(null), // Ya no está completada
      isSynced: const Value(false),
    ));

    return await getGoalById(id);
  }

  /// Eliminar meta
  Future<void> deleteGoal(String id) async {
    await (_db.delete(_db.goals)..where((t) => t.id.equals(id))).go();
  }

  /// Obtener no sincronizados
  Future<List<GoalModel>> getUnsyncedGoals() async {
    final query = _db.select(_db.goals)
      ..where((t) => t.isSynced.equals(false));
    final results = await query.get();
    return results.map(_goalFromRow).toList();
  }

  /// Marcar como sincronizado
  Future<void> markAsSynced(String id) async {
    await (_db.update(_db.goals)..where((t) => t.id.equals(id)))
        .write(const GoalsCompanion(isSynced: Value(true)));
  }

  // ==================== ESTADISTICAS ====================

  /// Total ahorrado en todas las metas
  Future<double> getTotalSaved(String userId) async {
    final query = _db.select(_db.goals)
      ..where((t) => t.userId.equals(userId));
    final results = await query.get();
    double total = 0;
    for (final g in results) {
      total += g.currentAmount;
    }
    return total;
  }

  /// Total objetivo de todas las metas
  Future<double> getTotalTarget(String userId) async {
    final query = _db.select(_db.goals)
      ..where((t) => t.userId.equals(userId) & t.completedAt.isNull());
    final results = await query.get();
    double total = 0;
    for (final g in results) {
      total += g.targetAmount;
    }
    return total;
  }

  // ==================== SYNC ====================

  /// Sincronizar con Supabase
  Future<void> syncWithSupabase(String userId) async {
    try {
      // Subir no sincronizados
      final unsynced = await getUnsyncedGoals();
      for (final goal in unsynced) {
        await _upsertToSupabase(goal);
        await markAsSynced(goal.id);
      }

      // Descargar del servidor
      final remote = await _fetchFromSupabase(userId);
      for (final remoteGoal in remote) {
        final local = await getGoalById(remoteGoal.id);
        if (local == null) {
          await _insertFromRemote(remoteGoal);
        } else if (!local.isSynced) {
          await _upsertToSupabase(local);
          await markAsSynced(local.id);
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _upsertToSupabase(GoalModel goal) async {
    if (_isOnline) await _supabase!.from('goals').upsert(goal.toSupabaseMap());
  }

  Future<List<GoalModel>> _fetchFromSupabase(String userId) async {
    if (!_isOnline) return [];
    final response = await _supabase!
        .from('goals')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => GoalModel.fromSupabase(json as Map<String, dynamic>))
        .toList();
  }

  Future<void> _insertFromRemote(GoalModel goal) async {
    final companion = GoalsCompanion.insert(
      id: goal.id,
      userId: goal.userId,
      familyId: Value(goal.familyId),
      name: goal.name,
      targetAmount: goal.targetAmount,
      currentAmount: Value(goal.currentAmount),
      targetDate: Value(goal.targetDate),
      icon: Value(goal.icon),
      color: Value(goal.color),
      isSynced: const Value(true),
      createdAt: Value(goal.createdAt ?? DateTime.now()),
      completedAt: Value(goal.completedAt),
    );

    await _db.into(_db.goals).insertOnConflictUpdate(companion);
  }

  // ==================== HELPERS ====================

  GoalModel _goalFromRow(Goal row) {
    return GoalModel(
      id: row.id,
      userId: row.userId,
      familyId: row.familyId,
      name: row.name,
      targetAmount: row.targetAmount,
      currentAmount: row.currentAmount,
      targetDate: row.targetDate,
      icon: row.icon,
      color: row.color,
      isSynced: row.isSynced,
      createdAt: row.createdAt,
      completedAt: row.completedAt,
    );
  }
}
