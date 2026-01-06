/// Modelo de template para cuentas en el wizard de onboarding
/// Define los tipos de cuenta predefinidos y sus configuraciones
/// 
/// Versión: 1.0.0
/// Fecha: 2025-01-05

import '../../../accounts/domain/models/account_model.dart';

/// Template de cuenta para el wizard de onboarding
/// Define la configuración predeterminada de cada tipo de cuenta
class AccountTemplate {
  final AccountType type;
  final String defaultName;
  final String emoji;
  final String description;
  final bool isAsset;
  final bool requiresBankSelection;
  final bool requiresCreditLimit;
  final List<String>? suggestedNames;
  final String defaultColor;

  const AccountTemplate({
    required this.type,
    required this.defaultName,
    required this.emoji,
    required this.description,
    required this.isAsset,
    this.requiresBankSelection = false,
    this.requiresCreditLimit = false,
    this.suggestedNames,
    required this.defaultColor,
  });

  /// Templates predefinidos para Colombia
  static const List<AccountTemplate> templates = [
    // ==================== ACTIVOS (Lo que tengo 💰) ====================
    AccountTemplate(
      type: AccountType.bank,
      defaultName: 'Banco',
      emoji: '🏦',
      description: 'Cuenta de ahorros o corriente',
      isAsset: true,
      requiresBankSelection: true,
      suggestedNames: [
        'Bancolombia',
        'Davivienda',
        'Banco de Bogotá',
        'BBVA',
        'Scotiabank Colpatria',
        'AV Villas',
        'Banco Popular',
        'Banco de Occidente',
        'Banco Caja Social',
        'Banco Falabella',
        'Banco Pichincha',
        'Itaú',
        'Citibank',
        'GNB Sudameris',
      ],
      defaultColor: '#2196F3',
    ),

    AccountTemplate(
      type: AccountType.wallet,
      defaultName: 'Billetera Digital',
      emoji: '📱',
      description: 'Nequi, DaviPlata, etc.',
      isAsset: true,
      suggestedNames: [
        'Nequi',
        'DaviPlata',
        'DollarApp',
        'Movii',
        'Dale!',
        'Powwi',
        'RappiPay',
        'Tpaga',
        'PSE',
        'Pibank',
      ],
      defaultColor: '#9C27B0',
    ),

    AccountTemplate(
      type: AccountType.savings,
      defaultName: 'Alcancía',
      emoji: '🐷',
      description: 'Ahorros en casa o guardados',
      isAsset: true,
      defaultColor: '#FF9800',
    ),

    AccountTemplate(
      type: AccountType.investment,
      defaultName: 'Inversión',
      emoji: '📈',
      description: 'CDT, acciones, fondos',
      isAsset: true,
      suggestedNames: [
        'CDT',
        'Acciones',
        'Fondo de inversión',
        'Fiducuenta',
        'Fondo voluntario pensión',
        'Criptomonedas',
        'TES',
        'Bonos',
      ],
      defaultColor: '#009688',
    ),

    // ==================== PASIVOS (Lo que debo 💳) ====================
    AccountTemplate(
      type: AccountType.credit,
      defaultName: 'Tarjeta de Crédito',
      emoji: '💳',
      description: 'Cualquier tarjeta de crédito',
      isAsset: false,
      requiresCreditLimit: true,
      suggestedNames: [
        'Visa',
        'Mastercard',
        'American Express',
        'Diners Club',
        'Tarjeta Éxito',
        'Tarjeta Alkosto',
        'Tarjeta Falabella',
        'Nu Colombia',
        'RappiCard',
      ],
      defaultColor: '#F44336',
    ),

    AccountTemplate(
      type: AccountType.loan,
      defaultName: 'Préstamo Bancario',
      emoji: '🏦',
      description: 'Crédito de consumo, hipotecario, etc.',
      isAsset: false,
      requiresBankSelection: true,
      defaultColor: '#E91E63',
    ),

    AccountTemplate(
      type: AccountType.payable,
      defaultName: 'Préstamo Personal',
      emoji: '👥',
      description: 'Préstamo de amigos o familiares',
      isAsset: false,
      defaultColor: '#FF5722',
    ),

    AccountTemplate(
      type: AccountType.receivable,
      defaultName: 'Me Deben',
      emoji: '📝',
      description: 'Dinero prestado a otros',
      isAsset: true,
      defaultColor: '#4CAF50',
    ),
  ];

  /// Encuentra template por tipo
  static AccountTemplate? getByType(AccountType type) {
    try {
      return templates.firstWhere((t) => t.type == type);
    } catch (_) {
      return null;
    }
  }

  /// Solo activos (para el wizard principal)
  static List<AccountTemplate> get assets {
    return templates.where((t) => t.isAsset).toList();
  }

  /// Solo pasivos (para sección opcional)
  static List<AccountTemplate> get liabilities {
    return templates.where((t) => !t.isAsset).toList();
  }

  /// Obtener el icono Material del tipo de cuenta
  String get materialIcon => type.icon;
}

/// Datos de cuenta en configuración del wizard
/// Almacena la configuración temporal mientras el usuario completa el wizard
class AccountConfigData {
  final AccountType type;
  final String name;
  final double initialBalance;
  final String? bankName;
  final double? creditLimit;
  final String color;
  final String emoji;

  AccountConfigData({
    required this.type,
    required this.name,
    this.initialBalance = 0,
    this.bankName,
    this.creditLimit,
    required this.color,
    required this.emoji,
  });

  AccountConfigData copyWith({
    AccountType? type,
    String? name,
    double? initialBalance,
    String? bankName,
    double? creditLimit,
    String? color,
    String? emoji,
  }) {
    return AccountConfigData(
      type: type ?? this.type,
      name: name ?? this.name,
      initialBalance: initialBalance ?? this.initialBalance,
      bankName: bankName ?? this.bankName,
      creditLimit: creditLimit ?? this.creditLimit,
      color: color ?? this.color,
      emoji: emoji ?? this.emoji,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'name': name,
      'initialBalance': initialBalance,
      'bankName': bankName,
      'creditLimit': creditLimit,
      'color': color,
      'emoji': emoji,
    };
  }

  factory AccountConfigData.fromJson(Map<String, dynamic> json) {
    return AccountConfigData(
      type: AccountType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => AccountType.bank,
      ),
      name: json['name'] as String,
      initialBalance: (json['initialBalance'] as num?)?.toDouble() ?? 0,
      bankName: json['bankName'] as String?,
      creditLimit: (json['creditLimit'] as num?)?.toDouble(),
      color: json['color'] as String? ?? '#4CAF50',
      emoji: json['emoji'] as String? ?? '💰',
    );
  }

  /// Crear desde un template
  factory AccountConfigData.fromTemplate(AccountTemplate template) {
    return AccountConfigData(
      type: template.type,
      name: template.defaultName,
      initialBalance: 0,
      bankName: null,
      creditLimit: template.requiresCreditLimit ? 0 : null,
      color: template.defaultColor,
      emoji: template.emoji,
    );
  }
}
