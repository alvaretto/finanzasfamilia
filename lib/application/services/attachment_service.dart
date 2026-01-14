import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

/// Resultado del procesamiento OCR
class OcrResult {
  final String fullText;
  final double? detectedAmount;
  final List<String> allAmounts;

  const OcrResult({
    required this.fullText,
    this.detectedAmount,
    this.allAmounts = const [],
  });
}

/// Resultado de captura de imagen
class CapturedImage {
  final String localPath;
  final String fileName;
  final String mimeType;
  final int fileSize;

  const CapturedImage({
    required this.localPath,
    required this.fileName,
    required this.mimeType,
    required this.fileSize,
  });
}

/// Servicio para gestionar adjuntos de transacciones
class AttachmentService {
  final ImagePicker _imagePicker;
  final TextRecognizer _textRecognizer;

  AttachmentService({
    ImagePicker? imagePicker,
    TextRecognizer? textRecognizer,
  })  : _imagePicker = imagePicker ?? ImagePicker(),
        _textRecognizer = textRecognizer ??
            TextRecognizer(script: TextRecognitionScript.latin);

  /// Captura una imagen desde la cámara
  Future<CapturedImage?> captureFromCamera() async {
    return _pickImage(ImageSource.camera);
  }

  /// Selecciona una imagen desde la galería
  Future<CapturedImage?> pickFromGallery() async {
    return _pickImage(ImageSource.gallery);
  }

  Future<CapturedImage?> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (pickedFile == null) return null;

      final savedPath = await _saveToLocalStorage(pickedFile);
      final file = File(savedPath);
      final fileSize = await file.length();
      final fileName = p.basename(savedPath);
      final mimeType = _getMimeType(fileName);

      return CapturedImage(
        localPath: savedPath,
        fileName: fileName,
        mimeType: mimeType,
        fileSize: fileSize,
      );
    } catch (e) {
      debugPrint('Error picking image: $e');
      return null;
    }
  }

  /// Guarda la imagen en el almacenamiento local de la app
  Future<String> _saveToLocalStorage(XFile pickedFile) async {
    final appDir = await getApplicationDocumentsDirectory();
    final attachmentsDir = Directory(p.join(appDir.path, 'attachments'));

    if (!await attachmentsDir.exists()) {
      await attachmentsDir.create(recursive: true);
    }

    final extension = p.extension(pickedFile.path);
    final fileName = '${const Uuid().v4()}$extension';
    final savedPath = p.join(attachmentsDir.path, fileName);

    await File(pickedFile.path).copy(savedPath);
    return savedPath;
  }

  String _getMimeType(String fileName) {
    final ext = p.extension(fileName).toLowerCase();
    switch (ext) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.webp':
        return 'image/webp';
      case '.pdf':
        return 'application/pdf';
      default:
        return 'application/octet-stream';
    }
  }

  /// Procesa una imagen con OCR para extraer texto y montos
  Future<OcrResult> processWithOcr(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final recognizedText = await _textRecognizer.processImage(inputImage);

      final fullText = recognizedText.text;
      final amounts = _extractAmounts(fullText);
      final mainAmount = _findMainAmount(amounts);

      return OcrResult(
        fullText: fullText,
        detectedAmount: mainAmount,
        allAmounts: amounts.map((a) => a.toString()).toList(),
      );
    } catch (e) {
      debugPrint('Error processing OCR: $e');
      return const OcrResult(fullText: '', allAmounts: []);
    }
  }

  /// Extrae montos del texto reconocido
  List<double> _extractAmounts(String text) {
    final amounts = <double>[];

    // Patrones comunes para montos en Colombia
    // $1.234.567 o $1,234,567 o $1234567
    final patterns = [
      // Con símbolo $ y separadores de miles con punto
      RegExp(r'\$\s*([\d]{1,3}(?:\.[\d]{3})*(?:,\d{2})?)', multiLine: true),
      // Con símbolo $ y separadores de miles con coma
      RegExp(r'\$\s*([\d]{1,3}(?:,[\d]{3})*(?:\.\d{2})?)', multiLine: true),
      // Solo números grandes (posibles montos)
      RegExp(r'(?:total|subtotal|valor|monto)[:\s]*([\d.,]+)',
          caseSensitive: false),
      // Números con formato de moneda sin símbolo
      RegExp(r'([\d]{1,3}(?:[.,][\d]{3})+)', multiLine: true),
    ];

    for (final pattern in patterns) {
      final matches = pattern.allMatches(text);
      for (final match in matches) {
        final amountStr = match.group(1);
        if (amountStr != null) {
          final parsed = _parseAmount(amountStr);
          if (parsed != null && parsed > 100 && parsed < 100000000) {
            amounts.add(parsed);
          }
        }
      }
    }

    // Eliminar duplicados y ordenar de mayor a menor
    final uniqueAmounts = amounts.toSet().toList();
    uniqueAmounts.sort((a, b) => b.compareTo(a));

    return uniqueAmounts;
  }

  /// Parsea un string de monto a double
  double? _parseAmount(String amountStr) {
    try {
      // Limpiar el string
      var cleaned = amountStr.replaceAll(RegExp(r'[^\d.,]'), '');

      // Determinar si usa punto o coma como separador decimal
      final lastDot = cleaned.lastIndexOf('.');
      final lastComma = cleaned.lastIndexOf(',');

      if (lastComma > lastDot && lastComma == cleaned.length - 3) {
        // Formato: 1.234,56 (europeo/colombiano con decimales)
        cleaned = cleaned.replaceAll('.', '').replaceAll(',', '.');
      } else if (lastDot > lastComma && lastDot == cleaned.length - 3) {
        // Formato: 1,234.56 (americano)
        cleaned = cleaned.replaceAll(',', '');
      } else {
        // Sin decimales, quitar separadores de miles
        cleaned = cleaned.replaceAll('.', '').replaceAll(',', '');
      }

      return double.tryParse(cleaned);
    } catch (e) {
      return null;
    }
  }

  /// Encuentra el monto principal (probablemente el total)
  double? _findMainAmount(List<double> amounts) {
    if (amounts.isEmpty) return null;

    // Por defecto, tomar el monto más grande que sea razonable
    // (asumiendo que es el total de la factura)
    for (final amount in amounts) {
      if (amount >= 1000 && amount <= 50000000) {
        return amount;
      }
    }

    return amounts.isNotEmpty ? amounts.first : null;
  }

  /// Elimina un archivo de adjunto del almacenamiento local
  Future<void> deleteLocalFile(String localPath) async {
    try {
      final file = File(localPath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('Error deleting file: $e');
    }
  }

  /// Obtiene el directorio de adjuntos
  Future<Directory> getAttachmentsDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final attachmentsDir = Directory(p.join(appDir.path, 'attachments'));

    if (!await attachmentsDir.exists()) {
      await attachmentsDir.create(recursive: true);
    }

    return attachmentsDir;
  }

  /// Calcula el tamaño total de los adjuntos almacenados
  Future<int> getTotalStorageUsed() async {
    try {
      final dir = await getAttachmentsDirectory();
      int totalSize = 0;

      await for (final entity in dir.list()) {
        if (entity is File) {
          totalSize += await entity.length();
        }
      }

      return totalSize;
    } catch (e) {
      return 0;
    }
  }

  /// Libera recursos del reconocedor de texto
  void dispose() {
    _textRecognizer.close();
  }
}
