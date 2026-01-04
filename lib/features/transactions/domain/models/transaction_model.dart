import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:uuid/uuid.dart';

part 'transaction_model.freezed.dart';
part 'transaction_model.g.dart';

const _uuid = Uuid();

/// Tipos de transaccion
enum TransactionType {
  income,
  expense,
  transfer,
}

/// Metodos de pago disponibles
enum PaymentMethod {
  cash,
  debitCard,
  creditCard,
  bankTransfer,
  digitalWallet,
  check,
  other,
}

extension PaymentMethodExtension on PaymentMethod {
  String get displayName {
    switch (this) {
      case PaymentMethod.cash:
        return 'Efectivo';
      case PaymentMethod.debitCard:
        return 'Tarjeta de Debito';
      case PaymentMethod.creditCard:
        return 'Tarjeta de Credito';
      case PaymentMethod.bankTransfer:
        return 'Transferencia Bancaria';
      case PaymentMethod.digitalWallet:
        return 'Billetera Digital';
      case PaymentMethod.check:
        return 'Cheque';
      case PaymentMethod.other:
        return 'Otro';
    }
  }

  String get icon {
    switch (this) {
      case PaymentMethod.cash:
        return 'payments';
      case PaymentMethod.debitCard:
        return 'credit_card';
      case PaymentMethod.creditCard:
        return 'credit_score';
      case PaymentMethod.bankTransfer:
        return 'account_balance';
      case PaymentMethod.digitalWallet:
        return 'account_balance_wallet';
      case PaymentMethod.check:
        return 'receipt';
      case PaymentMethod.other:
        return 'more_horiz';
    }
  }
}

extension TransactionTypeExtension on TransactionType {
  String get displayName {
    switch (this) {
      case TransactionType.income:
        return 'Ingreso';
      case TransactionType.expense:
        return 'Gasto';
      case TransactionType.transfer:
        return 'Transferencia';
    }
  }

  String get icon {
    switch (this) {
      case TransactionType.income:
        return 'arrow_downward';
      case TransactionType.expense:
        return 'arrow_upward';
      case TransactionType.transfer:
        return 'swap_horiz';
    }
  }
}

/// Modelo de transaccion
@freezed
class TransactionModel with _$TransactionModel {
  const TransactionModel._();

  const factory TransactionModel({
    required String id,
    required String userId,
    required String accountId,
    int? categoryId,
    required double amount,
    required TransactionType type,
    @Default(PaymentMethod.cash) PaymentMethod paymentMethod,
    String? description,
    required DateTime date,
    String? notes,
    @Default([]) List<String> tags,
    String? transferToAccountId,
    String? recurringId,
    @Default(false) bool isSynced,
    DateTime? createdAt,
    DateTime? updatedAt,
    // Campos para UI (no persistidos)
    String? accountName,
    String? categoryName,
    String? categoryIcon,
    String? categoryColor,
    String? transferToAccountName,
  }) = _TransactionModel;

  factory TransactionModel.fromJson(Map<String, dynamic> json) =>
      _$TransactionModelFromJson(json);

