/// Entidades del dominio para Dashboard
library;

export 'budget_alert.dart';
export 'category_expense.dart';
export 'dashboard_summary.dart';
export 'expense_group.dart';
// IndicatorStatus se exporta desde financial_indicators_provider.dart
// para compatibilidad con código existente
export 'month_summary.dart';

// DTOs livianos para cálculos (sin dependencias de Drift)
export 'account_balance_dto.dart';
export 'budget_info_dto.dart';
export 'category_info_dto.dart';
export 'transaction_summary_dto.dart';
