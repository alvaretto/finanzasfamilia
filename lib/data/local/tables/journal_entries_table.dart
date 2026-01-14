import 'package:drift/drift.dart';

import 'transactions_table.dart';
import 'accounts_table.dart';
import 'categories_table.dart';

/// Tipo de asiento contable
enum JournalEntryType {
  /// Débito - Lo que ENTRA o AUMENTA
  debit,

  /// Crédito - Lo que SALE o DISMINUYE
  credit,
}

/// Tabla de Asientos Contables (Journal Entries)
/// Implementa la Partida Doble automáticamente
///
/// Regla de Oro:
/// - DÉBITO (Dr) = Lo que ENTRA o AUMENTA en la cuenta destino
/// - CRÉDITO (Cr) = Lo que SALE o DISMINUYE de la cuenta origen
///
/// Ejemplos:
/// | Acción | Débito | Crédito |
/// |--------|--------|---------|
/// | Compra con Nequi | Gastos:Alimentación | Activos:Bancos:Nequi |
/// | Recibe Salario | Activos:Bancolombia | Ingresos:Salario |
/// | Paga TC | Pasivos:TC:Visa | Activos:Bancos:Ahorros |
///
/// NOTA: Un asiento puede apuntar a una Account (activo/pasivo) O a una
/// Category (ingreso/gasto). Solo uno de los dos debe estar presente.
@DataClassName('JournalEntryRecord')
class JournalEntries extends Table {
  /// ID único (UUID)
  TextColumn get id => text()();

  /// ID del usuario propietario (para sincronización con PowerSync)
  TextColumn get userId => text().nullable()();

  /// ID de la transacción relacionada
  TextColumn get transactionId => text().references(Transactions, #id)();

  /// ID del detalle de transacción (si aplica)
  TextColumn get transactionDetailId => text().nullable()();

  /// ID de la cuenta afectada (para activos/pasivos)
  /// Usar cuando el asiento afecta una cuenta de balance
  TextColumn get accountId => text().nullable().references(Accounts, #id)();

  /// ID de la categoría afectada (para ingresos/gastos)
  /// Usar cuando el asiento afecta una cuenta de resultados
  TextColumn get categoryId => text().nullable().references(Categories, #id)();

  /// Tipo de asiento (debit/credit)
  TextColumn get entryType => text()();

  /// Monto del asiento (siempre positivo)
  RealColumn get amount => real()();

  /// Descripción del asiento
  TextColumn get description => text().nullable()();

  /// Número de asiento (para auditoría)
  IntColumn get entryNumber => integer().nullable()();

  /// Fecha del asiento
  DateTimeColumn get entryDate => dateTime()();

  /// Si ha sido reconciliado - Nullable para compatibilidad con PowerSync
  BoolColumn get isReconciled => boolean().nullable()();

  /// Fecha de reconciliación
  DateTimeColumn get reconciledAt => dateTime().nullable()();

  /// Orden global de sincronización (estilo Linear)
  IntColumn get syncSequence => integer().nullable()();

  /// Timestamps
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
