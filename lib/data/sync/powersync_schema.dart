import 'package:powersync/powersync.dart';

/// Schema de PowerSync que mapea las tablas de Supabase
/// para sincronización bidireccional Offline-First
///
/// IMPORTANTE: Este schema debe coincidir exactamente con:
/// - supabase/migrations/001_initial_schema.sql
/// - supabase/powersync/sync_rules.yaml
///
/// Nota: Los campos boolean de SQLite se mapean como integer (0/1)
/// Nota: Los campos DateTime se mapean como text (ISO 8601)
/// Nota: user_id NO se incluye aquí porque PowerSync lo maneja automáticamente
const schema = Schema([
  // =========================================================================
  // CATEGORÍAS - Taxonomía jerárquica (asset, liability, income, expense)
  // =========================================================================
  Table('categories', [
    Column.text('id'),
    Column.text('name'),
    Column.text('icon'),
    Column.text('type'), // asset, liability, income, expense
    Column.text('parent_id'),
    Column.integer('level'),
    Column.integer('sort_order'),
    Column.integer('is_active'),
    Column.integer('is_system'),
    Column.text('created_at'),
    Column.text('updated_at'),
  ]),

  // =========================================================================
  // CUENTAS - Billeteras y cuentas del usuario (Nequi, DaviPlata, etc.)
  // =========================================================================
  Table('accounts', [
    Column.text('id'),
    Column.text('name'),
    Column.text('icon'),
    Column.text('category_id'),
    Column.real('balance'),
    Column.text('currency'), // Default: COP
    Column.text('color'),
    Column.text('description'),
    Column.integer('include_in_total'),
    Column.integer('is_active'),
    Column.text('created_at'),
    Column.text('updated_at'),
  ]),

  // =========================================================================
  // LUGARES - Donde se realizan las transacciones
  // =========================================================================
  Table('places', [
    Column.text('id'),
    Column.text('name'),
    Column.text('icon'),
    Column.text('address'),
    Column.real('latitude'),
    Column.real('longitude'),
    Column.integer('is_favorite'),
    Column.integer('visit_count'),
    Column.text('last_visited_at'),
    Column.integer('is_active'),
    Column.text('created_at'),
    Column.text('updated_at'),
  ]),

  // =========================================================================
  // MÉTODOS DE PAGO (cash, debit, credit, transfer, digital_wallet, other)
  // =========================================================================
  Table('payment_methods', [
    Column.text('id'),
    Column.text('name'),
    Column.text('icon'),
    Column.text('type'), // cash, debit, credit, transfer, digital_wallet, other
    Column.text('account_id'),
    Column.integer('is_default'),
    Column.integer('is_active'),
    Column.text('created_at'),
    Column.text('updated_at'),
  ]),

  // =========================================================================
  // UNIDADES DE MEDIDA (weight, volume, length, unit, other)
  // =========================================================================
  Table('measurement_units', [
    Column.text('id'),
    Column.text('name'),
    Column.text('abbreviation'),
    Column.text('type'), // weight, volume, length, unit, other
    Column.real('conversion_factor'),
    Column.text('base_unit_id'),
    Column.integer('is_system'),
    Column.integer('is_active'),
    Column.text('created_at'),
    Column.text('updated_at'),
  ]),

  // =========================================================================
  // TRANSACCIONES - Header de movimientos (income, expense, transfer)
  // =========================================================================
  Table('transactions', [
    Column.text('id'),
    Column.text('type'), // income, expense, transfer
    Column.real('amount'),
    Column.text('description'),
    Column.text('from_account_id'),
    Column.text('to_account_id'),
    Column.text('category_id'),
    Column.text('place_id'),
    Column.text('transaction_date'),
    Column.integer('is_confirmed'),
    Column.integer('has_details'),
    Column.integer('item_count'),
    Column.text('sync_status'), // pending, synced, error
    Column.text('created_at'),
    Column.text('updated_at'),
  ]),

  // =========================================================================
  // DETALLES DE TRANSACCIÓN - Shopping Cart / Líneas de compra
  // =========================================================================
  Table('transaction_details', [
    Column.text('id'),
    Column.text('transaction_id'),
    Column.text('category_id'),
    Column.text('description'),
    Column.real('quantity'),
    Column.text('unit_id'), // Referencia a measurement_units
    Column.real('unit_price'),
    Column.real('total_price'),
    Column.integer('sort_order'),
    Column.text('created_at'),
    Column.text('updated_at'),
  ]),

  // =========================================================================
  // PRESUPUESTOS - Límites mensuales por categoría (Semáforo)
  // =========================================================================
  Table('budgets', [
    Column.text('id'),
    Column.text('category_id'),
    Column.real('amount'),
    Column.integer('month'), // 1-12
    Column.integer('year'), // 2020-2100
    Column.integer('is_active'),
    Column.text('created_at'),
    Column.text('updated_at'),
  ]),

  // =========================================================================
  // ASIENTOS CONTABLES - Partida Doble (debit, credit)
  // =========================================================================
  Table('journal_entries', [
    Column.text('id'),
    Column.text('transaction_id'),
    Column.text('account_id'),
    Column.text('entry_type'), // debit, credit
    Column.real('amount'),
    Column.text('description'),
    Column.text('created_at'),
  ]),
]);
