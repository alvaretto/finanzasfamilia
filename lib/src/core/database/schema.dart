import 'package:powersync/powersync.dart';

/// PowerSync Schema - Offline-First Database
/// Basado en .claude/docs/schema_plan.md

const schema = Schema([
  Table('accounts', [
    Column.text('user_id'),
    Column.text('name'),
    Column.text('type'),           // cash, bank, digital_wallet, investment
    Column.text('subtype'),        // savings, checking, cdt, etc.
    Column.real('balance'),
    Column.text('currency'),
    Column.text('icon'),
    Column.text('color'),
    Column.integer('is_active'),
    Column.integer('sort_order'),
    Column.text('created_at'),
    Column.text('updated_at'),
  ]),

  Table('liabilities', [
    Column.text('user_id'),
    Column.text('name'),
    Column.text('type'),           // credit_card, loan, payable
    Column.text('subtype'),        // mortgage, vehicle, personal, tax
    Column.real('balance'),
    Column.real('credit_limit'),
    Column.real('interest_rate'),
    Column.integer('due_day'),
    Column.text('currency'),
    Column.integer('is_active'),
    Column.text('created_at'),
    Column.text('updated_at'),
  ]),

  Table('categories', [
    Column.text('user_id'),
    Column.text('parent_id'),
    Column.text('name'),
    Column.text('type'),           // income, expense
    Column.text('icon'),
    Column.text('color'),
    Column.integer('is_system'),
    Column.integer('sort_order'),
    Column.text('created_at'),
  ]),

  Table('transactions', [
    Column.text('user_id'),
    Column.text('account_id'),
    Column.text('liability_id'),
    Column.text('category_id'),
    Column.text('type'),           // income, expense, transfer
    Column.real('amount'),
    Column.text('description'),
    Column.text('date'),
    Column.text('time'),
    Column.integer('is_recurring'),
    Column.text('recurring_id'),
    Column.text('tags'),           // JSON array as text
    Column.text('attachments'),    // JSON array as text
    Column.text('created_at'),
    Column.text('updated_at'),
  ]),

  Table('recurring_transactions', [
    Column.text('user_id'),
    Column.text('account_id'),
    Column.text('category_id'),
    Column.text('type'),
    Column.real('amount'),
    Column.text('description'),
    Column.text('frequency'),      // daily, weekly, monthly, yearly
    Column.integer('interval_count'),
    Column.text('start_date'),
    Column.text('end_date'),
    Column.text('next_date'),
    Column.integer('is_active'),
    Column.text('created_at'),
  ]),

  Table('budgets', [
    Column.text('user_id'),
    Column.text('category_id'),
    Column.real('amount'),
    Column.text('period'),         // monthly, yearly
    Column.text('start_date'),
    Column.text('end_date'),
    Column.real('alert_threshold'),
    Column.text('created_at'),
  ]),
]);
