import 'package:uuid/uuid.dart';

import '../exceptions/accounting_exceptions.dart';
import '../repositories/repositories.dart';

/// Servicio de Contabilidad - Motor de Partida Doble
///
/// El usuario ve un formulario simple, pero el sistema escribe
/// registros de Contabilidad de Partida Doble automáticamente.
///
/// Reglas:
/// - DÉBITO (Dr) = Lo que ENTRA o AUMENTA
/// - CRÉDITO (Cr) = Lo que SALE o DISMINUYE
///
/// NOTA: Este servicio usa interfaces de repositorio (Clean Architecture).
/// No depende de Drift ni de ninguna implementación concreta.
class AccountingService {
  final AccountRepository accountRepository;
  final TransactionRepository transactionRepository;
  final JournalEntryRepository journalEntryRepository;
  final CategoryRepository categoryRepository;
  final TransactionExecutor transactionExecutor;

  static const _uuid = Uuid();

  AccountingService({
    required this.accountRepository,
    required this.transactionRepository,
    required this.journalEntryRepository,
    required this.categoryRepository,
    required this.transactionExecutor,
  });

  /// Registra un gasto con partida doble
  /// - Débito en la categoría de gasto
  /// - Crédito en la cuenta de pago (activo)
  ///
  /// Throws [InsufficientFundsException] si la cuenta de activo líquido
  /// no tiene saldo suficiente.
  Future<TransactionData> recordExpense({
    required String categoryId,
    required String paymentAccountId,
    required double amount,
    required String description,
    required DateTime date,
  }) async {
    _validateAmount(amount);
    await _validateAccountExists(paymentAccountId);
    await _validateSufficientFunds(paymentAccountId, amount);

    final transactionId = _uuid.v4();
    final now = DateTime.now();

    return transactionExecutor.execute(() async {
      // 1. Crear transacción
      final transaction = _buildTransaction(
        id: transactionId,
        type: 'expense',
        amount: amount,
        description: description,
        categoryId: categoryId,
        fromAccountId: paymentAccountId,
        date: date,
        now: now,
      );
      await transactionRepository.insertTransaction(transaction);

      // 2. Crear asientos contables (Partida Doble)
      await _createJournalEntries(
        transactionId: transactionId,
        debitId: categoryId,
        debitIsAccount: false,
        creditId: paymentAccountId,
        creditIsAccount: true,
        amount: amount,
        description: description,
        date: date,
        now: now,
      );

      // 3. Actualizar saldo de cuenta de pago
      await _updateAccountBalance(paymentAccountId, -amount);

      return transaction;
    });
  }

  /// Registra un ingreso con partida doble
  /// - Débito en la cuenta destino (activo)
  /// - Crédito en la categoría de ingreso
  Future<TransactionData> recordIncome({
    required String categoryId,
    required String destinationAccountId,
    required double amount,
    required String description,
    required DateTime date,
  }) async {
    _validateAmount(amount);
    await _validateAccountExists(destinationAccountId);

    final transactionId = _uuid.v4();
    final now = DateTime.now();

    return transactionExecutor.execute(() async {
      // 1. Crear transacción
      final transaction = _buildTransaction(
        id: transactionId,
        type: 'income',
        amount: amount,
        description: description,
        categoryId: categoryId,
        toAccountId: destinationAccountId,
        date: date,
        now: now,
      );
      await transactionRepository.insertTransaction(transaction);

      // 2. Crear asientos contables
      await _createJournalEntries(
        transactionId: transactionId,
        debitId: destinationAccountId,
        debitIsAccount: true,
        creditId: categoryId,
        creditIsAccount: false,
        amount: amount,
        description: description,
        date: date,
        now: now,
      );

      // 3. Actualizar saldo de cuenta destino
      await _updateAccountBalance(destinationAccountId, amount);

      return transaction;
    });
  }

