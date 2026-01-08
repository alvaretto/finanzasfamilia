import 'dart:convert';
import 'package:uuid/uuid.dart';

enum TransactionType {
  income,
  expense,
  transfer,
}

class Transaction {
  final String id;
  final String userId;
  final String? accountId;
  final String? liabilityId;
  final String? categoryId;
  final TransactionType type;
  final double amount;
  final String? description;
  final DateTime date;
  final String? time;
  final bool isRecurring;
  final String? recurringId;
  final List<String> tags;
  final List<String> attachments;
  final DateTime createdAt;
  final DateTime updatedAt;

  Transaction({
    String? id,
    required this.userId,
    this.accountId,
    this.liabilityId,
    this.categoryId,
    required this.type,
    required this.amount,
    this.description,
    required this.date,
    this.time,
    this.isRecurring = false,
    this.recurringId,
    this.tags = const [],
    this.attachments = const [],
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  Transaction copyWith({
    String? accountId,
    String? liabilityId,
    String? categoryId,
    TransactionType? type,
    double? amount,
    String? description,
    DateTime? date,
    String? time,
    bool? isRecurring,
    String? recurringId,
    List<String>? tags,
    List<String>? attachments,
  }) {
    return Transaction(
      id: id,
      userId: userId,
      accountId: accountId ?? this.accountId,
      liabilityId: liabilityId ?? this.liabilityId,
      categoryId: categoryId ?? this.categoryId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      date: date ?? this.date,
      time: time ?? this.time,
      isRecurring: isRecurring ?? this.isRecurring,
      recurringId: recurringId ?? this.recurringId,
      tags: tags ?? this.tags,
      attachments: attachments ?? this.attachments,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'account_id': accountId,
      'liability_id': liabilityId,
      'category_id': categoryId,
      'type': type.name,
      'amount': amount,
      'description': description,
      'date': date.toIso8601String().split('T').first,
      'time': time,
      'is_recurring': isRecurring ? 1 : 0,
      'recurring_id': recurringId,
      'tags': jsonEncode(tags),
      'attachments': jsonEncode(attachments),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      accountId: map['account_id'] as String?,
      liabilityId: map['liability_id'] as String?,
      categoryId: map['category_id'] as String?,
      type: TransactionType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => TransactionType.expense,
      ),
      amount: (map['amount'] as num).toDouble(),
      description: map['description'] as String?,
      date: DateTime.parse(map['date'] as String),
      time: map['time'] as String?,
      isRecurring: map['is_recurring'] == 1,
      recurringId: map['recurring_id'] as String?,
      tags: map['tags'] != null
          ? List<String>.from(jsonDecode(map['tags'] as String))
          : [],
      attachments: map['attachments'] != null
          ? List<String>.from(jsonDecode(map['attachments'] as String))
          : [],
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  /// Monto con signo según tipo
  double get signedAmount {
    return type == TransactionType.expense ? -amount : amount;
  }

  /// Etiqueta del tipo
  String get typeLabel {
    switch (type) {
      case TransactionType.income:
        return 'Ingreso';
      case TransactionType.expense:
        return 'Gasto';
      case TransactionType.transfer:
        return 'Transferencia';
    }
  }
}
