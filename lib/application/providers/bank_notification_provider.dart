import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notification_listener_service/notification_event.dart';
import 'package:notification_listener_service/notification_listener_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/parsers/bank_notification_parser.dart';
import '../../domain/entities/notifications/bank_notification.dart';
import '../../domain/services/bank_notification_service.dart';

/// Provider para el coordinador de parsers
final bankNotificationParserProvider = Provider<BankNotificationParserCoordinator>((ref) {
  return BankNotificationParserCoordinator();
});

/// Provider para verificar si el permiso está concedido
final notificationPermissionProvider = FutureProvider<bool>((ref) async {
  if (!Platform.isAndroid) return false;
  return NotificationListenerService.isPermissionGranted();
});

/// Provider para el servicio de notificaciones bancarias
final bankNotificationServiceProvider = Provider<BankNotificationService>((ref) {
  final pendingRepo = ref.watch(_pendingTransactionRepositoryProvider);
  final merchantRepo = ref.watch(_merchantCategoryRepositoryProvider);

  return BankNotificationService(
    pendingRepository: pendingRepo,
    merchantRepository: merchantRepo,
  );
});

/// Provider para las transacciones pendientes
final pendingBankTransactionsProvider =
    AsyncNotifierProvider<PendingBankTransactionsNotifier, List<PendingBankTransaction>>(
  PendingBankTransactionsNotifier.new,
);

/// Notifier para gestionar transacciones pendientes
class PendingBankTransactionsNotifier extends AsyncNotifier<List<PendingBankTransaction>> {
  StreamSubscription<ServiceNotificationEvent>? _subscription;

  @override
  Future<List<PendingBankTransaction>> build() async {
    ref.onDispose(() {
      _subscription?.cancel();
    });

    // Iniciar escucha de notificaciones si tenemos permiso
    if (Platform.isAndroid) {
      final hasPermission = await NotificationListenerService.isPermissionGranted();
      if (hasPermission) {
        _startListening();
      }
    }

    // Cargar transacciones pendientes existentes
    final service = ref.read(bankNotificationServiceProvider);
    return service.getPendingTransactions();
  }

  void _startListening() {
    _subscription?.cancel();
    _subscription = NotificationListenerService.notificationsStream.listen(
      _onNotificationReceived,
      onError: (e) => debugPrint('[BankNotification] Stream error: $e'),
    );
  }

  Future<void> _onNotificationReceived(ServiceNotificationEvent event) async {
    final parser = ref.read(bankNotificationParserProvider);

    // Verificar si es de un banco soportado
    final packageName = event.packageName ?? '';
    if (!parser.isSupportedBank(packageName)) return;

    // Convertir a RawBankNotification
    final raw = RawBankNotification(
      id: '${event.packageName}_${DateTime.now().millisecondsSinceEpoch}',
      packageName: packageName,
      title: event.title ?? '',
      text: event.content ?? '',
      bigText: event.content ?? '', // El plugin no distingue bigText
      timestamp: DateTime.now(),
    );

    // Parsear
    final parsed = parser.parse(raw);
    if (parsed == null) return;

    // Procesar y guardar
    final service = ref.read(bankNotificationServiceProvider);
    final pending = await service.processNotification(parsed);

    if (pending != null) {
      // Actualizar estado
      state = AsyncData([...state.value ?? [], pending]);
    }
  }

  /// Confirma una transacción pendiente
  Future<void> confirm(
    String notificationId, {
    required String categoryId,
    required String accountId,
  }) async {
    final service = ref.read(bankNotificationServiceProvider);
    final current = state.value ?? [];

    final transaction = current.firstWhere(
      (t) => t.parsed.notificationId == notificationId,
    );

    await service.confirmTransaction(
      notificationId,
      categoryId: categoryId,
      accountId: accountId,
      merchant: transaction.parsed.merchant,
    );

    // Remover de pendientes
    state = AsyncData(
      current.where((t) => t.parsed.notificationId != notificationId).toList(),
    );
  }

  /// Ignora una transacción pendiente
  Future<void> ignore(String notificationId) async {
    final service = ref.read(bankNotificationServiceProvider);
    await service.ignoreTransaction(notificationId);

    final current = state.value ?? [];
    state = AsyncData(
      current.where((t) => t.parsed.notificationId != notificationId).toList(),
    );
  }

  /// Solicita permiso de notificaciones
  Future<bool> requestPermission() async {
    if (!Platform.isAndroid) return false;

    final granted = await NotificationListenerService.requestPermission();
    if (granted) {
      _startListening();
    }
    return granted;
  }

  /// Recarga las transacciones pendientes
  Future<void> refresh() async {
    final service = ref.read(bankNotificationServiceProvider);
    state = AsyncData(await service.getPendingTransactions());
  }
}

/// Provider para estadísticas
final notificationStatsProvider = FutureProvider<NotificationStats>((ref) async {
  final service = ref.watch(bankNotificationServiceProvider);
  return service.getStats();
});

// ============================================================================
// Implementaciones de repositorios (usando SharedPreferences por simplicidad)
// ============================================================================

final _pendingTransactionRepositoryProvider = Provider<PendingTransactionRepository>((ref) {
  return SharedPrefsPendingTransactionRepository();
});

final _merchantCategoryRepositoryProvider = Provider<MerchantCategoryRepository>((ref) {
  return SharedPrefsMerchantCategoryRepository();
});

/// Implementación simple con SharedPreferences
class SharedPrefsPendingTransactionRepository implements PendingTransactionRepository {
  @override
  Future<List<PendingBankTransaction>> getPending() async {
    // Por simplicidad, no persistimos las pendientes entre sesiones
    // En una implementación real usaríamos Drift
    return _inMemory.values
        .where((t) => t.status == PendingTransactionStatus.pending)
        .toList();
  }

  final _inMemory = <String, PendingBankTransaction>{};

  @override
  Future<void> save(PendingBankTransaction transaction) async {
    _inMemory[transaction.parsed.notificationId] = transaction;
  }

  @override
  Future<void> updateStatus(String notificationId, PendingTransactionStatus status) async {
    final existing = _inMemory[notificationId];
    if (existing != null) {
      _inMemory[notificationId] = PendingBankTransaction(
        parsed: existing.parsed,
        status: status,
        suggestedCategoryId: existing.suggestedCategoryId,
        suggestedAccountId: existing.suggestedAccountId,
        processedAt: status == PendingTransactionStatus.confirmed ? DateTime.now() : null,
      );
    }
  }

  @override
  Future<void> markAsProcessed(String notificationId, String transactionId) async {
    _inMemory.remove(notificationId);
  }

  @override
  Future<bool> exists(String notificationId) async {
    return _inMemory.containsKey(notificationId);
  }
}

/// Implementación de matching con SharedPreferences
class SharedPrefsMerchantCategoryRepository implements MerchantCategoryRepository {
  static const _merchantPrefix = 'merchant_category_';
  static const _bankPrefix = 'bank_account_';

  @override
  Future<String?> getCategoryForMerchant(String merchant) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('$_merchantPrefix$merchant');
  }

  @override
  Future<void> saveMerchantCategory(String merchant, String categoryId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_merchantPrefix$merchant', categoryId);
  }

  @override
  Future<String?> getAccountForBank(ColombianBank bank) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('$_bankPrefix${bank.name}');
  }

  @override
  Future<void> saveBankAccount(ColombianBank bank, String accountId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_bankPrefix${bank.name}', accountId);
  }
}