  /// Registra una transferencia entre cuentas
  /// - Débito en cuenta destino (aumenta)
  /// - Crédito en cuenta origen (disminuye)
  ///
  /// Throws [InsufficientFundsException] si la cuenta origen es un activo
  /// líquido y no tiene saldo suficiente.
  Future<TransactionData> recordTransfer({
    required String fromAccountId,
    required String toAccountId,
    required double amount,
    required String description,
    required DateTime date,
  }) async {
    _validateAmount(amount);
    await _validateAccountExists(fromAccountId);
    await _validateAccountExists(toAccountId);
    await _validateSufficientFunds(fromAccountId, amount);

    final transactionId = _uuid.v4();
    final now = DateTime.now();
    final transferCategoryId = await _getOrCreateTransferCategory();

    return transactionExecutor.execute(() async {
      // 1. Crear transacción
      final transaction = _buildTransaction(
        id: transactionId,
        type: 'transfer',
        amount: amount,
        description: description,
        categoryId: transferCategoryId,
        fromAccountId: fromAccountId,
        toAccountId: toAccountId,
        date: date,
        now: now,
      );
      await transactionRepository.insertTransaction(transaction);

      // 2. Crear asientos contables
      await _createJournalEntries(
        transactionId: transactionId,
        debitId: toAccountId,
        debitIsAccount: true,
        creditId: fromAccountId,
        creditIsAccount: true,
        amount: amount,
        description: description,
        date: date,
        now: now,
      );

      // 3. Actualizar saldos
      await _updateAccountBalance(fromAccountId, -amount);
      await _updateAccountBalance(toAccountId, amount);

      return transaction;
    });
  }

  /// Registra un pago de pasivo (ej: pago de tarjeta de crédito)
  /// - Débito en el pasivo (disminuye la deuda)
  /// - Crédito en el activo (disminuye el saldo)
  ///
  /// Throws [InsufficientFundsException] si la cuenta de pago es un activo
  /// líquido y no tiene saldo suficiente.
  Future<TransactionData> recordLiabilityPayment({
    required String liabilityAccountId,
    required String paymentAccountId,
    required double amount,
    required String description,
    required DateTime date,
  }) async {
    _validateAmount(amount);
    await _validateAccountExists(liabilityAccountId);
    await _validateAccountExists(paymentAccountId);
    await _validateSufficientFunds(paymentAccountId, amount);

    final transactionId = _uuid.v4();
    final now = DateTime.now();
    final paymentCategoryId = await _getOrCreateLiabilityPaymentCategory();

    return transactionExecutor.execute(() async {
      // 1. Crear transacción
      final transaction = _buildTransaction(
        id: transactionId,
        type: 'liability_payment',
        amount: amount,
        description: description,
        categoryId: paymentCategoryId,
        fromAccountId: paymentAccountId,
        toAccountId: liabilityAccountId,
        date: date,
        now: now,
      );
      await transactionRepository.insertTransaction(transaction);

      // 2. Crear asientos contables
      await _createJournalEntries(
        transactionId: transactionId,
        debitId: liabilityAccountId,
        debitIsAccount: true,
        creditId: paymentAccountId,
        creditIsAccount: true,
        amount: amount,
        description: description,
        date: date,
        now: now,
      );

      // 3. Actualizar saldos
      await _updateAccountBalance(liabilityAccountId, amount);
      await _updateAccountBalance(paymentAccountId, -amount);

      return transaction;
    });
  }

  /// Obtiene el balance de una cuenta.
  Future<double> getAccountBalance(String accountId) async {
    final account = await accountRepository.getAccountById(accountId);
    if (account == null) {
      throw StateError('La cuenta no existe: $accountId');
    }
    return account.balance;
  }

