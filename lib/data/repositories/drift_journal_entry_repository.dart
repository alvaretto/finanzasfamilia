import 'package:drift/drift.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/repositories/journal_entry_repository.dart';
import '../local/database.dart';

/// Implementación concreta de JournalEntryRepository usando Drift.
class DriftJournalEntryRepository implements JournalEntryRepository {
  final AppDatabase _db;

  DriftJournalEntryRepository(this._db);

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
  Future<int> getNextEntryNumber() async {
    final maxNumber = _db.journalEntries.entryNumber.max();
    final query = _db.selectOnly(_db.journalEntries)..addColumns([maxNumber]);
    final result = await query.getSingle();
    return (result.read(maxNumber) ?? 0) + 1;
  }

  @override
  Future<void> insertEntries(List<JournalEntryData> entries) async {
    final userId = _currentUserId;
    final companions = entries.map((e) => JournalEntriesCompanion(
          id: Value(e.id),
          userId: Value(userId),
          transactionId: Value(e.transactionId),
          accountId: Value(e.accountId),
          categoryId: Value(e.categoryId),
          entryType: Value(e.entryType),
          amount: Value(e.amount),
          description: Value(e.description),
          entryNumber: Value(e.entryNumber),
          entryDate: Value(e.entryDate),
          createdAt: Value(e.createdAt),
          updatedAt: Value(e.updatedAt),
        ));

    await _db.batch((batch) {
      batch.insertAll(_db.journalEntries, companions.toList());
    });
  }

  @override
  Future<void> deleteEntriesByTransaction(String transactionId) async {
    await (_db.delete(_db.journalEntries)
          ..where((je) => je.transactionId.equals(transactionId)))
        .go();
  }

  @override
  Future<List<JournalEntryData>> getEntriesByTransaction(
      String transactionId) async {
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
