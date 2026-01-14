import '../../application/services/attachment_service.dart' as app;
import '../../domain/repositories/attachment_repository.dart';

/// Adapter que conecta AttachmentService (application) con la interfaz de dominio.
class AttachmentFileAdapter implements AttachmentFileService {
  final app.AttachmentService _service;

  AttachmentFileAdapter(this._service);

  @override
  Future<CapturedImageData?> captureFromCamera() async {
    final captured = await _service.captureFromCamera();
    if (captured == null) return null;

    return CapturedImageData(
      localPath: captured.localPath,
      fileName: captured.fileName,
      mimeType: captured.mimeType,
      fileSize: captured.fileSize,
    );
  }

  @override
  Future<CapturedImageData?> pickFromGallery() async {
    final captured = await _service.pickFromGallery();
    if (captured == null) return null;

    return CapturedImageData(
      localPath: captured.localPath,
      fileName: captured.fileName,
      mimeType: captured.mimeType,
      fileSize: captured.fileSize,
    );
  }

  @override
  Future<OcrResultData> processWithOcr(String imagePath) async {
    final result = await _service.processWithOcr(imagePath);
    // Convertir fullText a líneas dividiendo por newline
    final lines = result.fullText.isNotEmpty
        ? result.fullText.split('\n')
        : <String>[];
    return OcrResultData(
      fullText: result.fullText,
      detectedAmount: result.detectedAmount,
      lines: lines,
    );
  }

  @override
  Future<void> deleteLocalFile(String path) async {
    await _service.deleteLocalFile(path);
  }

  @override
  Future<int> getTotalStorageUsed() async {
    return _service.getTotalStorageUsed();
  }

  @override
  void dispose() {
    _service.dispose();
  }
}
