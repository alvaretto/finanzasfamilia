import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';

import 'tables/tables.dart';

part 'database.g.dart';

/// Base de datos local usando Drift
/// Diseñada para trabajar con PowerSync en modo Offline-First
///
/// Tablas incluidas:
/// - Categories: Taxonomía financiera jerárquica
/// - Accounts: Cuentas financieras
/// - Transactions: Encabezado de transacciones
/// - TransactionDetails: Detalle de transacciones (Shopping Cart)
/// - JournalEntries: Asientos contables (Partida Doble)
/// - Budgets: Presupuestos mensuales
/// - MeasurementUnits: Unidades de medida
/// - Places: Lugares de compra/venta
/// - PaymentMethods: Métodos de pago
/// - RecurringTransactions: Transacciones recurrentes (servicios, suscripciones)
/// - SavingsGoals: Metas de ahorro
/// - SavingsContributions: Contribuciones a metas de ahorro
/// - TransactionAttachments: Adjuntos de transacciones (recibos, facturas)
@DriftDatabase(tables: [
  Categories,
  Accounts,
  Transactions,
  TransactionDetails,
  JournalEntries,
  Budgets,
  MeasurementUnits,
  Places,
  PaymentMethods,
  RecurringTransactions,
  SavingsGoals,
  SavingsContributions,
  TransactionAttachments,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// Constructor para usar con PowerSync (recibe el path del archivo SQLite)
  AppDatabase.forPowerSync(String dbPath)
      : super(NativeDatabase(File(dbPath)));

  /// Constructor para tests con base de datos en memoria
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 5; // v5: TransactionAttachments

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        // Migración de v1 a v2: Agregar nuevas tablas
        if (from < 2) {
          await m.createTable(measurementUnits);
          await m.createTable(places);
          await m.createTable(paymentMethods);
          await m.createTable(transactionDetails);
          await m.createTable(journalEntries);

          // Agregar nuevos campos a transactions
          await m.addColumn(transactions, transactions.placeId);
          await m.addColumn(transactions, transactions.hasDetails);
          await m.addColumn(transactions, transactions.itemCount);
        }
        // Migración de v2 a v3: Agregar RecurringTransactions
        if (from < 3) {
          await m.createTable(recurringTransactions);
        }
        // Migración de v3 a v4: Agregar SavingsGoals y SavingsContributions
        if (from < 4) {
          await m.createTable(savingsGoals);
          await m.createTable(savingsContributions);
        }
        // Migración de v4 a v5: Agregar TransactionAttachments
        if (from < 5) {
          await m.createTable(transactionAttachments);
        }
      },
      beforeOpen: (details) async {
        // Habilitar foreign keys
        await customStatement('PRAGMA foreign_keys = ON');
      },
    );
  }
}

/// Abre la conexión a la base de datos SQLite
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'finanzas_familiares.db'));
    return NativeDatabase.createInBackground(file);
  });
}
