import 'package:drift/drift.dart';

import '../../domain/repositories/journal_entry_repository.dart';
import '../local/database.dart';
import '../remote/supabase_write_service.dart';

/// Repositorio híbrido de journal entries (asientos contables)
///
/// ARQUITECTURA: Online-first writes, local reads
class HybridJournalEntryRepository implements JournalEntryRepository {
  final AppDatabase _db;
  final SupabaseWriteService _supabaseWrite;

  HybridJournalEntryRepository(this._db, this._supabaseWrite);

  String? get _currentUserId => _supabaseWrite.currentUserId;

  @override
  Future<int> getNextEntryNumber() async {
    // READ: desde Drift (local)
    final maxNumber = _db.journalEntries.entryNumber.max();
    final query = _db.selectOnly(_db.journalEntries)..addColumns([maxNumber]);
    final result = await query.getSingle();
    return (result.read(maxNumber) ?? 0) + 1;
  }

  @override
  Future<void> insertEntries(List<JournalEntryData> entries) async {
    if (entries.isEmpty) return;

    final now = DateTime.now();

    // Preparar datos para Supabase
    final supabaseData = entries.map((e) => {
      'id': e.id,
      'user_id': _currentUserId,
      'transaction_id': e.transactionId,
      'account_id': e.accountId,
      'category_id': e.categoryId,
      'entry_type': e.entryType,
      'amount': e.amount,
      'description': e.description,
      'entry_number': e.entryNumber,
      'entry_date': e.entryDate.toIso8601String(),
      'created_at': e.createdAt.toIso8601String(),
      'updated_at': now.toIso8601String(),
    }).toList();

    // 1. WRITE: Supabase primero (batch)
    await _supabaseWrite.upsertJournalEntries(supabaseData);

    // 2. WRITE: Drift local (para UI inmediata)
    final companions = entries.map((e) => JournalEntriesCompanion(
          id: Value(e.id),
          userId: Value(_currentUserId),
          transactionId: Value(e.transactionId),
          accountId: Value(e.accountId),
          categoryId: Value(e.categoryId),
          entryType: Value(e.entryType),
          amount: Value(e.amount),
          description: Value(e.description),
          entryNumber: Value(e.entryNumber),
          entryDate: Value(e.entryDate),
          createdAt: Value(e.createdAt),
          updatedAt: Value(now),
        ));

    await _db.batch((batch) {
      batch.insertAllOnConflictUpdate(_db.journalEntries, companions.toList());
    });
  }

  @override
  Future<void> deleteEntriesByTransaction(String transactionId) async {
    // 1. DELETE: Supabase primero
    await _supabaseWrite.deleteJournalEntriesForTransaction(transactionId);

    // 2. DELETE: Drift local
    await (_db.delete(_db.journalEntries)
          ..where((je) => je.transactionId.equals(transactionId)))
        .go();
  }

  @override
  Future<List<JournalEntryData>> getEntriesByTransaction(
      String transactionId) async {
    // READ: desde Drift (local)
    final entries = await (_db.select(_db.journalEntries)
          ..where((je) => je.transactionId.equals(transactionId))
          ..orderBy([(je) => OrderingTerm.asc(je.entryNumber)]))
        .get();

    return entries.map(_toJournalEntryData).toList();
  }

  JournalEntryData _toJournalEntryData(JournalEntryRecord entry) {
    return JournalEntryData(
      id: entry.id,
      transactionId: entry.transactionId,
      accountId: entry.accountId,
      categoryId: entry.categoryId,
      entryType: entry.entryType,
      amount: entry.amount,
      description: entry.description,
      entryNumber: entry.entryNumber,
      entryDate: entry.entryDate,
      createdAt: entry.createdAt,
      updatedAt: entry.updatedAt,
    );
  }
}