  /// Elimina una transacción y revierte todos sus efectos contables.
  Future<void> deleteTransaction(String transactionId) async {
    return transactionExecutor.execute(() async {
      // 1. Obtener la transacción
      final transaction =
          await transactionRepository.getTransactionById(transactionId);
      if (transaction == null) {
        throw StateError('La transacción no existe: $transactionId');
      }

      // 2. Revertir cambios de balance según el tipo
      await _revertBalanceChanges(transaction);

      // 3. Eliminar asientos contables
      await journalEntryRepository.deleteEntriesByTransaction(transactionId);

      // 4. Eliminar la transacción
      await transactionRepository.deleteTransaction(transactionId);
    });
  }

  /// Obtiene una transacción por ID.
  Future<TransactionData?> getTransactionById(String transactionId) {
    return transactionRepository.getTransactionById(transactionId);
  }

  /// Actualiza una transacción existente.
  Future<TransactionData> updateTransaction({
    required String transactionId,
    required String type,
    required String categoryId,
    required double amount,
    required String description,
    required DateTime date,
    String? fromAccountId,
    String? toAccountId,
  }) async {
    return transactionExecutor.execute(() async {
      // 1. Obtener la transacción original
      final original = await getTransactionById(transactionId);
      if (original == null) {
        throw StateError('La transacción no existe: $transactionId');
      }

      // 2. Revertir los efectos de la transacción original
      await _revertBalanceChanges(original);

      // 3. Eliminar asientos contables antiguos
      await journalEntryRepository.deleteEntriesByTransaction(transactionId);

      // 4. Eliminar la transacción original
      await transactionRepository.deleteTransaction(transactionId);

      // 5. Crear nueva transacción con los datos actualizados
      switch (type) {
        case 'expense':
          return recordExpense(
            categoryId: categoryId,
            paymentAccountId: fromAccountId!,
            amount: amount,
            description: description,
            date: date,
          );
        case 'income':
          return recordIncome(
            categoryId: categoryId,
            destinationAccountId: toAccountId!,
            amount: amount,
            description: description,
            date: date,
          );
        case 'transfer':
          return recordTransfer(
            fromAccountId: fromAccountId!,
            toAccountId: toAccountId!,
            amount: amount,
            description: description,
            date: date,
          );
        case 'liability_payment':
          return recordLiabilityPayment(
            liabilityAccountId: toAccountId!,
            paymentAccountId: fromAccountId!,
            amount: amount,
            description: description,
            date: date,
          );
        default:
          throw ArgumentError('Tipo de transacción no soportado: $type');
      }
    });
  }

  // ============================================================
  // Métodos privados auxiliares
  // ============================================================

  void _validateAmount(double amount) {
    if (amount <= 0) {
      throw ArgumentError('El monto debe ser mayor a cero');
    }
  }

  Future<void> _validateAccountExists(String accountId) async {
    final exists = await accountRepository.accountExists(accountId);
    if (!exists) {
      throw StateError('La cuenta no existe: $accountId');
    }
  }

  /// Valida que una cuenta de activo líquido tenga saldo suficiente.
  /// Las cuentas de pasivo (tarjetas de crédito) no se validan.
  Future<void> _validateSufficientFunds(String accountId, double amount) async {
    final accountWithCategory =
        await accountRepository.getAccountWithCategoryById(accountId);
    if (accountWithCategory == null) {
      throw StateError('La cuenta no existe: $accountId');
    }

    // Solo validar activos líquidos (no pasivos)
    if (!accountWithCategory.isLiquidAsset) return;

    final available = accountWithCategory.account.balance;
    if (available < amount) {
      throw InsufficientFundsException(
        available: available,
        required: amount,
        accountName: accountWithCategory.account.name,
      );
    }
  }

  TransactionData _buildTransaction({
    required String id,
    required String type,
    required double amount,
    required String description,
    required String categoryId,
    String? fromAccountId,
    String? toAccountId,
    required DateTime date,
    required DateTime now,
  }) {
    return TransactionData(
      id: id,
      type: type,
      amount: amount,
      description: description,
      categoryId: categoryId,
      fromAccountId: fromAccountId,
      toAccountId: toAccountId,
      transactionDate: date,
      createdAt: now,
      updatedAt: now,
    );
  }

