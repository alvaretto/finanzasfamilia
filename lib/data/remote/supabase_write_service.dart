import 'dart:developer' as developer;

import 'package:supabase_flutter/supabase_flutter.dart';

/// Servicio centralizado para writes directos a Supabase
///
/// ARQUITECTURA: Online-first writes
/// - Todos los writes van directamente a Supabase
/// - PowerSync descarga los cambios → Drift local
/// - Lecturas desde Drift (rápido, offline-capable)
///
/// Beneficios:
/// - Evita FK violations del upload queue de PowerSync
/// - Supabase valida constraints inmediatamente
/// - Errores se detectan al momento del write
class SupabaseWriteService {
  final SupabaseClient _client;

  SupabaseWriteService(this._client);

  /// Usuario actual autenticado
  String? get currentUserId => _client.auth.currentUser?.id;

  /// Verifica si hay conexión/sesión activa
  bool get isAuthenticated => _client.auth.currentUser != null;

  // ===========================================================================
  // CATEGORIES
  // ===========================================================================

  Future<void> upsertCategory(Map<String, dynamic> data) async {
    _ensureUserId(data);
    _log('Upsert category: ${data['id']}');
    await _client.from('categories').upsert(data);
  }

  Future<void> deleteCategory(String id) async {
    _log('Delete category: $id');
    await _client.from('categories').delete().eq('id', id);
  }

  // ===========================================================================
  // ACCOUNTS
  // ===========================================================================

  Future<void> upsertAccount(Map<String, dynamic> data) async {
    _ensureUserId(data);
    _log('Upsert account: ${data['id']}');
    await _client.from('accounts').upsert(data);
  }

  Future<void> deleteAccount(String id) async {
    _log('Delete account: $id');
    await _client.from('accounts').delete().eq('id', id);
  }

