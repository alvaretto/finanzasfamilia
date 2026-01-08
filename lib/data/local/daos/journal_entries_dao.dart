import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/journal_entries_table.dart';

part 'journal_entries_dao.g.dart';

/// DAO para operaciones con asientos contables (Partida Doble)
@DriftAccessor(tables: [JournalEntries])
class JournalEntriesDao extends DatabaseAccessor<AppDatabase>
    with _$JournalEntriesDaoMixin {
  JournalEntriesDao(super.db);

  /// Obtiene todos los asientos de una transacción
  Future<List<JournalEntryRecord>> getEntriesByTransaction(
    String transactionId,
  ) {
    return (select(journalEntries)
          ..where((je) => je.transactionId.equals(transactionId))
          ..orderBy([(je) => OrderingTerm.asc(je.entryNumber)]))
        .get();
  }

  /// Obtiene asientos de una cuenta en un período
  Future<List<JournalEntryRecord>> getEntriesByAccountInPeriod(
    String accountId,
    DateTime start,
    DateTime end,
  ) {
    return (select(journalEntries)
          ..where((je) => je.accountId.equals(accountId))
          ..where((je) => je.entryDate.isBiggerOrEqualValue(start))
          ..where((je) => je.entryDate.isSmallerOrEqualValue(end))
          ..orderBy([(je) => OrderingTerm.asc(je.entryDate)]))
        .get();
  }

  /// Obtiene un asiento por ID
  Future<JournalEntryRecord?> getEntryById(String id) {
    return (select(journalEntries)..where((je) => je.id.equals(id)))
        .getSingleOrNull();
  }

  /// Inserta un nuevo asiento
  Future<void> insertEntry(JournalEntriesCompanion entry) {
    return into(journalEntries).insert(entry);
  }

  /// Inserta múltiples asientos (para partida doble completa)
  Future<void> insertEntries(List<JournalEntriesCompanion> entries) {
    return batch((batch) {
      batch.insertAll(journalEntries, entries);
    });
  }

  /// Actualiza un asiento
  Future<bool> updateEntry(JournalEntryRecord entry) {
    return update(journalEntries).replace(entry);
  }

  /// Elimina asientos de una transacción
  Future<int> deleteEntriesByTransaction(String transactionId) {
    return (delete(journalEntries)
          ..where((je) => je.transactionId.equals(transactionId)))
        .go();
  }

  /// Obtiene el total de débitos de una cuenta
  Future<double> getTotalDebits(String accountId) async {
    final total = journalEntries.amount.sum();
    final query = selectOnly(journalEntries)
      ..addColumns([total])
      ..where(journalEntries.accountId.equals(accountId))
      ..where(journalEntries.entryType.equals('debit'));
    final result = await query.getSingle();
    return result.read(total) ?? 0.0;
  }

  /// Obtiene el total de créditos de una cuenta
  Future<double> getTotalCredits(String accountId) async {
    final total = journalEntries.amount.sum();
    final query = selectOnly(journalEntries)
      ..addColumns([total])
      ..where(journalEntries.accountId.equals(accountId))
      ..where(journalEntries.entryType.equals('credit'));
    final result = await query.getSingle();
    return result.read(total) ?? 0.0;
  }

  /// Calcula el balance de una cuenta (Débitos - Créditos o Créditos - Débitos según tipo)
  /// Para Activos y Gastos: Débitos - Créditos
  /// Para Pasivos, Ingresos y Patrimonio: Créditos - Débitos
  Future<double> getAccountBalance(String accountId) async {
    final debits = await getTotalDebits(accountId);
    final credits = await getTotalCredits(accountId);
    return debits - credits;
  }

  /// Obtiene débitos de una cuenta en un período
  Future<double> getDebitsInPeriod(
    String accountId,
    DateTime start,
    DateTime end,
  ) async {
    final total = journalEntries.amount.sum();
    final query = selectOnly(journalEntries)
      ..addColumns([total])
      ..where(journalEntries.accountId.equals(accountId))
      ..where(journalEntries.entryType.equals('debit'))
      ..where(journalEntries.entryDate.isBiggerOrEqualValue(start))
      ..where(journalEntries.entryDate.isSmallerOrEqualValue(end));
    final result = await query.getSingle();
    return result.read(total) ?? 0.0;
  }

  /// Obtiene créditos de una cuenta en un período
  Future<double> getCreditsInPeriod(
    String accountId,
    DateTime start,
    DateTime end,
  ) async {
    final total = journalEntries.amount.sum();
    final query = selectOnly(journalEntries)
      ..addColumns([total])
      ..where(journalEntries.accountId.equals(accountId))
      ..where(journalEntries.entryType.equals('credit'))
      ..where(journalEntries.entryDate.isBiggerOrEqualValue(start))
      ..where(journalEntries.entryDate.isSmallerOrEqualValue(end));
    final result = await query.getSingle();
    return result.read(total) ?? 0.0;
  }

  /// Marca un asiento como reconciliado
  Future<int> markAsReconciled(String id) {
    return (update(journalEntries)..where((je) => je.id.equals(id))).write(
      JournalEntriesCompanion(
        isReconciled: const Value(true),
        reconciledAt: Value(DateTime.now()),
      ),
    );
  }

  /// Verifica que la partida doble esté balanceada
  /// (suma de débitos = suma de créditos para una transacción)
  Future<bool> isTransactionBalanced(String transactionId) async {
    final entries = await getEntriesByTransaction(transactionId);
    double totalDebits = 0;
    double totalCredits = 0;

    for (final entry in entries) {
      if (entry.entryType == 'debit') {
        totalDebits += entry.amount;
      } else {
        totalCredits += entry.amount;
      }
    }

    // Permitir pequeña diferencia por redondeo
    return (totalDebits - totalCredits).abs() < 0.01;
  }

  /// Obtiene el siguiente número de asiento
  Future<int> getNextEntryNumber() async {
    final maxNumber = journalEntries.entryNumber.max();
    final query = selectOnly(journalEntries)..addColumns([maxNumber]);
    final result = await query.getSingle();
    return (result.read(maxNumber) ?? 0) + 1;
  }
}
