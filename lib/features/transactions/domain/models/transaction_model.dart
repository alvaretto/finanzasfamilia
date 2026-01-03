import 'package:freezed_annotation/freezed_annotation.dart';

part 'transaction_model.freezed.dart';
part 'transaction_model.g.dart';

/// Tipos de transaccion
enum TransactionType {
  income,
  expense,
  transfer,
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
    int? categoryId,
    String? description,
    DateTime? date,
    String? notes,
    List<String>? tags,
    String? transferToAccountId,
    String? recurringId,
  }) {
    return TransactionModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      accountId: accountId,
      categoryId: categoryId,
      amount: amount.abs(),
      type: type,
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

  /// Convierte a Map para Supabase
  Map<String, dynamic> toSupabaseMap() {
    return {
      'id': id,
      'user_id': userId,
      'account_id': accountId,
      'category_id': categoryId,
      'amount': amount,
      'type': type.name,
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
