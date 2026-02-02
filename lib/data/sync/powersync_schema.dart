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
/// Nota: user_id se incluye para sincronización con Supabase RLS
///
/// SYNC SEQUENCE (Estilo Linear):
/// - sync_sequence es un BIGINT incremental global
/// - Garantiza orden total de operaciones
/// - Los padres siempre tienen sync_sequence menor que sus hijos
/// - Permite sincronización ordenada en reinstalación de app
///
/// Schema de PowerSync - la columna 'id' es agregada automáticamente por PowerSync
const schema = Schema([
  // =========================================================================
  // CATEGORÍAS - Taxonomía jerárquica (asset, liability, income, expense)
  // =========================================================================
  Table('categories', [
    // 'id' es automático en PowerSync - NO declarar
    Column.text('user_id'), // Para RLS en Supabase
    Column.text('name'),
    Column.text('icon'),
    Column.text('type'), // asset, liability, income, expense
    Column.text('parent_id'),
    Column.integer('level'),
    Column.integer('sort_order'),
    Column.integer('is_active'),
    Column.integer('is_system'),
    Column.integer('sync_sequence'), // Orden global de operaciones
    Column.text('created_at'),
    Column.text('updated_at'),
  ]),

  // =========================================================================
  // CUENTAS - Billeteras y cuentas del usuario (Nequi, DaviPlata, etc.)
  // =========================================================================
  Table('accounts', [
    Column.text('user_id'), // Para RLS en Supabase
    Column.text('name'),
    Column.text('type'), // wallet, bank, credit_card, etc. (nullable, default: wallet)
    Column.text('icon'),
    Column.text('category_id'),
    Column.real('balance'),
    Column.text('currency'), // Default: COP
    Column.text('color'),
    Column.text('description'),
    Column.integer('include_in_total'),
    Column.integer('is_active'),
    Column.integer('is_system'),
    Column.integer('sync_sequence'), // Orden global de operaciones
    Column.text('created_at'),
    Column.text('updated_at'),
  ]),

  // =========================================================================
  // LUGARES - Donde se realizan las transacciones
  // =========================================================================
  Table('places', [
    Column.text('user_id'), // Para RLS en Supabase
    Column.text('name'),
    Column.text('type'), // supermarket, store, street, web, etc.
    Column.text('address'),
    Column.text('city'),
    Column.real('latitude'),
    Column.real('longitude'),
    Column.text('notes'),
    Column.integer('is_active'),
    Column.integer('is_system'),
    Column.integer('usage_count'),
    Column.integer('sync_sequence'), // Orden global de operaciones
    Column.text('created_at'),
    Column.text('updated_at'),
  ]),

  // =========================================================================
  // MÉTODOS DE PAGO - Vinculados a cuentas
  // =========================================================================
  Table('payment_methods', [
    Column.text('user_id'), // Para RLS en Supabase
    Column.text('name'),
    Column.text('account_id'),
    Column.text('icon'),
    Column.text('color'),
    Column.integer('is_default'),
    Column.integer('is_active'),
    Column.integer('sort_order'),
    Column.integer('sync_sequence'), // Orden global de operaciones
    Column.text('created_at'),
    Column.text('updated_at'),
  ]),

  // =========================================================================
  // UNIDADES DE MEDIDA (weight, volume, unit, package)
  // =========================================================================
  Table('measurement_units', [
    Column.text('user_id'), // Para RLS en Supabase
    Column.text('name'),
    Column.text('abbreviation'),
    Column.text('type'), // weight, volume, unit, package
    Column.real('conversion_factor'),
    Column.text('base_unit_id'),
    Column.integer('is_system'),
    Column.integer('is_active'),
    Column.integer('sort_order'),
    Column.integer('sync_sequence'), // Orden global de operaciones
    Column.text('created_at'),
    Column.text('updated_at'),
  ]),

  // =========================================================================
  // TRANSACCIONES - Header de movimientos (income, expense, transfer)
  // =========================================================================
  Table('transactions', [
    Column.text('user_id'), // Para RLS en Supabase
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
    Column.integer('sync_sequence'), // Orden global de operaciones
    Column.text('satisfaction_level'), // low, medium, high, neutral (solo gastos)
    Column.text('created_at'),
    Column.text('updated_at'),
  ]),

  // =========================================================================
  // DETALLES DE TRANSACCIÓN - Shopping Cart / Líneas de compra
  // =========================================================================
  Table('transaction_details', [
    Column.text('user_id'), // Para RLS en Supabase
    Column.text('transaction_id'),
    Column.text('concept'),
    Column.text('category_id'),
    Column.real('unit_value'),
    Column.real('quantity'),
    Column.text('measurement_unit_id'),
    Column.real('total_value'),
    Column.text('payment_method_id'),
    Column.text('mode'), // cash, credit
    Column.text('accrual_date'),
    Column.real('discount'),
    Column.text('notes'),
    Column.integer('sort_order'),
    Column.integer('sync_sequence'), // Orden global de operaciones
    Column.text('created_at'),
    Column.text('updated_at'),
  ]),

  // =========================================================================
  // PRESUPUESTOS - Límites mensuales por categoría (Semáforo)
  // =========================================================================
  Table('budgets', [
    Column.text('user_id'), // Para RLS en Supabase
    Column.text('category_id'),
    Column.real('amount'),
    Column.integer('month'), // 1-12
    Column.integer('year'), // 2020-2100
    Column.integer('is_active'),
    Column.integer('sync_sequence'), // Orden global de operaciones
    Column.text('created_at'),
    Column.text('updated_at'),
  ]),

  // =========================================================================
  // ASIENTOS CONTABLES - Partida Doble (debit, credit)
  // =========================================================================
  Table('journal_entries', [
    Column.text('user_id'), // Para RLS en Supabase
    Column.text('transaction_id'),
    Column.text('transaction_detail_id'),
    Column.text('account_id'),
    Column.text('category_id'),
    Column.text('entry_type'), // debit, credit
    Column.real('amount'),
    Column.text('description'),
    Column.integer('entry_number'),
    Column.text('entry_date'),
    Column.integer('is_reconciled'),
    Column.text('reconciled_at'),
    Column.integer('sync_sequence'), // Orden global de operaciones
    Column.text('created_at'),
    Column.text('updated_at'),
  ]),

  // =========================================================================
  // METAS DE AHORRO
  // =========================================================================
  Table('savings_goals', [
    Column.text('user_id'), // Para RLS en Supabase
    Column.text('name'),
    Column.text('description'),
    Column.real('target_amount'),
    Column.real('current_amount'),
    Column.text('target_date'),
    Column.text('account_id'),
    Column.integer('color'),
    Column.integer('icon'),
    Column.integer('is_active'),
    Column.integer('is_completed'),
    Column.text('completed_at'),
    Column.integer('sync_sequence'), // Orden global de operaciones
    Column.text('created_at'),
    Column.text('updated_at'),
  ]),

  // =========================================================================
  // CONTRIBUCIONES A METAS DE AHORRO
  // =========================================================================
  Table('savings_contributions', [
    Column.text('user_id'), // Para RLS en Supabase
    Column.text('goal_id'),
    Column.real('amount'),
    Column.text('note'),
    Column.text('date'),
    Column.integer('sync_sequence'), // Orden global de operaciones
    Column.text('created_at'),
  ]),

  // =========================================================================
  // ADJUNTOS DE TRANSACCIONES
  // =========================================================================
  Table('transaction_attachments', [
    Column.text('user_id'), // Para RLS en Supabase
    Column.text('transaction_id'),
    Column.text('file_name'),
    Column.text('mime_type'),
    Column.text('local_path'),
    Column.text('remote_url'),
    Column.integer('file_size'),
    Column.text('ocr_text'),
    Column.real('ocr_amount'),
    Column.integer('is_synced'),
    Column.integer('sync_sequence'), // Orden global de operaciones
    Column.text('created_at'),
  ]),

  // =========================================================================
  // TRANSACCIONES RECURRENTES
  // =========================================================================
  Table('recurring_transactions', [
    Column.text('user_id'), // Para RLS en Supabase
    Column.text('name'),
    Column.text('type'), // income, expense
    Column.real('amount'),
    Column.text('description'),
    Column.text('from_account_id'),
    Column.text('to_account_id'),
    Column.text('category_id'),
    Column.text('frequency'), // daily, weekly, biweekly, monthly, etc.
    Column.integer('day_of_execution'),
    Column.text('start_date'),
    Column.text('end_date'),
    Column.text('last_executed_at'),
    Column.text('next_execution_date'),
    Column.integer('is_active'),
    Column.integer('requires_confirmation'),
    Column.integer('execution_count'),
    Column.integer('sync_sequence'), // Orden global de operaciones
    Column.text('created_at'),
    Column.text('updated_at'),
  ]),

  // =========================================================================
  // FAMILIAS - Grupos que comparten finanzas
  // =========================================================================
  Table('families', [
    Column.text('user_id'), // Para RLS en Supabase
    Column.text('name'),
    Column.text('description'),
    Column.text('icon'),
    Column.text('color'),
    Column.text('owner_id'),
    Column.text('invite_code'),
    Column.integer('is_active'),
    Column.integer('sync_sequence'), // Orden global de operaciones
    Column.text('created_at'),
    Column.text('updated_at'),
  ]),

  // =========================================================================
  // MIEMBROS DE FAMILIA - Usuarios en familias con roles
  // =========================================================================
  Table('family_members', [
    Column.text('sync_user_id'), // Para RLS en Supabase (diferente de user_id que es el ID del miembro)
    Column.text('family_id'),
    Column.text('user_id'), // ID del miembro
    Column.text('user_email'),
    Column.text('display_name'),
    Column.text('avatar_url'),
    Column.text('role'), // owner, admin, member, viewer
    Column.integer('is_active'),
    Column.text('joined_at'),
    Column.integer('sync_sequence'), // Orden global de operaciones
    Column.text('created_at'),
    Column.text('updated_at'),
  ]),

  // =========================================================================
  // INVITACIONES FAMILIARES - Invitaciones pendientes
  // =========================================================================
  Table('family_invitations', [
    Column.text('user_id'), // Para RLS en Supabase
    Column.text('family_id'),
    Column.text('invited_email'),
    Column.text('invited_by_user_id'),
    Column.text('role'), // admin, member, viewer
    Column.text('status'), // pending, accepted, rejected, expired, cancelled
    Column.text('token'),
    Column.text('expires_at'),
    Column.text('message'),
    Column.text('created_at'),
    Column.text('updated_at'),
  ]),

  // =========================================================================
  // CUENTAS COMPARTIDAS - Cuentas disponibles para familia
  // =========================================================================
  Table('shared_accounts', [
    Column.text('user_id'), // Para RLS en Supabase
    Column.text('family_id'),
    Column.text('account_id'),
    Column.text('owner_user_id'),
    Column.integer('visible_to_all'),
    Column.integer('members_can_transact'),
    Column.text('created_at'),
  ]),

  // =========================================================================
  // CONFIGURACIÓN DE USUARIO - Persistencia de preferencias
  // =========================================================================
  Table('user_settings', [
    Column.text('user_id'), // Para RLS en Supabase
    Column.text('theme_mode'), // light, dark, system
    Column.integer('onboarding_completed'), // 0, 1
    Column.integer('notifications_enabled'), // 0, 1
    Column.integer('budget_alerts_enabled'), // 0, 1
    Column.integer('recurring_reminders_enabled'), // 0, 1
    Column.integer('daily_reminder_enabled'), // 0, 1
    Column.integer('daily_reminder_hour'), // 0-23
    Column.text('currency'), // COP, USD (default COP)
    Column.text('date_format'), // default dd/MM/yyyy
    Column.text('created_at'),
    Column.text('updated_at'),
  ]),
]);
