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
/// Se debe hacer override desde main.dart con la instancia inicializada
@Riverpod(keepAlive: true)
AppDatabase appDatabase(Ref ref) {
  // Este provider debe ser overrideado desde main.dart
  // Si no se hace override, usar base de datos standalone (fallback)
  return AppDatabase();
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
