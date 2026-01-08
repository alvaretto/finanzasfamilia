import 'package:uuid/uuid.dart';

enum AccountType {
  cash,
  bank,
  digitalWallet,
  investment,
}

enum AccountSubtype {
  // Cash
  wallet,
  cashBox,
  piggyBank,
  // Bank
  savings,
  checking,
  // Digital Wallet
  nequi,
  daviplata,
  paypal,
  dollarApp,
  // Investment
  cdt,
  property,
  other,
}

class Account {
  final String id;
  final String userId;
  final String name;
  final AccountType type;
  final AccountSubtype? subtype;
  final double balance;
  final String currency;
  final String? icon;
  final String? color;
  final bool isActive;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  Account({
    String? id,
    required this.userId,
    required this.name,
    required this.type,
    this.subtype,
    this.balance = 0,
    this.currency = 'COP',
    this.icon,
    this.color,
    this.isActive = true,
    this.sortOrder = 0,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  Account copyWith({
    String? name,
    AccountType? type,
    AccountSubtype? subtype,
    double? balance,
    String? currency,
    String? icon,
    String? color,
    bool? isActive,
    int? sortOrder,
  }) {
    return Account(
      id: id,
      userId: userId,
      name: name ?? this.name,
      type: type ?? this.type,
      subtype: subtype ?? this.subtype,
      balance: balance ?? this.balance,
      currency: currency ?? this.currency,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      isActive: isActive ?? this.isActive,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'type': type.name,
      'subtype': subtype?.name,
      'balance': balance,
      'currency': currency,
      'icon': icon,
      'color': color,
      'is_active': isActive ? 1 : 0,
      'sort_order': sortOrder,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Account.fromMap(Map<String, dynamic> map) {
    return Account(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      name: map['name'] as String,
      type: AccountType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => AccountType.cash,
      ),
      subtype: map['subtype'] != null
          ? AccountSubtype.values.firstWhere(
              (e) => e.name == map['subtype'],
              orElse: () => AccountSubtype.other,
            )
          : null,
      balance: (map['balance'] as num?)?.toDouble() ?? 0,
      currency: map['currency'] as String? ?? 'COP',
      icon: map['icon'] as String?,
      color: map['color'] as String?,
      isActive: map['is_active'] == 1,
      sortOrder: map['sort_order'] as int? ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  /// Nombre amigable del tipo de cuenta
  String get typeLabel {
    switch (type) {
      case AccountType.cash:
        return 'Efectivo';
      case AccountType.bank:
        return 'Banco';
      case AccountType.digitalWallet:
        return 'Billetera Digital';
      case AccountType.investment:
        return 'Inversión';
    }
  }
}
