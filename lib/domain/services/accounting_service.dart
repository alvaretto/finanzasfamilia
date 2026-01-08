import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../data/local/database.dart';
import '../../data/local/daos/daos.dart';

/// Servicio de Contabilidad - Motor de Partida Doble
///
/// El usuario ve un formulario simple, pero el sistema escribe
/// registros de Contabilidad de Partida Doble automáticamente.
///
/// Reglas:
/// - DÉBITO (Dr) = Lo que ENTRA o AUMENTA
/// - CRÉDITO (Cr) = Lo que SALE o DISMINUYE
class AccountingService {
  final AppDatabase db;
  final TransactionsDao transactionsDao;
  final JournalEntriesDao journalEntriesDao;
  final CategoriesDao categoriesDao;

  static const _uuid = Uuid();

  AccountingService({
    required this.db,
    required this.transactionsDao,
    required this.journalEntriesDao,
    required this.categoriesDao,
  });

  /// Registra un gasto con partida doble
  /// - Débito en la categoría de gasto
  /// - Crédito en la cuenta de pago (activo)
  Future<TransactionEntry> recordExpense({
    required String categoryId,
    required String paymentAccountId,
    required double amount,
    required String description,
    required DateTime date,
  }) async {
    _validateAmount(amount);
    await _validateAccountExists(paymentAccountId);

    final transactionId = _uuid.v4();
    final now = DateTime.now();

    return db.transaction(() async {
      // 1. Crear transacción
      final transaction = await _createTransaction(
        id: transactionId,
        type: 'expense',
        amount: amount,
        description: description,
        categoryId: categoryId,
        fromAccountId: paymentAccountId,
        date: date,
        now: now,
      );

      // 2. Crear asientos contables (Partida Doble)
      // Gasto: Débito en categoría de gasto, Crédito en cuenta de pago
      await _createJournalEntries(
        transactionId: transactionId,
        debitId: categoryId,
        debitIsAccount: false, // Es una categoría
        creditId: paymentAccountId,
        creditIsAccount: true, // Es una cuenta
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
  Future<TransactionEntry> recordIncome({
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

    return db.transaction(() async {
      // 1. Crear transacción
      final transaction = await _createTransaction(
        id: transactionId,
        type: 'income',
        amount: amount,
        description: description,
        categoryId: categoryId,
        toAccountId: destinationAccountId,
        date: date,
        now: now,
      );

      // 2. Crear asientos contables
      // Ingreso: Débito en cuenta destino, Crédito en categoría de ingreso
      await _createJournalEntries(
        transactionId: transactionId,
        debitId: destinationAccountId,
        debitIsAccount: true, // Es una cuenta
        creditId: categoryId,
        creditIsAccount: false, // Es una categoría
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
  Future<TransactionEntry> recordTransfer({
    required String fromAccountId,
    required String toAccountId,
    required double amount,
    required String description,
    required DateTime date,
  }) async {
    _validateAmount(amount);
    await _validateAccountExists(fromAccountId);
    await _validateAccountExists(toAccountId);

    final transactionId = _uuid.v4();
    final now = DateTime.now();

    // Obtener categoría del sistema para transferencias
    final transferCategoryId = await _getOrCreateTransferCategory();

    return db.transaction(() async {
      // 1. Crear transacción
      final transaction = await _createTransaction(
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

      // 2. Crear asientos contables
      // Transferencia: Débito en cuenta destino, Crédito en cuenta origen
      await _createJournalEntries(
        transactionId: transactionId,
        debitId: toAccountId,
        debitIsAccount: true, // Ambas son cuentas
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
  Future<TransactionEntry> recordLiabilityPayment({
    required String liabilityAccountId,
    required String paymentAccountId,
    required double amount,
    required String description,
    required DateTime date,
  }) async {
    _validateAmount(amount);
    await _validateAccountExists(liabilityAccountId);
    await _validateAccountExists(paymentAccountId);

    final transactionId = _uuid.v4();
    final now = DateTime.now();

    // Obtener categoría del sistema para pagos de pasivos
    final paymentCategoryId = await _getOrCreateLiabilityPaymentCategory();

    return db.transaction(() async {
      // 1. Crear transacción
      final transaction = await _createTransaction(
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

      // 2. Crear asientos contables
      // Pago de pasivo: Débito en pasivo, Crédito en activo
      await _createJournalEntries(
        transactionId: transactionId,
        debitId: liabilityAccountId,
        debitIsAccount: true, // Ambas son cuentas
        creditId: paymentAccountId,
        creditIsAccount: true,
        amount: amount,
        description: description,
        date: date,
        now: now,
      );

      // 3. Actualizar saldos
      // El pasivo aumenta (se acerca a 0, ya que es negativo)
      await _updateAccountBalance(liabilityAccountId, amount);
      // El activo disminuye
      await _updateAccountBalance(paymentAccountId, -amount);

      return transaction;
    });
  }

  /// Obtiene el balance de una cuenta calculado desde asientos contables
  Future<double> getAccountBalance(String accountId) async {
    // Obtener saldo actual de la cuenta directamente
    final account = await (db.select(db.accounts)
          ..where((a) => a.id.equals(accountId)))
        .getSingle();
    return account.balance;
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
    final account = await (db.select(db.accounts)
          ..where((a) => a.id.equals(accountId)))
        .getSingleOrNull();

    if (account == null) {
      throw StateError('La cuenta no existe: $accountId');
    }
  }

  Future<TransactionEntry> _createTransaction({
    required String id,
    required String type,
    required double amount,
    required String description,
    required String categoryId,
    String? fromAccountId,
    String? toAccountId,
    required DateTime date,
    required DateTime now,
  }) async {
    final companion = TransactionsCompanion.insert(
      id: id,
      type: type,
      amount: amount,
      description: Value(description),
      categoryId: categoryId,
      fromAccountId: Value(fromAccountId),
      toAccountId: Value(toAccountId),
      transactionDate: date,
      createdAt: Value(now),
      updatedAt: Value(now),
    );

    await transactionsDao.insertTransaction(companion);

    return (db.select(db.transactions)..where((t) => t.id.equals(id)))
        .getSingle();
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
    final nextNumber = await journalEntriesDao.getNextEntryNumber();

    final entries = [
      // Asiento de Débito
      JournalEntriesCompanion(
        id: Value(_uuid.v4()),
        transactionId: Value(transactionId),
        accountId: debitIsAccount ? Value(debitId) : const Value(null),
        categoryId: debitIsAccount ? const Value(null) : Value(debitId),
        entryType: const Value('debit'),
        amount: Value(amount),
        description: Value(description),
        entryNumber: Value(nextNumber),
        entryDate: Value(date),
        createdAt: Value(now),
        updatedAt: Value(now),
      ),
      // Asiento de Crédito
      JournalEntriesCompanion(
        id: Value(_uuid.v4()),
        transactionId: Value(transactionId),
        accountId: creditIsAccount ? Value(creditId) : const Value(null),
        categoryId: creditIsAccount ? const Value(null) : Value(creditId),
        entryType: const Value('credit'),
        amount: Value(amount),
        description: Value(description),
        entryNumber: Value(nextNumber + 1),
        entryDate: Value(date),
        createdAt: Value(now),
        updatedAt: Value(now),
      ),
    ];

    await journalEntriesDao.insertEntries(entries);
  }

  Future<void> _updateAccountBalance(String accountId, double delta) async {
    final account = await (db.select(db.accounts)
          ..where((a) => a.id.equals(accountId)))
        .getSingle();

    await (db.update(db.accounts)..where((a) => a.id.equals(accountId))).write(
      AccountsCompanion(
        balance: Value(account.balance + delta),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<String> _getOrCreateTransferCategory() async {
    const transferCategoryId = 'system-transfer';

    final existing = await categoriesDao.getCategoryById(transferCategoryId);
    if (existing != null) return transferCategoryId;

    // Crear categoría del sistema para transferencias
    final now = DateTime.now();
    await db.into(db.categories).insert(
          CategoriesCompanion.insert(
            id: transferCategoryId,
            name: 'Transferencias',
            type: 'system',
            level: const Value(0),
            isSystem: const Value(true),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );

    return transferCategoryId;
  }

  Future<String> _getOrCreateLiabilityPaymentCategory() async {
    const paymentCategoryId = 'system-liability-payment';

    final existing = await categoriesDao.getCategoryById(paymentCategoryId);
    if (existing != null) return paymentCategoryId;

    // Crear categoría del sistema para pagos de pasivos
    final now = DateTime.now();
    await db.into(db.categories).insert(
          CategoriesCompanion.insert(
            id: paymentCategoryId,
            name: 'Pagos de Pasivos',
            type: 'system',
            level: const Value(0),
            isSystem: const Value(true),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );

    return paymentCategoryId;
  }
}
