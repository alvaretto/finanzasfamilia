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
        return 'Me Deben';
      case AccountType.payable:
        return 'Debo Pagar';
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

/// Subtipo de deuda (para loan y payable)
enum DebtSubtype {
  bankLoan,         // Préstamo bancario tradicional
  mortgage,         // Hipoteca / Crédito vivienda
  vehicleLoan,      // Crédito de vehículo
  personalLoan,     // Préstamo personal (libre inversión)
  familyLoan,       // Préstamo de familiar
  friendLoan,       // Préstamo de amigo
  employerLoan,     // Préstamo de empleador
  educationLoan,    // Crédito educativo (ICETEX, etc.)
  appliances,       // Cuotas electrodomésticos/muebles
  utilities,        // Servicios públicos atrasados
  taxes,            // Impuestos pendientes
  medical,          // Deudas médicas
  informalLoan,     // Préstamo informal (gota a gota, etc.)
  other,            // Otro tipo de deuda
}

extension DebtSubtypeExtension on DebtSubtype {
  String get displayName {
    switch (this) {
      case DebtSubtype.bankLoan:
        return 'Préstamo Bancario';
      case DebtSubtype.mortgage:
        return 'Hipoteca / Vivienda';
      case DebtSubtype.vehicleLoan:
        return 'Crédito Vehículo';
      case DebtSubtype.personalLoan:
        return 'Libre Inversión';
      case DebtSubtype.familyLoan:
        return 'Préstamo Familiar';
      case DebtSubtype.friendLoan:
        return 'Préstamo de Amigo';
      case DebtSubtype.employerLoan:
        return 'Préstamo Empleador';
      case DebtSubtype.educationLoan:
        return 'Crédito Educativo';
      case DebtSubtype.appliances:
        return 'Cuotas Electrodomésticos';
      case DebtSubtype.utilities:
        return 'Servicios Atrasados';
      case DebtSubtype.taxes:
        return 'Impuestos Pendientes';
      case DebtSubtype.medical:
        return 'Deudas Médicas';
      case DebtSubtype.informalLoan:
        return 'Préstamo Informal';
      case DebtSubtype.other:
        return 'Otra Deuda';
    }
  }

  String get icon {
    switch (this) {
      case DebtSubtype.bankLoan:
        return 'account_balance';
      case DebtSubtype.mortgage:
        return 'home';
      case DebtSubtype.vehicleLoan:
        return 'directions_car';
      case DebtSubtype.personalLoan:
        return 'person';
      case DebtSubtype.familyLoan:
        return 'family_restroom';
      case DebtSubtype.friendLoan:
        return 'people';
      case DebtSubtype.employerLoan:
        return 'business';
      case DebtSubtype.educationLoan:
        return 'school';
      case DebtSubtype.appliances:
        return 'kitchen';
      case DebtSubtype.utilities:
        return 'bolt';
      case DebtSubtype.taxes:
        return 'receipt_long';
      case DebtSubtype.medical:
        return 'local_hospital';
      case DebtSubtype.informalLoan:
        return 'warning';
      case DebtSubtype.other:
        return 'more_horiz';
    }
  }

  String get emoji {
    switch (this) {
      case DebtSubtype.bankLoan:
        return '🏦';
      case DebtSubtype.mortgage:
        return '🏠';
      case DebtSubtype.vehicleLoan:
        return '🚗';
      case DebtSubtype.personalLoan:
        return '💰';
      case DebtSubtype.familyLoan:
        return '👨‍👩‍👧';
      case DebtSubtype.friendLoan:
        return '🤝';
      case DebtSubtype.employerLoan:
        return '🏢';
      case DebtSubtype.educationLoan:
        return '🎓';
      case DebtSubtype.appliances:
        return '📺';
      case DebtSubtype.utilities:
        return '💡';
      case DebtSubtype.taxes:
        return '📋';
      case DebtSubtype.medical:
        return '🏥';
      case DebtSubtype.informalLoan:
        return '⚠️';
      case DebtSubtype.other:
        return '📝';
    }
  }
}

/// Grupo de cuenta para organización
enum AccountGroup {
  personal,  // Cuentas personales
  family,    // Cuentas familiares compartidas
  business,  // Cuentas de negocio
  other,     // Otras
}

extension AccountGroupExtension on AccountGroup {
  String get displayName {
    switch (this) {
      case AccountGroup.personal:
        return '👤 Personal';
      case AccountGroup.family:
        return '👨‍👩‍👧‍👦 Familiar';
      case AccountGroup.business:
        return '💼 Negocio';
      case AccountGroup.other:
        return '📁 Otros';
    }
  }

  String get emoji {
    switch (this) {
      case AccountGroup.personal:
        return '👤';
      case AccountGroup.family:
        return '👨‍👩‍👧‍👦';
      case AccountGroup.business:
        return '💼';
      case AccountGroup.other:
        return '📁';
    }
  }
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
    @Default(AccountGroup.personal) AccountGroup accountGroup,
    @Default(false) bool isTestAccount,
    DebtSubtype? debtSubtype,  // Subtipo de deuda (para loan, payable)
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
    AccountGroup accountGroup = AccountGroup.personal,
    bool isTestAccount = false,
    DebtSubtype? debtSubtype,
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
      accountGroup: accountGroup,
      isTestAccount: isTestAccount,
      debtSubtype: debtSubtype,
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
    final map = {
      'id': id,
      'user_id': userId,
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
      'account_group': accountGroup.name,
      'is_test_account': isTestAccount,
      'debt_subtype': debtSubtype?.name,
    };

    // Solo incluir family_id si no es null (evita trigger de RLS)
    if (familyId != null) {
      map['family_id'] = familyId;
    }

    return map;
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
      accountGroup: AccountGroup.values.firstWhere(
        (e) => e.name == json['account_group'],
        orElse: () => AccountGroup.personal,
      ),
      isTestAccount: json['is_test_account'] as bool? ?? false,
      debtSubtype: json['debt_subtype'] != null
          ? DebtSubtype.values.firstWhere(
              (e) => e.name == json['debt_subtype'],
              orElse: () => DebtSubtype.other,
            )
          : null,
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
