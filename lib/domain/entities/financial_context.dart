import 'package:freezed_annotation/freezed_annotation.dart';

part 'financial_context.freezed.dart';
part 'financial_context.g.dart';

/// Contexto financiero anónimo para enviar al asistente IA
/// Solo contiene agregados, nunca transacciones individuales
@freezed
class FinancialContext with _$FinancialContext {
  const factory FinancialContext({
    required String period,
    required FinancialSummary summary,
    required Map<String, CategoryExpenseContext> expensesByCategory,
    required List<AccountContext> accounts,
    @Default('COP') String currency,
  }) = _FinancialContext;

  factory FinancialContext.fromJson(Map<String, dynamic> json) =>
      _$FinancialContextFromJson(json);
}

@freezed
class FinancialSummary with _$FinancialSummary {
  const factory FinancialSummary({
    required double totalIncome,
    required double totalExpenses,
    required double balance,
    required double netWorth,
    required double totalAssets,
    required double totalLiabilities,
  }) = _FinancialSummary;

  factory FinancialSummary.fromJson(Map<String, dynamic> json) =>
      _$FinancialSummaryFromJson(json);
}

@freezed
class CategoryExpenseContext with _$CategoryExpenseContext {
  const factory CategoryExpenseContext({
    required double total,
    required Map<String, double> subcategories,
  }) = _CategoryExpenseContext;

  factory CategoryExpenseContext.fromJson(Map<String, dynamic> json) =>
      _$CategoryExpenseContextFromJson(json);
}

@freezed
class AccountContext with _$AccountContext {
  const factory AccountContext({
    required String name,
    required String type,
    required double balance,
  }) = _AccountContext;

  factory AccountContext.fromJson(Map<String, dynamic> json) =>
      _$AccountContextFromJson(json);
}

/// Mensaje de chat con el asistente
@freezed
class ChatMessage with _$ChatMessage {
  const factory ChatMessage({
    required String id,
    required String content,
    required ChatRole role,
    required DateTime timestamp,
    @Default(false) bool isLoading,
    String? error,
  }) = _ChatMessage;

  factory ChatMessage.fromJson(Map<String, dynamic> json) =>
      _$ChatMessageFromJson(json);
}

enum ChatRole {
  user,
  assistant,
}
