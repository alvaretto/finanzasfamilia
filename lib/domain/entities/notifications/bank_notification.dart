import 'package:freezed_annotation/freezed_annotation.dart';

part 'bank_notification.freezed.dart';
part 'bank_notification.g.dart';

/// Banco colombiano reconocido
enum ColombianBank {
  bancolombia('Bancolombia', ['com.bancolombia', 'co.com.bancolombia']),
  nequi('Nequi', ['com.nequi']),
  daviplata('DaviPlata', ['com.davivienda.daviplata', 'co.com.davivienda.daviplata']),
  davivienda('Davivienda', ['com.davivienda.personas', 'com.davivienda']),
  unknown('Desconocido', []);

  final String displayName;
  final List<String> packagePrefixes;

  const ColombianBank(this.displayName, this.packagePrefixes);

  /// Detecta el banco a partir del package name
  static ColombianBank fromPackage(String packageName) {
    for (final bank in ColombianBank.values) {
      if (bank.packagePrefixes.any((prefix) => packageName.startsWith(prefix))) {
        return bank;
      }
    }
    return ColombianBank.unknown;
  }
}

/// Tipo de transacción detectada en la notificación
enum NotificationTransactionType {
  expense, // Compra, pago, retiro
  income, // Transferencia recibida, consignación
  transfer, // Transferencia enviada (a otra cuenta propia)
  unknown,
}

/// Notificación bancaria raw (antes de parsear)
@freezed
class RawBankNotification with _$RawBankNotification {
  const factory RawBankNotification({
    required String id,
    required String packageName,
    required String title,
    required String text,
    required String bigText,
    required DateTime timestamp,
  }) = _RawBankNotification;

  factory RawBankNotification.fromJson(Map<String, dynamic> json) =>
      _$RawBankNotificationFromJson(json);
}

/// Transacción parseada de una notificación bancaria
@freezed
class ParsedBankTransaction with _$ParsedBankTransaction {
  const factory ParsedBankTransaction({
    required String notificationId,
    required ColombianBank bank,
    required NotificationTransactionType type,
    required double amount,
    required DateTime timestamp,
    String? merchant, // Comercio o persona
    String? accountLastDigits, // Últimos 4 dígitos de cuenta/tarjeta
    String? rawText, // Texto original para debug
    @Default(false) bool isProcessed, // Ya se creó transacción
    @Default(false) bool isIgnored, // Usuario lo ignoró
  }) = _ParsedBankTransaction;

  factory ParsedBankTransaction.fromJson(Map<String, dynamic> json) =>
      _$ParsedBankTransactionFromJson(json);
}

/// Estado de una transacción pendiente de confirmación
enum PendingTransactionStatus {
  pending, // Esperando confirmación del usuario
  confirmed, // Usuario confirmó, crear transacción
  ignored, // Usuario ignoró
  autoConfirmed, // Auto-confirmado por configuración
}

/// Transacción pendiente de confirmación por el usuario
@freezed
class PendingBankTransaction with _$PendingBankTransaction {
  const factory PendingBankTransaction({
    required ParsedBankTransaction parsed,
    required PendingTransactionStatus status,
    String? suggestedCategoryId, // Categoría sugerida por matching
    String? suggestedAccountId, // Cuenta sugerida por matching
    DateTime? processedAt,
  }) = _PendingBankTransaction;

  factory PendingBankTransaction.fromJson(Map<String, dynamic> json) =>
      _$PendingBankTransactionFromJson(json);
}