  Future<void> _createJournalEntries({
    required String transactionId,
    required String debitId,
    required bool debitIsAccount,
    required String creditId,
    required bool creditIsAccount,
    required double amount,
    required String description,
    required DateTime date,
    required DateTime now,
  }) async {
    final nextNumber = await journalEntryRepository.getNextEntryNumber();

    final entries = [
      // Asiento de Débito
      JournalEntryData(
        id: _uuid.v4(),
        transactionId: transactionId,
        accountId: debitIsAccount ? debitId : null,
        categoryId: debitIsAccount ? null : debitId,
        entryType: 'debit',
        amount: amount,
        description: description,
        entryNumber: nextNumber,
        entryDate: date,
        createdAt: now,
        updatedAt: now,
      ),
      // Asiento de Crédito
      JournalEntryData(
        id: _uuid.v4(),
        transactionId: transactionId,
        accountId: creditIsAccount ? creditId : null,
        categoryId: creditIsAccount ? null : creditId,
        entryType: 'credit',
        amount: amount,
        description: description,
        entryNumber: nextNumber + 1,
        entryDate: date,
        createdAt: now,
        updatedAt: now,
      ),
    ];

    await journalEntryRepository.insertEntries(entries);
  }

  Future<void> _updateAccountBalance(String accountId, double delta) async {
    final account = await accountRepository.getAccountById(accountId);
    if (account == null) {
      throw StateError('La cuenta no existe: $accountId');
    }
    await accountRepository.updateBalance(accountId, account.balance + delta);
  }

  Future<void> _revertBalanceChanges(TransactionData transaction) async {
    switch (transaction.type) {
      case 'expense':
        if (transaction.fromAccountId != null) {
          await _updateAccountBalance(transaction.fromAccountId!, transaction.amount);
        }
        break;

      case 'income':
        if (transaction.toAccountId != null) {
          await _updateAccountBalance(transaction.toAccountId!, -transaction.amount);
        }
        break;

      case 'transfer':
        if (transaction.fromAccountId != null) {
          await _updateAccountBalance(transaction.fromAccountId!, transaction.amount);
        }
        if (transaction.toAccountId != null) {
          await _updateAccountBalance(transaction.toAccountId!, -transaction.amount);
        }
        break;

      case 'liability_payment':
        if (transaction.toAccountId != null) {
          await _updateAccountBalance(transaction.toAccountId!, -transaction.amount);
        }
        if (transaction.fromAccountId != null) {
          await _updateAccountBalance(transaction.fromAccountId!, transaction.amount);
        }
        break;
    }
  }

  Future<String> _getOrCreateTransferCategory() async {
    const transferCategoryId = 'system-transfer';

    final existing = await categoryRepository.getCategoryById(transferCategoryId);
    if (existing != null) return transferCategoryId;

    final now = DateTime.now();
    await categoryRepository.insertCategory(CategoryData(
      id: transferCategoryId,
      name: 'Transferencias',
      type: 'system',
      level: 0,
      isSystem: true,
      createdAt: now,
      updatedAt: now,
    ));

    return transferCategoryId;
  }

  Future<String> _getOrCreateLiabilityPaymentCategory() async {
    const paymentCategoryId = 'system-liability-payment';

    final existing = await categoryRepository.getCategoryById(paymentCategoryId);
    if (existing != null) return paymentCategoryId;

    final now = DateTime.now();
    await categoryRepository.insertCategory(CategoryData(
      id: paymentCategoryId,
      name: 'Pagos de Pasivos',
      type: 'system',
      level: 0,
      isSystem: true,
      createdAt: now,
      updatedAt: now,
    ));

    return paymentCategoryId;
  }
}

/// Interfaz para ejecutar operaciones en una transacción de base de datos.
/// Permite que el dominio solicite atomicidad sin conocer la implementación.
abstract class TransactionExecutor {
  /// Ejecuta una función dentro de una transacción atómica.
  Future<T> execute<T>(Future<T> Function() action);
}
