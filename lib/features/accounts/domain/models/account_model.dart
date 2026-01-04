import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:uuid/uuid.dart';

part 'account_model.freezed.dart';
part 'account_model.g.dart';

const _uuid = Uuid();

/// Tipos de cuenta disponibles
enum AccountType {
  cash,        // Efectivo
  bank,        // Cuenta bancaria
  wallet,      // Billetera digital (Nequi, Daviplata, PayPal)
  savings,     // Cuenta de ahorros, CDT
  investment,  // Inversiones (acciones, cripto, fondos)
  credit,      // Tarjeta de credito (PASIVO)
  loan,        // Prestamo (PASIVO)
  receivable,  // Cuenta por cobrar (dinero prestado a otros)
  payable,     // Cuenta por pagar (deudas con terceros)
}

extension AccountTypeExtension on AccountType {
  String get displayName {
    switch (this) {
      case AccountType.cash:
        return 'Efectivo';
      case AccountType.bank:
        return 'Cuenta Bancaria';
      case AccountType.wallet:
        return 'Billetera Digital';
      case AccountType.savings:
        return 'Ahorros';
      case AccountType.investment:
        return 'Inversiones';
      case AccountType.credit:
        return 'Tarjeta de Credito';
      case AccountType.loan:
        return 'Prestamo';
      case AccountType.receivable:
        return 'Cuenta por Cobrar';
      case AccountType.payable:
        return 'Cuenta por Pagar';
    }
  }

  String get icon {
    switch (this) {
      case AccountType.cash:
        return 'payments';
      case AccountType.bank:
        return 'account_balance';
      case AccountType.wallet:
        return 'account_balance_wallet';
      case AccountType.savings:
        return 'savings';
      case AccountType.investment:
        return 'trending_up';
      case AccountType.credit:
        return 'credit_card';
      case AccountType.loan:
        return 'real_estate_agent';
      case AccountType.receivable:
        return 'arrow_circle_down';
      case AccountType.payable:
        return 'arrow_circle_up';
    }
  }

  /// Indica si es cuenta de pasivo (resta al patrimonio neto)
  bool get isLiability {
    switch (this) {
      case AccountType.credit:
      case AccountType.loan:
      case AccountType.payable:
        return true;
      default:
        return false;
    }
  }

  /// Indica si es cuenta de activo (suma al patrimonio neto)
  bool get isAsset => !isLiability;
}

/// Modelo de cuenta financiera
@freezed
class AccountModel with _$AccountModel {
  const AccountModel._();

  const factory AccountModel({
    required String id,
    required String userId,
    String? familyId,
    required String name,
    required AccountType type,
    required String currency,
    @Default(0.0) double balance,
    @Default(0.0) double creditLimit,
    String? color,
    String? icon,
    String? bankName,
    String? lastFourDigits,
    @Default(true) bool isActive,
    @Default(false) bool includeInTotal,
    DateTime? createdAt,
    DateTime? updatedAt,
    @Default(false) bool isSynced,
  }) = _AccountModel;

  factory AccountModel.fromJson(Map<String, dynamic> json) =>
      _$AccountModelFromJson(json);

  /// Crear nueva cuenta con valores por defecto
  factory AccountModel.create({
    required String userId,
    required String name,
    required AccountType type,
    String currency = 'COP',
    double balance = 0.0,
    String? familyId,
    String? color,
    String? icon,
    String? bankName,
    String? lastFourDigits,
    double creditLimit = 0.0,
  }) {
    return AccountModel(
      id: _uuid.v4(),
      userId: userId,
      familyId: familyId,
      name: name,
      type: type,
      currency: currency,
      balance: balance,
      creditLimit: creditLimit,
      color: color ?? '#4CAF50',
      icon: icon ?? type.icon,
      bankName: bankName,
      lastFourDigits: lastFourDigits,
      isActive: true,
      includeInTotal: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isSynced: false,
    );
  }

  /// Balance disponible (para tarjetas de crédito considera el límite)
  double get availableBalance {
    if (type == AccountType.credit) {
      return creditLimit - balance.abs();
    }
    return balance;
  }

  /// Indica si es cuenta de deuda/pasivo
  bool get isDebtAccount => type.isLiability;

  /// Balance efectivo para patrimonio neto
  /// Pasivos restan, activos suman
  double get netWorthContribution {
    if (type.isLiability) {
      return -balance.abs();
    }
    return balance;
  }

  /// Convierte a Map para Supabase
  Map<String, dynamic> toSupabaseMap() {
    return {
      'id': id,
      'user_id': userId,
      'family_id': familyId,
      'name': name,
      'type': type.name,
      'currency': currency,
      'balance': balance,
      'credit_limit': creditLimit,
      'color': color,
      'icon': icon,
      'bank_name': bankName,
      'last_four_digits': lastFourDigits,
      'is_active': isActive,
      'include_in_total': includeInTotal,
    };
  }

  /// Crear desde respuesta de Supabase
  factory AccountModel.fromSupabase(Map<String, dynamic> json) {
    return AccountModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      familyId: json['family_id'] as String?,
      name: json['name'] as String,
      type: AccountType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => AccountType.bank,
      ),
      currency: json['currency'] as String? ?? 'COP',
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
      creditLimit: (json['credit_limit'] as num?)?.toDouble() ?? 0.0,
      color: json['color'] as String?,
      icon: json['icon'] as String?,
      bankName: json['bank_name'] as String?,
      lastFourDigits: json['last_four_digits'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      includeInTotal: json['include_in_total'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      isSynced: true,
    );
  }
}
