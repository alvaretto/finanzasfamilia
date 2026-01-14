import 'dart:io';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../entities/receipts/parsed_receipt.dart';
import 'receipt_parser_service.dart';

/// Servicio que coordina el escaneo de facturas:
/// 1. Captura imagen (cámara o galería)
/// 2. Extrae texto con ML Kit OCR
/// 3. Intenta parsear con regex (ReceiptParserService)
/// 4. Si regex falla, usa Claude Haiku via Edge Function
class ReceiptScannerService {
  final ImagePicker _imagePicker;
  final ReceiptParserService _parserService;
  final SupabaseClient _supabaseClient;
  final TextRecognizer _textRecognizer;

  ReceiptScannerService({
    required ImagePicker imagePicker,
    required ReceiptParserService parserService,
    required SupabaseClient supabaseClient,
    TextRecognizer? textRecognizer,
  })  : _imagePicker = imagePicker,
        _parserService = parserService,
        _supabaseClient = supabaseClient,
        _textRecognizer = textRecognizer ?? TextRecognizer();

  /// Escanea una factura desde la cámara
  Future<ReceiptScanResult> scanFromCamera() async {
    final image = await _imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    if (image == null) {
      return const ReceiptScanResult.failed(error: 'No se capturó imagen');
    }
    return _processImage(File(image.path));
  }

  /// Escanea una factura desde la galería
  Future<ReceiptScanResult> scanFromGallery() async {
    final image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (image == null) {
      return const ReceiptScanResult.failed(error: 'No se seleccionó imagen');
    }
    return _processImage(File(image.path));
  }

  /// Procesa una imagen de factura
  Future<ReceiptScanResult> _processImage(File imageFile) async {
    try {
      // 1. OCR con ML Kit
      final inputImage = InputImage.fromFile(imageFile);
      final recognizedText = await _textRecognizer.processImage(inputImage);
      final ocrText = recognizedText.text;

      if (ocrText.trim().isEmpty) {
        return const ReceiptScanResult.failed(
          error: 'No se pudo leer texto de la imagen',
        );
      }

      // 2. Intentar parsing con regex
      final regexResult = _parserService.parse(ocrText);

      if (regexResult != null && regexResult.confidence >= 0.5) {
        // Regex tuvo éxito con buena confianza
        return ReceiptScanResult.success(receipt: regexResult);
      }

      // 3. Regex falló o baja confianza, usar Haiku
      final aiResult = await _parseWithAI(ocrText);
      if (aiResult != null) {
        return ReceiptScanResult.success(receipt: aiResult);
      }

      // 4. Todo falló
      return ReceiptScanResult.needsAI(rawText: ocrText);
    } catch (e) {
      return ReceiptScanResult.failed(error: 'Error procesando imagen: $e');
    }
  }

  /// Parsea texto de factura usando Claude Haiku via Edge Function
  Future<ParsedReceipt?> _parseWithAI(String ocrText) async {
    try {
      final response = await _supabaseClient.functions.invoke(
        'ai-chat',
        body: {
          'mode': 'receipt-parse',
          'ocr_text': ocrText,
        },
      );

      if (response.status != 200) return null;

      final data = response.data as Map<String, dynamic>;
      if (data['success'] != true) return null;

      return ParsedReceipt(
        amount: (data['amount'] as num).toDouble(),
        merchant: data['merchant'] as String?,
        date: data['date'] != null ? DateTime.tryParse(data['date']) : null,
        suggestedCategory: data['category'] as String?,
        rawText: ocrText,
        parseSource: 'ai',
        confidence: (data['confidence'] as num?)?.toDouble() ?? 0.8,
      );
    } catch (e) {
      return null;
    }
  }

  /// Libera recursos del text recognizer
  void dispose() {
    _textRecognizer.close();
  }
}
