import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/local/database.dart';
import '../../data/local/daos/daos.dart';
import '../../data/sync/sync.dart';

part 'database_provider.g.dart';

/// Provider del cliente de Supabase
@Riverpod(keepAlive: true)
SupabaseClient supabaseClient(Ref ref) {
  return Supabase.instance.client;
}

/// Provider del manager de PowerSync
@Riverpod(keepAlive: true)
PowerSyncDatabaseManager powerSyncManager(Ref ref) {
  return PowerSyncDatabaseManager.instance;
}

/// Provider de la base de datos de Drift
/// Usa el archivo SQLite de PowerSync para operaciones locales
@Riverpod(keepAlive: true)
AppDatabase appDatabase(Ref ref) {
  final powerSync = ref.watch(powerSyncManagerProvider);

  if (!powerSync.isInitialized) {
    // Si PowerSync no está inicializado, usar base de datos standalone
    return AppDatabase();
  }

  // Usar el mismo archivo SQLite que PowerSync
  return AppDatabase.forPowerSync(powerSync.dbPath);
}

/// Provider del DAO de categorías
@riverpod
CategoriesDao categoriesDao(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  return CategoriesDao(db);
}

/// Provider del DAO de transacciones
@riverpod
TransactionsDao transactionsDao(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  return TransactionsDao(db);
}

/// Provider del DAO de presupuestos
@riverpod
BudgetsDao budgetsDao(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  return BudgetsDao(db);
}

// ============================================================
// DAOs de Catálogos (Fase 1.5)
// ============================================================

/// Provider del DAO de unidades de medida
@riverpod
MeasurementUnitsDao measurementUnitsDao(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  return MeasurementUnitsDao(db);
}

/// Provider del DAO de lugares
@riverpod
PlacesDao placesDao(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  return PlacesDao(db);
}

/// Provider del DAO de métodos de pago
@riverpod
PaymentMethodsDao paymentMethodsDao(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  return PaymentMethodsDao(db);
}

// ============================================================
// DAOs Transaccionales (Fase 1.5)
// ============================================================

/// Provider del DAO de detalles de transacción (Shopping Cart)
@riverpod
TransactionDetailsDao transactionDetailsDao(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  return TransactionDetailsDao(db);
}

/// Provider del DAO de asientos contables (Partida Doble)
@riverpod
JournalEntriesDao journalEntriesDao(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  return JournalEntriesDao(db);
}

/// Provider del DAO de cuentas
@riverpod
AccountsDao accountsDao(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  return AccountsDao(db);
}
