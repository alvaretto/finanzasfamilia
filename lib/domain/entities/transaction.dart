import 'package:freezed_annotation/freezed_annotation.dart';

part 'transaction.freezed.dart';
part 'transaction.g.dart';

/// Tipo de transacción
enum TransactionType {
  /// Ingreso - "Lo que Entra"
  income,

  /// Gasto - "Lo que Sale"
  expense,

  /// Transferencia entre cuentas
  transfer,
}

/// Entidad de Transacción inmutable
/// Representa un movimiento financiero
@freezed
class Transaction with _$Transaction {
  const Transaction._();

  const factory Transaction({
    required String id,
    required String accountId,
    required String categoryId,
    required TransactionType type,
    required double amount,
    required DateTime date,
    String? description,
    String? notes,
    String? transferToAccountId,
    @Default(false) bool isRecurring,
    String? recurringId,
    @Default(false) bool isPending,
    /// Nivel de satisfacción del gasto (solo para type=expense)
    /// Valores: 'low', 'medium', 'high', 'neutral'
    String? satisfactionLevel,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Transaction;

  factory Transaction.fromJson(Map<String, dynamic> json) =>
      _$TransactionFromJson(json);

  /// Verifica si es un ingreso
  bool get isIncome => type == TransactionType.income;

  /// Verifica si es un gasto
  bool get isExpense => type == TransactionType.expense;

  /// Verifica si es una transferencia
  bool get isTransfer => type == TransactionType.transfer;

  /// Monto con signo (negativo para gastos)
  double get signedAmount {
    switch (type) {
      case TransactionType.income:
        return amount;
      case TransactionType.expense:
        return -amount;
      case TransactionType.transfer:
        return 0; // Las transferencias son neutrales
    }
  }

  /// Nombre del tipo en español
  String get typeName {
    switch (type) {
      case TransactionType.income:
        return 'Ingreso';
      case TransactionType.expense:
        return 'Gasto';
      case TransactionType.transfer:
        return 'Transferencia';
    }
  }

  /// Nombre del nivel de satisfacción en español (solo para gastos)
  String? get satisfactionName {
    switch (satisfactionLevel) {
      case 'low':
        return 'Baja';
      case 'medium':
        return 'Media';
      case 'high':
        return 'Alta';
      case 'neutral':
        return 'Neutra';
      default:
        return null;
    }
  }
}