  /// Crear nueva transaccion
  factory TransactionModel.create({
    required String userId,
    required String accountId,
    required double amount,
    required TransactionType type,
    PaymentMethod paymentMethod = PaymentMethod.cash,
    int? categoryId,
    String? description,
    DateTime? date,
    String? notes,
    List<String>? tags,
    String? transferToAccountId,
    String? recurringId,
  }) {
    return TransactionModel(
      id: _uuid.v4(),
      userId: userId,
      accountId: accountId,
      categoryId: categoryId,
      amount: amount.abs(),
      type: type,
      paymentMethod: paymentMethod,
      description: description,
      date: date ?? DateTime.now(),
      notes: notes,
      tags: tags ?? [],
      transferToAccountId: transferToAccountId,
      recurringId: recurringId,
      isSynced: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Amount con signo (negativo para gastos)
  double get signedAmount {
    switch (type) {
      case TransactionType.income:
        return amount;
      case TransactionType.expense:
        return -amount;
      case TransactionType.transfer:
        return -amount; // Salida de la cuenta origen
    }
  }

  /// Es transferencia
  bool get isTransfer => type == TransactionType.transfer;

  /// Validaciones de la transaccion
  /// Retorna lista de errores (vacía si es válida)
  List<String> get validationErrors {
    final errors = <String>[];

    // Validación 1: Monto debe ser > 0
    if (amount <= 0) {
      errors.add('El monto debe ser mayor a cero');
    }

    // Validación 2: Fecha no puede ser futura (con margen de 1 día)
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    if (date.isAfter(tomorrow)) {
      errors.add('La fecha no puede ser futura');
    }

    // Validación 3: Categoría es obligatoria (excepto para transferencias)
    if (type != TransactionType.transfer && categoryId == null) {
      errors.add('Debes seleccionar una categoría');
    }

    // Validación 4: Transferencias requieren cuenta destino
    if (type == TransactionType.transfer && transferToAccountId == null) {
      errors.add('Debes seleccionar la cuenta de destino');
    }

    // Validación 5: Cuenta destino debe ser diferente a origen
    if (type == TransactionType.transfer && transferToAccountId == accountId) {
      errors.add('La cuenta de destino debe ser diferente a la de origen');
    }

    return errors;
  }

  /// Indica si la transacción es válida
  bool get isValid => validationErrors.isEmpty;

  /// Valida la transacción y lanza excepción si hay errores
  void validate() {
    final errors = validationErrors;
    if (errors.isNotEmpty) {
      throw ArgumentError('Transacción inválida:\n${errors.join('\n')}');
    }
  }

  /// Convierte a Map para Supabase
  Map<String, dynamic> toSupabaseMap() {
    return {
      'id': id,
      'user_id': userId,
      'account_id': accountId,
      'category_id': categoryId,
      'amount': amount,
      'type': type.name,
      'payment_method': paymentMethod.name,
      'description': description,
      'date': date.toIso8601String(),
      'notes': notes,
      'tags': tags.isEmpty ? null : tags.join(','),
      'transfer_to_account_id': transferToAccountId,
      'recurring_id': recurringId,
    };
  }

  /// Crear desde respuesta de Supabase
  factory TransactionModel.fromSupabase(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      accountId: json['account_id'] as String,
      categoryId: json['category_id'] as int?,
      amount: (json['amount'] as num).toDouble(),
      type: TransactionType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => TransactionType.expense,
      ),
      paymentMethod: json['payment_method'] != null
          ? PaymentMethod.values.firstWhere(
              (e) => e.name == json['payment_method'],
              orElse: () => PaymentMethod.cash,
            )
          : PaymentMethod.cash,
      description: json['description'] as String?,
      date: DateTime.parse(json['date'] as String),
      notes: json['notes'] as String?,
      tags: json['tags'] != null
          ? (json['tags'] as String).split(',').where((s) => s.isNotEmpty).toList()
          : [],
      transferToAccountId: json['transfer_to_account_id'] as String?,
      recurringId: json['recurring_id'] as String?,
      isSynced: true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }
}

/// Modelo de categoria
@freezed
class CategoryModel with _$CategoryModel {
  const CategoryModel._();

  const factory CategoryModel({
    required int id,
    required String uuid,
    String? userId,
    String? familyId,
    required String name,
    required String type, // income, expense
    String? icon,
    String? emoji, // Emoji representativo (ej: 🍔, 🏠, 🚗)
    String? color,
    int? parentId,
    @Default(false) bool isSystem,
    @Default(false) bool isSynced,
    DateTime? createdAt,
  }) = _CategoryModel;

  factory CategoryModel.fromJson(Map<String, dynamic> json) =>
      _$CategoryModelFromJson(json);

  bool get isIncome => type == 'income';
  bool get isExpense => type == 'expense';
}
