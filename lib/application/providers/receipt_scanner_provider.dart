import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/receipts/parsed_receipt.dart' as domain;
import '../../domain/services/receipt_parser_service.dart';
import '../../domain/services/receipt_scanner_service.dart';

/// Provider para el servicio de parsing de facturas
final receiptParserServiceProvider = Provider<ReceiptParserService>((ref) {
  return ReceiptParserService();
});

/// Provider para el servicio de escaneo de facturas
final receiptScannerServiceProvider = Provider<ReceiptScannerService>((ref) {
  return ReceiptScannerService(
    imagePicker: ImagePicker(),
    parserService: ref.watch(receiptParserServiceProvider),
    supabaseClient: Supabase.instance.client,
  );
});

/// Estado del escaneo de facturas
sealed class ReceiptScanState {
  const ReceiptScanState();
}

class ReceiptScanIdle extends ReceiptScanState {
  const ReceiptScanIdle();
}

class ReceiptScanLoading extends ReceiptScanState {
  final String message;
  const ReceiptScanLoading(this.message);
}

class ReceiptScanSuccess extends ReceiptScanState {
  final domain.ParsedReceipt receipt;
  const ReceiptScanSuccess(this.receipt);
}

class ReceiptScanError extends ReceiptScanState {
  final String error;
  const ReceiptScanError(this.error);
}

/// Notifier para manejar el estado del escaneo
class ReceiptScanNotifier extends Notifier<ReceiptScanState> {
  @override
  ReceiptScanState build() => const ReceiptScanIdle();

  Future<void> scanFromCamera() async {
    state = const ReceiptScanLoading('Capturando imagen...');

    final scanner = ref.read(receiptScannerServiceProvider);
    final result = await scanner.scanFromCamera();

    _handleResult(result);
  }

  Future<void> scanFromGallery() async {
    state = const ReceiptScanLoading('Procesando imagen...');

    final scanner = ref.read(receiptScannerServiceProvider);
    final result = await scanner.scanFromGallery();

    _handleResult(result);
  }

  void _handleResult(domain.ReceiptScanResult result) {
    switch (result) {
      case domain.ReceiptScanSuccess(:final receipt):
        state = ReceiptScanSuccess(receipt);
      case domain.ReceiptScanNeedsAI(:final rawText):
        state = ReceiptScanError(
          'No se pudo extraer información. Texto detectado:\n$rawText',
        );
      case domain.ReceiptScanFailed(:final error):
        state = ReceiptScanError(error);
    }
  }

  void reset() {
    state = const ReceiptScanIdle();
  }
}

/// Provider del notifier de escaneo
final receiptScanNotifierProvider =
    NotifierProvider<ReceiptScanNotifier, ReceiptScanState>(
  ReceiptScanNotifier.new,
);
