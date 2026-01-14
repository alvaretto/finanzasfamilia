import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../sync/powersync_database.dart' show kSharedDatabaseFileName;
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
/// - Families: Grupos familiares
/// - FamilyMembers: Miembros de familia con roles
/// - FamilyInvitations: Invitaciones pendientes
/// - SharedAccounts: Cuentas compartidas en familia
/// - UserSettings: Configuración de usuario sincronizada
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
  Families,
  FamilyMembers,
  FamilyInvitations,
  SharedAccounts,
  UserSettings,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// Constructor para usar con PowerSync (recibe el path del archivo SQLite)
  AppDatabase.forPowerSync(String dbPath)
      : super(NativeDatabase(File(dbPath)));

  /// Constructor para tests con base de datos en memoria
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 13; // v13: Agregar sync_sequence para orden global (estilo Linear)

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
        // Migración de v5 a v6: Agregar tablas de Modo Familiar
        if (from < 6) {
          await m.createTable(families);
          await m.createTable(familyMembers);
          await m.createTable(familyInvitations);
          await m.createTable(sharedAccounts);
        }
        // Migración de v6 a v7: Agregar isSystem a accounts
        if (from < 7) {
          await m.addColumn(accounts, accounts.isSystem);
          // Marcar cuentas existentes como del sistema
          await customStatement(
            "UPDATE accounts SET is_system = 1 WHERE name IN ('Billetera Personal', 'Caja Menor Casa', 'Alcancía', 'Davivienda', 'Bancolombia', 'DaviPlata', 'Nequi', 'DollarApp', 'PayPal', 'CDT / Fiducias', 'Propiedades')",
          );
        }
        // Migración de v7 a v8: Agregar user_id a todas las tablas para PowerSync sync
        if (from < 8) {
          await m.addColumn(accounts, accounts.userId);
          await m.addColumn(transactions, transactions.userId);
          await m.addColumn(categories, categories.userId);
          await m.addColumn(budgets, budgets.userId);
          await m.addColumn(journalEntries, journalEntries.userId);
          await m.addColumn(places, places.userId);
          await m.addColumn(paymentMethods, paymentMethods.userId);
          await m.addColumn(measurementUnits, measurementUnits.userId);
          await m.addColumn(transactionDetails, transactionDetails.userId);
          await m.addColumn(recurringTransactions, recurringTransactions.userId);
          await m.addColumn(savingsGoals, savingsGoals.userId);
          await m.addColumn(savingsContributions, savingsContributions.userId);
          await m.addColumn(transactionAttachments, transactionAttachments.userId);
        }
        // Migración de v8 a v9: Agregar user_id a tablas de familia para PowerSync sync
        if (from < 9) {
          await m.addColumn(families, families.userId);
          await m.addColumn(familyMembers, familyMembers.syncUserId);
          await m.addColumn(familyInvitations, familyInvitations.userId);
          await m.addColumn(sharedAccounts, sharedAccounts.userId);
        }
        // Migración de v9 a v10: Aumentar longitud de icon a 50 caracteres
        // SQLite TEXT no tiene límite rígido, este cambio solo afecta validación client-side
        if (from < 10) {
          // No se requiere ALTER TABLE, solo actualizar constraint de validación
        }
        // Migración de v10 a v11: Agregar tabla user_settings
        if (from < 11) {
          await m.createTable(userSettings);
        }
        // Migración de v11 a v12: Agregar accounts.type para Supabase sync
        if (from < 12) {
          await m.addColumn(accounts, accounts.type);
          // Establecer default 'wallet' para cuentas existentes
          await customStatement(
            "UPDATE accounts SET type = 'wallet' WHERE type IS NULL",
          );
        }
        // Migración de v12 a v13: Agregar sync_sequence a todas las tablas (estilo Linear)
        // sync_sequence es un INTEGER que garantiza orden global de operaciones
        // Padres siempre tienen sync_sequence menor que hijos
        if (from < 13) {
          await m.addColumn(categories, categories.syncSequence);
          await m.addColumn(accounts, accounts.syncSequence);
          await m.addColumn(transactions, transactions.syncSequence);
          await m.addColumn(transactionDetails, transactionDetails.syncSequence);
          await m.addColumn(journalEntries, journalEntries.syncSequence);
          await m.addColumn(budgets, budgets.syncSequence);
          await m.addColumn(places, places.syncSequence);
          await m.addColumn(paymentMethods, paymentMethods.syncSequence);
          await m.addColumn(measurementUnits, measurementUnits.syncSequence);
          await m.addColumn(savingsGoals, savingsGoals.syncSequence);
          await m.addColumn(savingsContributions, savingsContributions.syncSequence);
          await m.addColumn(recurringTransactions, recurringTransactions.syncSequence);
          await m.addColumn(transactionAttachments, transactionAttachments.syncSequence);
          await m.addColumn(families, families.syncSequence);
          await m.addColumn(familyMembers, familyMembers.syncSequence);
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
/// IMPORTANTE: Usa kSharedDatabaseFileName para compartir el archivo con PowerSync
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    // Usar el mismo archivo que PowerSync para que la sincronización funcione
    final file = File(p.join(dbFolder.path, kSharedDatabaseFileName));
    return NativeDatabase.createInBackground(file);
  });
}
