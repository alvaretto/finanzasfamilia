import '../entities/notifications/bank_notification.dart';

/// Repositorio para persistir transacciones pendientes de notificaciones
abstract class PendingTransactionRepository {
  Future<List<PendingBankTransaction>> getPending();
  Future<void> save(PendingBankTransaction transaction);
  Future<void> updateStatus(String notificationId, PendingTransactionStatus status);
  Future<void> markAsProcessed(String notificationId, String transactionId);
  Future<bool> exists(String notificationId);
}

/// Repositorio para patrones de matching aprendidos
abstract class MerchantCategoryRepository {
  /// Obtiene la categoría sugerida para un comercio
  Future<String?> getCategoryForMerchant(String merchant);

  /// Guarda el mapping comercio -> categoría
  Future<void> saveMerchantCategory(String merchant, String categoryId);

  /// Obtiene la cuenta sugerida para un banco
  Future<String?> getAccountForBank(ColombianBank bank);

  /// Guarda el mapping banco -> cuenta
  Future<void> saveBankAccount(ColombianBank bank, String accountId);
}

/// Servicio de dominio para gestión de notificaciones bancarias
class BankNotificationService {
  final PendingTransactionRepository _pendingRepo;
  final MerchantCategoryRepository _merchantRepo;

  BankNotificationService({
    required PendingTransactionRepository pendingRepository,
    required MerchantCategoryRepository merchantRepository,
  })  : _pendingRepo = pendingRepository,
        _merchantRepo = merchantRepository;

  /// Procesa una transacción parseada y la guarda como pendiente
  Future<PendingBankTransaction?> processNotification(
    ParsedBankTransaction parsed,
  ) async {
    // Verificar si ya existe (deduplicación)
    if (await _pendingRepo.exists(parsed.notificationId)) {
      return null;
    }

    // Buscar sugerencias de categoría y cuenta
    String? suggestedCategoryId;
    String? suggestedAccountId;

    if (parsed.merchant != null) {
      suggestedCategoryId = await _merchantRepo.getCategoryForMerchant(
        _normalizeMerchant(parsed.merchant!),
      );
    }

    suggestedAccountId = await _merchantRepo.getAccountForBank(parsed.bank);

    final pending = PendingBankTransaction(
      parsed: parsed,
      status: PendingTransactionStatus.pending,
      suggestedCategoryId: suggestedCategoryId,
      suggestedAccountId: suggestedAccountId,
    );

    await _pendingRepo.save(pending);
    return pending;
  }

  /// Obtiene todas las transacciones pendientes de confirmación
  Future<List<PendingBankTransaction>> getPendingTransactions() {
    return _pendingRepo.getPending();
  }

  /// Confirma una transacción (el usuario la acepta)
  Future<void> confirmTransaction(
    String notificationId, {
    required String categoryId,
    required String accountId,
    String? merchant,
  }) async {
    await _pendingRepo.updateStatus(
      notificationId,
      PendingTransactionStatus.confirmed,
    );

    // Guardar el matching para futuras transacciones
    if (merchant != null) {
      await _merchantRepo.saveMerchantCategory(
        _normalizeMerchant(merchant),
        categoryId,
      );
    }
  }

  /// Ignora una transacción (el usuario la descarta)
  Future<void> ignoreTransaction(String notificationId) {
    return _pendingRepo.updateStatus(
      notificationId,
      PendingTransactionStatus.ignored,
    );
  }

  /// Marca una transacción como procesada (ya se creó en el sistema)
  Future<void> markAsProcessed(String notificationId, String transactionId) {
    return _pendingRepo.markAsProcessed(notificationId, transactionId);
  }

  /// Guarda el mapping banco -> cuenta para futuras sugerencias
  Future<void> learnBankAccount(ColombianBank bank, String accountId) {
    return _merchantRepo.saveBankAccount(bank, accountId);
  }

  /// Normaliza el nombre del comercio para matching
  String _normalizeMerchant(String merchant) {
    return merchant
        .toUpperCase()
        .replaceAll(RegExp(r'[^A-Z0-9\s]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Calcula estadísticas de notificaciones procesadas
  Future<NotificationStats> getStats() async {
    final pending = await _pendingRepo.getPending();

    var totalPending = 0;
    var totalConfirmed = 0;
    var totalIgnored = 0;
    var totalAmount = 0.0;

    for (final tx in pending) {
      switch (tx.status) {
        case PendingTransactionStatus.pending:
          totalPending++;
          totalAmount += tx.parsed.amount;
        case PendingTransactionStatus.confirmed:
        case PendingTransactionStatus.autoConfirmed:
          totalConfirmed++;
        case PendingTransactionStatus.ignored:
          totalIgnored++;
      }
    }

    return NotificationStats(
      pendingCount: totalPending,
      confirmedCount: totalConfirmed,
      ignoredCount: totalIgnored,
      pendingAmount: totalAmount,
    );
  }
}

/// Estadísticas de notificaciones
class NotificationStats {
  final int pendingCount;
  final int confirmedCount;
  final int ignoredCount;
  final double pendingAmount;

  const NotificationStats({
    required this.pendingCount,
    required this.confirmedCount,
    required this.ignoredCount,
    required this.pendingAmount,
  });

  int get totalProcessed => confirmedCount + ignoredCount;
}
