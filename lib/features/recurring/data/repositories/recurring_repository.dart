import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/recurring_model.dart';

class RecurringRepository {
  final _supabase = Supabase.instance.client;

  static const _selectQuery = '''
    *,
    accounts (name),
    categories (name, icon, color)
  ''';

  /// Obtener todas las transacciones recurrentes del usuario
  Future<List<RecurringModel>> getRecurring(String userId) async {
    final response = await _supabase
        .from('recurring_transactions')
        .select(_selectQuery)
        .eq('user_id', userId)
        .order('next_occurrence', ascending: true);

    return (response as List)
        .map((json) => RecurringModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Obtener transacciones recurrentes activas
  Future<List<RecurringModel>> getActiveRecurring(String userId) async {
    final response = await _supabase
        .from('recurring_transactions')
        .select(_selectQuery)
        .eq('user_id', userId)
        .eq('is_active', true)
        .order('next_occurrence', ascending: true);

    return (response as List)
        .map((json) => RecurringModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Obtener transacciones pendientes (vencidas o de hoy)
  Future<List<RecurringModel>> getPendingRecurring(String userId) async {
    final today = DateTime.now().toIso8601String().split('T')[0];

    final response = await _supabase
        .from('recurring_transactions')
        .select(_selectQuery)
        .eq('user_id', userId)
        .eq('is_active', true)
        .lte('next_occurrence', today)
        .order('next_occurrence', ascending: true);

    return (response as List)
        .map((json) => RecurringModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Crear transacción recurrente
  Future<RecurringModel> createRecurring(RecurringModel recurring) async {
    final response = await _supabase
        .from('recurring_transactions')
        .insert(recurring.toInsertJson())
        .select(_selectQuery)
        .single();

    return RecurringModel.fromJson(response);
  }

  /// Actualizar transacción recurrente
  Future<RecurringModel> updateRecurring(RecurringModel recurring) async {
    final response = await _supabase
        .from('recurring_transactions')
        .update({
          'account_id': recurring.accountId,
          'category_id': recurring.categoryId,
          'amount': recurring.amount,
          'type': recurring.type.name,
          'description': recurring.description,
          'frequency': recurring.frequency.name,
          'end_date': recurring.endDate?.toIso8601String().split('T')[0],
          'is_active': recurring.isActive,
        })
        .eq('id', recurring.id)
        .select(_selectQuery)
        .single();

    return RecurringModel.fromJson(response);
  }

  /// Ejecutar transacción recurrente (crear transacción real)
  Future<void> executeRecurring(RecurringModel recurring) async {
    // Crear la transacción real
    await _supabase.from('transactions').insert({
      'user_id': recurring.userId,
      'account_id': recurring.accountId,
      'category_id': recurring.categoryId,
      'amount': recurring.amount,
      'type': recurring.type.name,
      'description': recurring.description,
      'date': recurring.nextOccurrence.toIso8601String().split('T')[0],
      'recurring_id': recurring.id,
    });

    // Actualizar el balance de la cuenta
    final balanceChange =
        recurring.type == RecurringType.income ? recurring.amount : -recurring.amount;

    await _supabase.rpc('update_account_balance', params: {
      'account_id_param': recurring.accountId,
      'amount_param': balanceChange,
    });

    // Calcular siguiente ocurrencia
    final nextOccurrence = recurring.frequency.nextFrom(recurring.nextOccurrence);

    // Verificar si ya terminó
    final shouldDeactivate = recurring.endDate != null &&
        nextOccurrence.isAfter(recurring.endDate!);

    // Actualizar la recurrencia
    await _supabase.from('recurring_transactions').update({
      'next_occurrence': nextOccurrence.toIso8601String().split('T')[0],
      'is_active': !shouldDeactivate,
    }).eq('id', recurring.id);
  }

  /// Saltar una ocurrencia
  Future<void> skipOccurrence(RecurringModel recurring) async {
    final nextOccurrence = recurring.frequency.nextFrom(recurring.nextOccurrence);

    final shouldDeactivate = recurring.endDate != null &&
        nextOccurrence.isAfter(recurring.endDate!);

    await _supabase.from('recurring_transactions').update({
      'next_occurrence': nextOccurrence.toIso8601String().split('T')[0],
      'is_active': !shouldDeactivate,
    }).eq('id', recurring.id);
  }

  /// Pausar/Reanudar recurrencia
  Future<void> toggleActive(String id, bool isActive) async {
    await _supabase
        .from('recurring_transactions')
        .update({'is_active': isActive})
        .eq('id', id);
  }

  /// Eliminar transacción recurrente
  Future<void> deleteRecurring(String id) async {
    await _supabase.from('recurring_transactions').delete().eq('id', id);
  }

  /// Stream de transacciones recurrentes
  Stream<List<RecurringModel>> watchRecurring(String userId) {
    return _supabase
        .from('recurring_transactions')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('next_occurrence', ascending: true)
        .asyncMap((_) => getRecurring(userId));
  }
}
