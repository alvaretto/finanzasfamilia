// test/helpers/test_data_generators.dart
//
// Helper centralizado para generar datos de prueba con valores válidos garantizados.
// Previene anti-patrón de amount: i.toDouble() en loops que inician en 0.
//
// Ver documentación completa en:
// .claude/skills/testing/TEST_DATA_GENERATION.md

import 'package:finanzas_familiares/features/transactions/domain/models/transaction_model.dart';
import 'package:uuid/uuid.dart';

/// Genera una transacción de prueba con montos válidos garantizados
///
/// El [index] puede ser 0 o cualquier valor - se convierte automáticamente
/// a un monto válido usando (index + 1).
///
/// **Cálculo de monto**: `baseAmount * (index + 1) * multiplier`
///
/// **Ejemplo**:
/// ```dart
/// // Montos: 10, 20, 30, ...
/// for (int i = 0; i < 100; i++) {
///   final tx = generateTestTransaction(
///     index: i,
///     userId: 'user-1',
///     baseAmount: 10.0,
///   );
/// }
/// ```
///
/// **Parámetros**:
/// - [index] (required): Índice del loop (puede ser 0)
/// - [userId] (required): ID del usuario
/// - [accountId] (optional): ID de cuenta (default: 'default-account')
/// - [type] (optional): TransactionType (default: expense)
/// - [baseAmount] (optional): Monto base (default: 1.0)
/// - [multiplier] (optional): Multiplicador (default: 1.0)
/// - [description] (optional): Descripción
/// - [categoryId] (optional): ID de categoría
///
/// **Ver también**:
/// - [generateTestTransactionList] para generar listas completas
/// - [TestDataValidators] para validar datos generados
TransactionModel generateTestTransaction({
  required int index,
  required String userId,
  String? accountId,
  TransactionType type = TransactionType.expense,
  double baseAmount = 1.0,
  double multiplier = 1.0,
  String? description,
  String? categoryId,
}) {
  // Cálculo: baseAmount * (index + 1) * multiplier
  // Esto garantiza que incluso cuando index=0, amount >= baseAmount
  final amount = baseAmount * (index + 1) * multiplier;

  // Validación defensiva
  assert(amount > 0, 'Amount must be positive: $amount');
  assert(userId.isNotEmpty, 'userId cannot be empty');

  return TransactionModel(
    id: const Uuid().v4(),
    userId: userId,
    accountId: accountId ?? 'default-account',
    amount: amount,
    type: type,
    description: description ?? 'Test transaction $index',
    categoryId: categoryId,
    date: DateTime.now(),
  );
}

/// Genera lista completa de transacciones con montos válidos
///
/// **Ejemplo**:
/// ```dart
/// final txs = generateTestTransactionList(
///   count: 100,
///   userId: 'user-123',
///   baseAmount: 5.0,
///   type: TransactionType.expense,
/// );
///
/// // Usar en tests
/// for (final tx in txs) {
///   await repo.createTransaction(tx);
/// }
/// ```
///
/// **Parámetros**:
/// - [count] (required): Número de transacciones a generar
/// - [userId] (required): ID del usuario
/// - [accountId] (optional): ID de cuenta para todas las transacciones
/// - [startIndex] (optional): Índice inicial (default: 0)
/// - [baseAmount] (optional): Monto base (default: 1.0)
/// - [type] (optional): TransactionType (default: expense)
///
/// **Ver también**:
/// - [generateTestTransaction] para transacciones individuales
/// - [TestDataValidators.validateTransactionList] para validar la lista generada
List<TransactionModel> generateTestTransactionList({
  required int count,
  required String userId,
  String? accountId,
  int startIndex = 0,
  double baseAmount = 1.0,
  TransactionType type = TransactionType.expense,
}) {
  assert(count > 0, 'count must be positive');
  assert(userId.isNotEmpty, 'userId cannot be empty');

  return List.generate(count, (i) {
    return generateTestTransaction(
      index: startIndex + i,
      userId: userId,
      accountId: accountId,
      baseAmount: baseAmount,
      type: type,
    );
  });
}

/// Validadores para verificar que datos de prueba cumplen reglas de negocio
///
/// **Uso**:
/// ```dart
/// final tx = generateTestTransaction(index: 0, userId: 'u1');
/// TestDataValidators.validateTransaction(tx);  // Lanza error si inválido
///
/// final txs = generateTestTransactionList(count: 10, userId: 'u1');
/// TestDataValidators.validateTransactionList(txs);  // Valida lista completa
/// ```
class TestDataValidators {
  /// Valida que una transacción cumple reglas de negocio
  ///
  /// Lanza [ArgumentError] si:
  /// - amount <= 0
  /// - userId está vacío
  /// - accountId está vacío
  ///
  /// **Ejemplo**:
  /// ```dart
  /// final tx = TransactionModel(...);
  /// TestDataValidators.validateTransaction(tx);  // Throws si inválido
  /// ```
  static void validateTransaction(TransactionModel tx) {
    if (tx.amount <= 0) {
      throw ArgumentError(
        'Transaction amount must be > 0, got: ${tx.amount}',
      );
    }
    if (tx.userId.isEmpty) {
      throw ArgumentError('Transaction must have userId');
    }
    if (tx.accountId.isEmpty) {
      throw ArgumentError('Transaction must have accountId');
    }
  }

  /// Valida lista completa de transacciones
  ///
  /// Llama a [validateTransaction] para cada transacción en la lista.
  /// Lanza [ArgumentError] si alguna transacción es inválida.
  ///
  /// **Ejemplo**:
  /// ```dart
  /// final txs = generateTestTransactionList(count: 100, userId: 'u1');
  /// TestDataValidators.validateTransactionList(txs);  // Throws si alguna inválida
  /// ```
  static void validateTransactionList(List<TransactionModel> txs) {
    for (final tx in txs) {
      validateTransaction(tx);
    }
  }
}