  Future<void> updateAccountBalance(String id, double newBalance) async {
    _log('Update account balance: $id → $newBalance');
    await _client.from('accounts').update({
      'balance': newBalance,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', id);
  }

  // ===========================================================================
  // TRANSACTIONS
  // ===========================================================================

  Future<void> upsertTransaction(Map<String, dynamic> data) async {
    _ensureUserId(data);
    _log('Upsert transaction: ${data['id']}');
    await _client.from('transactions').upsert(data);
  }

  Future<void> deleteTransaction(String id) async {
    _log('Delete transaction: $id');
    // Primero eliminar dependencias
    await _client.from('journal_entries').delete().eq('transaction_id', id);
    await _client.from('transaction_details').delete().eq('transaction_id', id);
    await _client.from('transaction_attachments').delete().eq('transaction_id', id);
    // Luego la transacción
    await _client.from('transactions').delete().eq('id', id);
  }

  // ===========================================================================
  // JOURNAL ENTRIES
  // ===========================================================================

  Future<void> upsertJournalEntry(Map<String, dynamic> data) async {
    _ensureUserId(data);
    _log('Upsert journal_entry: ${data['id']}');
    await _client.from('journal_entries').upsert(data);
  }

  Future<void> upsertJournalEntries(List<Map<String, dynamic>> entries) async {
    for (final entry in entries) {
      _ensureUserId(entry);
    }
    _log('Upsert ${entries.length} journal_entries');
    await _client.from('journal_entries').upsert(entries);
  }

  Future<void> deleteJournalEntriesForTransaction(String transactionId) async {
    _log('Delete journal_entries for transaction: $transactionId');
    await _client.from('journal_entries').delete().eq('transaction_id', transactionId);
  }

  // ===========================================================================
  // TRANSACTION DETAILS
  // ===========================================================================

  Future<void> upsertTransactionDetail(Map<String, dynamic> data) async {
    _ensureUserId(data);
    _log('Upsert transaction_detail: ${data['id']}');
    await _client.from('transaction_details').upsert(data);
  }

  Future<void> deleteTransactionDetail(String id) async {
    _log('Delete transaction_detail: $id');
    await _client.from('transaction_details').delete().eq('id', id);
  }

  // ===========================================================================
  // BUDGETS
  // ===========================================================================

  Future<void> upsertBudget(Map<String, dynamic> data) async {
    _ensureUserId(data);
    _log('Upsert budget: ${data['id']}');
    await _client.from('budgets').upsert(data);
  }

  Future<void> deleteBudget(String id) async {
    _log('Delete budget: $id');
    await _client.from('budgets').delete().eq('id', id);
  }

  // ===========================================================================
  // SAVINGS GOALS
  // ===========================================================================

  Future<void> upsertSavingsGoal(Map<String, dynamic> data) async {
    _ensureUserId(data);
    _log('Upsert savings_goal: ${data['id']}');
    await _client.from('savings_goals').upsert(data);
  }

  Future<void> deleteSavingsGoal(String id) async {
    _log('Delete savings_goal: $id');
    // Primero eliminar contribuciones
    await _client.from('savings_contributions').delete().eq('goal_id', id);
    await _client.from('savings_goals').delete().eq('id', id);
  }

  Future<void> upsertSavingsContribution(Map<String, dynamic> data) async {
    _ensureUserId(data);
    _log('Upsert savings_contribution: ${data['id']}');
    await _client.from('savings_contributions').upsert(data);
  }

  // ===========================================================================
  // RECURRING TRANSACTIONS
  // ===========================================================================

  Future<void> upsertRecurringTransaction(Map<String, dynamic> data) async {
    _ensureUserId(data);
    _log('Upsert recurring_transaction: ${data['id']}');
    await _client.from('recurring_transactions').upsert(data);
  }

  Future<void> deleteRecurringTransaction(String id) async {
    _log('Delete recurring_transaction: $id');
    await _client.from('recurring_transactions').delete().eq('id', id);
  }

  // ===========================================================================
  // PLACES
  // ===========================================================================

  Future<void> upsertPlace(Map<String, dynamic> data) async {
    _ensureUserId(data);
    _log('Upsert place: ${data['id']}');
    await _client.from('places').upsert(data);
  }

  Future<void> deletePlace(String id) async {
    _log('Delete place: $id');
    await _client.from('places').delete().eq('id', id);
  }

  // ===========================================================================
  // PAYMENT METHODS
  // ===========================================================================

  Future<void> upsertPaymentMethod(Map<String, dynamic> data) async {
    _ensureUserId(data);
    _log('Upsert payment_method: ${data['id']}');
    await _client.from('payment_methods').upsert(data);
  }

  Future<void> deletePaymentMethod(String id) async {
    _log('Delete payment_method: $id');
    await _client.from('payment_methods').delete().eq('id', id);
  }

  // ===========================================================================
  // USER SETTINGS
  // ===========================================================================

  Future<void> upsertUserSettings(Map<String, dynamic> data) async {
    // user_settings usa user_id como PK, no id
    if (!data.containsKey('user_id')) {
      data['user_id'] = currentUserId;
    }
    _log('Upsert user_settings for user: ${data['user_id']}');
    await _client.from('user_settings').upsert(data);
  }

  // ===========================================================================
  // ATTACHMENTS
  // ===========================================================================

  Future<void> upsertAttachment(Map<String, dynamic> data) async {
    _ensureUserId(data);
    _log('Upsert transaction_attachment: ${data['id']}');
    await _client.from('transaction_attachments').upsert(data);
  }

  Future<void> deleteAttachment(String id) async {
    _log('Delete transaction_attachment: $id');
    await _client.from('transaction_attachments').delete().eq('id', id);
  }

  // ===========================================================================
  // FAMILIES
  // ===========================================================================

  Future<void> upsertFamily(Map<String, dynamic> data) async {
    _ensureUserId(data);
    _log('Upsert family: ${data['id']}');
    await _client.from('families').upsert(data);
  }

  Future<void> deleteFamily(String id) async {
    _log('Delete family: $id');
    await _client.from('families').delete().eq('id', id);
  }

  Future<void> upsertFamilyMember(Map<String, dynamic> data) async {
    // family_members usa sync_user_id para RLS
    if (!data.containsKey('sync_user_id')) {
      data['sync_user_id'] = currentUserId;
    }
    _log('Upsert family_member: ${data['id']}');
    await _client.from('family_members').upsert(data);
  }

  Future<void> upsertFamilyInvitation(Map<String, dynamic> data) async {
    _ensureUserId(data);
    _log('Upsert family_invitation: ${data['id']}');
    await _client.from('family_invitations').upsert(data);
  }

  // ===========================================================================
  // GENERIC METHODS
  // ===========================================================================

  /// Upsert genérico para cualquier tabla
  Future<void> upsert(String table, Map<String, dynamic> data) async {
    _ensureUserId(data);
    _log('Generic upsert in $table: ${data['id']}');
    await _client.from(table).upsert(data);
  }

  /// Delete genérico para cualquier tabla
  Future<void> delete(String table, String id) async {
    _log('Generic delete in $table: $id');
    await _client.from(table).delete().eq('id', id);
  }

  /// Batch upsert para múltiples registros
  Future<void> batchUpsert(String table, List<Map<String, dynamic>> records) async {
    for (final record in records) {
      _ensureUserId(record);
    }
    _log('Batch upsert in $table: ${records.length} records');
    await _client.from(table).upsert(records);
  }

  // ===========================================================================
  // HELPERS
  // ===========================================================================

  /// Agrega user_id si no está presente
  void _ensureUserId(Map<String, dynamic> data) {
    if (!data.containsKey('user_id') && currentUserId != null) {
      data['user_id'] = currentUserId;
    }
  }

  void _log(String message) {
    developer.log(message, name: 'SupabaseWriteService');
  }
}
