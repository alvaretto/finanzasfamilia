import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/models/payment_enums.dart' as payment;

part 'transaction_model.freezed.dart';
part 'transaction_model.g.dart';

const _uuid = Uuid();

/// Tipos de transaccion
enum TransactionType {
  income,
  expense,
  transfer,
}

/// Metodos de pago disponibles (legacy - mantener para compatibilidad)
/// @deprecated Usar payment.PaymentMethod y payment.PaymentMedium
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
    String? categoryId,
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

    // ============ NUEVOS CAMPOS v3 - Detalles del artículo ============
    /// Descripción específica del artículo (ej: "Arroz")
    String? itemDescription,
    /// Marca del producto (ej: "Roa")
    String? brand,
    /// Cantidad comprada (ej: 10)
    double? quantity,
    /// ID de la unidad de medida (reference to Units.id)
    String? unitId,
    /// Precio unitario calculado (amount / quantity)
    double? unitPrice,

    // ============ NUEVOS CAMPOS v3 - Lugar de compra ============
    /// ID del establecimiento (reference to Establishments.id)
    String? establishmentId,

    // ============ NUEVOS CAMPOS v3 - Forma y medio de pago mejorado ============
    /// Forma de pago: credit, cash (nuevo sistema)
    String? paymentMethodV2,
    /// Medio de pago: credit_card, fiado, cash, bank_transfer, app_transfer
    String? paymentMedium,
    /// Submedio de pago: davivienda, bancolombia, nequi, daviplata, etc.
    String? paymentSubmedium,

    // ============ Campos para UI (no persistidos) ============
    String? accountName,
    String? categoryName,
    String? categoryIcon,
    String? categoryColor,
    String? transferToAccountName,
    /// Nombre de la unidad de medida (para UI)
    String? unitName,
    String? unitShortName,
    /// Datos del establecimiento (para UI)
    String? establishmentName,
    String? establishmentAddress,
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
    String? categoryId,
    String? description,
    DateTime? date,
    String? notes,
    List<String>? tags,
    String? transferToAccountId,
    String? recurringId,
    // Nuevos campos v3
    String? itemDescription,
    String? brand,
    double? quantity,
    String? unitId,
    String? establishmentId,
    String? paymentMethodV2,
    String? paymentMedium,
    String? paymentSubmedium,
  }) {
    // Calcular precio unitario si hay cantidad
    double? unitPrice;
    if (quantity != null && quantity > 0) {
      unitPrice = amount.abs() / quantity;
    }

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
      // Nuevos campos v3
      itemDescription: itemDescription,
      brand: brand,
      quantity: quantity,
      unitId: unitId,
      unitPrice: unitPrice,
      establishmentId: establishmentId,
      paymentMethodV2: paymentMethodV2,
      paymentMedium: paymentMedium,
      paymentSubmedium: paymentSubmedium,
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
      // Nuevos campos v3
      'item_description': itemDescription,
      'brand': brand,
      'quantity': quantity,
      'unit_id': unitId,
      'unit_price': unitPrice,
      'establishment_id': establishmentId,
      'payment_method_v2': paymentMethodV2,
      'payment_medium': paymentMedium,
      'payment_submedium': paymentSubmedium,
    };
  }

  /// Descripción completa del artículo para mostrar en UI
  /// Ejemplo: "Arroz Roa 10 lb" o solo "Arroz" si no hay detalles
  String get fullItemDescription {
    final parts = <String>[];
    if (itemDescription != null && itemDescription!.isNotEmpty) {
      parts.add(itemDescription!);
    }
    if (brand != null && brand!.isNotEmpty) {
      parts.add(brand!);
    }
    if (quantity != null && quantity! > 0) {
      final qtyStr = quantity! == quantity!.toInt()
          ? quantity!.toInt().toString()
          : quantity!.toStringAsFixed(2);
      final unitStr = unitShortName ?? '';
      parts.add('$qtyStr $unitStr'.trim());
    }
    return parts.isEmpty ? (description ?? '') : parts.join(' ');
  }

  /// Obtiene el medio de pago como enum tipado
  payment.PaymentMethod? get paymentMethodV2Enum =>
      payment.PaymentMethod.fromValue(paymentMethodV2);

  /// Obtiene el medio de pago específico como enum tipado
  payment.PaymentMedium? get paymentMediumEnum =>
      payment.PaymentMedium.fromValue(paymentMedium);

  /// Descripción legible del método de pago
  String get paymentDescription {
    final method = paymentMethodV2Enum;
    final medium = paymentMediumEnum;

    if (method == null && medium == null) {
      return paymentMethod.displayName; // Fallback al legacy
    }

    final parts = <String>[];
    if (medium != null) {
      parts.add(medium.displayName);
    }
    if (paymentSubmedium != null && paymentSubmedium!.isNotEmpty) {
      // Intentar obtener nombre legible del submedio
      final bank = payment.BankTransferProvider.fromValue(paymentSubmedium);
      final app = payment.AppTransferProvider.fromValue(paymentSubmedium);
      if (bank != null && bank != payment.BankTransferProvider.otro) {
        parts.add('(${bank.displayName})');
      } else if (app != null && app != payment.AppTransferProvider.otro) {
        parts.add('(${app.displayName})');
      }
    }

    return parts.isEmpty ? 'Sin especificar' : parts.join(' ');
  }

  /// Crear desde respuesta de Supabase
  factory TransactionModel.fromSupabase(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      accountId: json['account_id'] as String,
      categoryId: json['category_id'] as String?,
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
      // Nuevos campos v3
      itemDescription: json['item_description'] as String?,
      brand: json['brand'] as String?,
      quantity: (json['quantity'] as num?)?.toDouble(),
      unitId: json['unit_id'] as String?,
      unitPrice: (json['unit_price'] as num?)?.toDouble(),
      establishmentId: json['establishment_id'] as String?,
      paymentMethodV2: json['payment_method_v2'] as String?,
      paymentMedium: json['payment_medium'] as String?,
      paymentSubmedium: json['payment_submedium'] as String?,
    );
  }
}

/// Modelo de categoria
@freezed
class CategoryModel with _$CategoryModel {
  const CategoryModel._();

  const factory CategoryModel({
    required String id,
    String? userId,
    String? familyId,
    required String name,
    required String type, // income, expense
    String? icon,
    String? emoji, // Emoji representativo (ej: 🍔, 🏠, 🚗)
    String? color,
    String? parentId,
    @Default(false) bool isSystem,
    @Default(false) bool isSynced,
    DateTime? createdAt,
  }) = _CategoryModel;

  factory CategoryModel.fromJson(Map<String, dynamic> json) =>
      _$CategoryModelFromJson(json);

  bool get isIncome => type == 'income';
  bool get isExpense => type == 'expense';
}
