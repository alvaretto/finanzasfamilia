/// Frecuencia de transacción recurrente
enum RecurringFrequency {
  daily,
  weekly,
  monthly,
  yearly;

  String get displayName {
    switch (this) {
      case RecurringFrequency.daily:
        return 'Diario';
      case RecurringFrequency.weekly:
        return 'Semanal';
      case RecurringFrequency.monthly:
        return 'Mensual';
      case RecurringFrequency.yearly:
        return 'Anual';
    }
  }

  String get shortName {
    switch (this) {
      case RecurringFrequency.daily:
        return 'día';
      case RecurringFrequency.weekly:
        return 'sem';
      case RecurringFrequency.monthly:
        return 'mes';
      case RecurringFrequency.yearly:
        return 'año';
    }
  }

  /// Calcular próxima ocurrencia
  DateTime nextFrom(DateTime current) {
    switch (this) {
      case RecurringFrequency.daily:
        return current.add(const Duration(days: 1));
      case RecurringFrequency.weekly:
        return current.add(const Duration(days: 7));
      case RecurringFrequency.monthly:
        return DateTime(current.year, current.month + 1, current.day);
      case RecurringFrequency.yearly:
        return DateTime(current.year + 1, current.month, current.day);
    }
  }
}

/// Tipo de transacción
enum RecurringType {
  income,
  expense;

  String get displayName {
    switch (this) {
      case RecurringType.income:
        return 'Ingreso';
      case RecurringType.expense:
        return 'Gasto';
    }
  }
}

/// Modelo de transacción recurrente
class RecurringModel {
  final String id;
  final String userId;
  final String accountId;
  final String? categoryId;
  final double amount;
  final RecurringType type;
  final String? description;
  final RecurringFrequency frequency;
  final DateTime startDate;
  final DateTime? endDate;
  final DateTime nextOccurrence;
  final bool isActive;
  final DateTime createdAt;

  // Datos relacionados (para display)
  final String? accountName;
  final String? categoryName;
  final String? categoryIcon;
  final String? categoryColor;

  const RecurringModel({
    required this.id,
    required this.userId,
    required this.accountId,
    this.categoryId,
    required this.amount,
    required this.type,
    this.description,
    required this.frequency,
    required this.startDate,
    this.endDate,
    required this.nextOccurrence,
    this.isActive = true,
    required this.createdAt,
    this.accountName,
    this.categoryName,
    this.categoryIcon,
    this.categoryColor,
  });

  /// Verificar si ya expiró
  bool get isExpired {
    if (endDate == null) return false;
    return DateTime.now().isAfter(endDate!);
  }

  /// Días hasta próxima ocurrencia
  int get daysUntilNext {
    final now = DateTime.now();
    return nextOccurrence.difference(now).inDays;
  }

  /// Es hoy
  bool get isDueToday {
    final now = DateTime.now();
    return nextOccurrence.year == now.year &&
        nextOccurrence.month == now.month &&
        nextOccurrence.day == now.day;
  }

  /// Ya pasó (pendiente de ejecutar)
  bool get isOverdue {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(nextOccurrence.year, nextOccurrence.month, nextOccurrence.day);
    return due.isBefore(today);
  }

  RecurringModel copyWith({
    String? id,
    String? userId,
    String? accountId,
    String? categoryId,
    double? amount,
    RecurringType? type,
    String? description,
    RecurringFrequency? frequency,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? nextOccurrence,
    bool? isActive,
    DateTime? createdAt,
    String? accountName,
    String? categoryName,
    String? categoryIcon,
    String? categoryColor,
  }) {
    return RecurringModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      accountId: accountId ?? this.accountId,
      categoryId: categoryId ?? this.categoryId,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      description: description ?? this.description,
      frequency: frequency ?? this.frequency,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      nextOccurrence: nextOccurrence ?? this.nextOccurrence,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      accountName: accountName ?? this.accountName,
      categoryName: categoryName ?? this.categoryName,
      categoryIcon: categoryIcon ?? this.categoryIcon,
      categoryColor: categoryColor ?? this.categoryColor,
    );
  }

  factory RecurringModel.fromJson(Map<String, dynamic> json) {
    final account = json['accounts'] as Map<String, dynamic>?;
    final category = json['categories'] as Map<String, dynamic>?;

    return RecurringModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      accountId: json['account_id'] as String,
      categoryId: json['category_id'] as String?,
      amount: (json['amount'] as num).toDouble(),
      type: RecurringType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => RecurringType.expense,
      ),
      description: json['description'] as String?,
      frequency: RecurringFrequency.values.firstWhere(
        (f) => f.name == json['frequency'],
        orElse: () => RecurringFrequency.monthly,
      ),
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'] as String)
          : null,
      nextOccurrence: DateTime.parse(json['next_occurrence'] as String),
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      accountName: account?['name'] as String?,
      categoryName: category?['name'] as String?,
      categoryIcon: category?['icon'] as String?,
      categoryColor: category?['color'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'account_id': accountId,
      'category_id': categoryId,
      'amount': amount,
      'type': type.name,
      'description': description,
      'frequency': frequency.name,
      'start_date': startDate.toIso8601String().split('T')[0],
      'end_date': endDate?.toIso8601String().split('T')[0],
      'next_occurrence': nextOccurrence.toIso8601String().split('T')[0],
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'user_id': userId,
      'account_id': accountId,
      'category_id': categoryId,
      'amount': amount,
      'type': type.name,
      'description': description,
      'frequency': frequency.name,
      'start_date': startDate.toIso8601String().split('T')[0],
      'end_date': endDate?.toIso8601String().split('T')[0],
      'next_occurrence': nextOccurrence.toIso8601String().split('T')[0],
      'is_active': isActive,
    };
  }
}
