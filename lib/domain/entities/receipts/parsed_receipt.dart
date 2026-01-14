import 'package:freezed_annotation/freezed_annotation.dart';

part 'parsed_receipt.freezed.dart';
part 'parsed_receipt.g.dart';

/// Resultado del parsing de una factura/recibo
@freezed
class ParsedReceipt with _$ParsedReceipt {
  const factory ParsedReceipt({
    /// Monto total extraído
    required double amount,

    /// Nombre del comercio/establecimiento
    String? merchant,

    /// Fecha de la factura (si se pudo extraer)
    DateTime? date,

    /// Categoría sugerida basada en el comercio
    String? suggestedCategory,

    /// Texto crudo extraído por OCR
    required String rawText,

    /// Fuente del parsing: 'regex' o 'ai'
    required String parseSource,

    /// Confianza del parsing (0.0 - 1.0)
    @Default(1.0) double confidence,
  }) = _ParsedReceipt;

  factory ParsedReceipt.fromJson(Map<String, dynamic> json) =>
      _$ParsedReceiptFromJson(json);
}

/// Resultado del escaneo de factura (incluye imagen)
@freezed
class ReceiptScanResult with _$ReceiptScanResult {
  const factory ReceiptScanResult.success({
    required ParsedReceipt receipt,
  }) = ReceiptScanSuccess;

  const factory ReceiptScanResult.needsAI({
    required String rawText,
  }) = ReceiptScanNeedsAI;

  const factory ReceiptScanResult.failed({
    required String error,
  }) = ReceiptScanFailed;

  factory ReceiptScanResult.fromJson(Map<String, dynamic> json) =>
      _$ReceiptScanResultFromJson(json);
}
