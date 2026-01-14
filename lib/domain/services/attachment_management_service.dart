// Servicio de dominio para gestión de adjuntos.
// Contiene lógica de negocio pura para adjuntos y OCR.

import 'package:uuid/uuid.dart';
import '../repositories/attachment_repository.dart';

/// Excepción para errores de adjuntos.
class AttachmentException implements Exception {
  final String message;
  const AttachmentException(this.message);

  @override
  String toString() => message;
}

/// Excepción cuando no se encuentra un adjunto.
class AttachmentNotFoundException extends AttachmentException {
  final String attachmentId;
  const AttachmentNotFoundException(this.attachmentId)
      : super('Adjunto no encontrado: $attachmentId');
}

/// Servicio de dominio para gestión de adjuntos.
///
/// Gestiona la lógica de negocio para:
/// - Captura de imágenes (cámara/galería)
/// - Procesamiento OCR
/// - Sincronización con storage remoto
/// - CRUD de adjuntos
class AttachmentManagementService {
  final AttachmentRepository _repository;
  final AttachmentFileService _fileService;
  final AttachmentStorageSync _storageSync;
  final Uuid _uuid;

  AttachmentManagementService({
    required AttachmentRepository repository,
    required AttachmentFileService fileService,
    required AttachmentStorageSync storageSync,
    Uuid? uuid,
  })  : _repository = repository,
        _fileService = fileService,
        _storageSync = storageSync,
        _uuid = uuid ?? const Uuid();

  // ==================== CONSULTAS ====================

  /// Obtiene adjuntos de una transacción.
  Future<List<AttachmentData>> getAttachmentsForTransaction(
      String transactionId) {
    return _repository.getAttachmentsForTransaction(transactionId);
  }

  /// Obtiene un adjunto por ID.
  Future<AttachmentData?> getAttachmentById(String id) {
    return _repository.getAttachmentById(id);
  }

  /// Obtiene adjuntos pendientes de sincronización.
  Future<List<AttachmentData>> getPendingSyncAttachments() {
    return _repository.getPendingSyncAttachments();
  }

  /// Obtiene el espacio total usado por adjuntos.
  Future<int> getTotalStorageUsed() {
    return _fileService.getTotalStorageUsed();
  }

  // ==================== CAPTURA ====================

  /// Captura una imagen desde la cámara y la agrega como adjunto.
  ///
  /// Opcionalmente procesa OCR para extraer texto y montos.
  /// Retorna null si el usuario cancela.
  Future<AttachmentData?> captureFromCamera({
    required String transactionId,
    bool processOcr = true,
  }) async {
    final captured = await _fileService.captureFromCamera();
    if (captured == null) return null;

    return _saveAttachment(
      transactionId: transactionId,
      captured: captured,
      processOcr: processOcr,
    );
  }

  /// Selecciona una imagen desde la galería y la agrega como adjunto.
  ///
  /// Opcionalmente procesa OCR para extraer texto y montos.
  /// Retorna null si el usuario cancela.
  Future<AttachmentData?> pickFromGallery({
    required String transactionId,
    bool processOcr = true,
  }) async {
    final captured = await _fileService.pickFromGallery();
    if (captured == null) return null;

    return _saveAttachment(
      transactionId: transactionId,
      captured: captured,
      processOcr: processOcr,
    );
  }

  Future<AttachmentData?> _saveAttachment({
    required String transactionId,
    required CapturedImageData captured,
    required bool processOcr,
  }) async {
    final id = _uuid.v4();

    String? ocrText;
    double? ocrAmount;

    // Procesar OCR si está habilitado y es imagen
    if (processOcr && captured.mimeType.startsWith('image/')) {
      final ocrResult = await _fileService.processWithOcr(captured.localPath);
      ocrText = ocrResult.fullText.isNotEmpty ? ocrResult.fullText : null;
      ocrAmount = ocrResult.detectedAmount;
    }

    await _repository.insertAttachment(
      id,
      CreateAttachmentData(
        transactionId: transactionId,
        fileName: captured.fileName,
        mimeType: captured.mimeType,
        localPath: captured.localPath,
        fileSize: captured.fileSize,
        ocrText: ocrText,
        ocrAmount: ocrAmount,
      ),
    );

    return AttachmentData(
      id: id,
      transactionId: transactionId,
      fileName: captured.fileName,
      mimeType: captured.mimeType,
      localPath: captured.localPath,
      fileSize: captured.fileSize,
      ocrText: ocrText,
      ocrAmount: ocrAmount,
      isSynced: false,
      createdAt: DateTime.now(),
    );
  }

  // ==================== OCR ====================

  /// Reprocesa OCR para un adjunto existente.
  Future<OcrResultData?> reprocessOcr(String attachmentId) async {
    final attachment = await _repository.getAttachmentById(attachmentId);
    if (attachment == null) {
      throw AttachmentNotFoundException(attachmentId);
    }

    if (!attachment.isImage) {
      throw const AttachmentException('Solo se puede procesar OCR en imágenes');
    }

    final ocrResult = await _fileService.processWithOcr(attachment.localPath);
    await _repository.updateOcrData(
      attachmentId,
      ocrResult.fullText.isNotEmpty ? ocrResult.fullText : null,
      ocrResult.detectedAmount,
    );

    return ocrResult;
  }

  // ==================== ELIMINACIÓN ====================

  /// Elimina un adjunto.
  Future<void> deleteAttachment(String attachmentId) async {
    final attachment = await _repository.getAttachmentById(attachmentId);
    if (attachment == null) {
      throw AttachmentNotFoundException(attachmentId);
    }

    // Eliminar archivo local
    await _fileService.deleteLocalFile(attachment.localPath);

    // Eliminar del storage remoto si está sincronizado
    if (attachment.isSynced) {
      await _storageSync.deleteAttachment(
        attachmentId: attachment.id,
        fileName: attachment.fileName,
      );
    }

    // Eliminar del repositorio
    await _repository.deleteAttachment(attachmentId);
  }

  /// Elimina todos los adjuntos de una transacción.
  Future<void> deleteAllAttachments(String transactionId) async {
    final attachments =
        await _repository.getAttachmentsForTransaction(transactionId);

    for (final attachment in attachments) {
      // Eliminar archivo local
      await _fileService.deleteLocalFile(attachment.localPath);

      // Eliminar del storage remoto si está sincronizado
      if (attachment.isSynced) {
        await _storageSync.deleteAttachment(
          attachmentId: attachment.id,
          fileName: attachment.fileName,
        );
      }
    }

    // Eliminar todos del repositorio
    await _repository.deleteAttachmentsForTransaction(transactionId);
  }

  // ==================== SINCRONIZACIÓN ====================

  /// Sincroniza un adjunto específico a storage remoto.
  ///
  /// Retorna true si la sincronización fue exitosa.
  Future<bool> syncAttachment(String attachmentId) async {
    final attachment = await _repository.getAttachmentById(attachmentId);
    if (attachment == null) {
      throw AttachmentNotFoundException(attachmentId);
    }

    if (attachment.isSynced) {
      return true; // Ya sincronizado
    }

    final result = await _storageSync.uploadAttachment(
      attachmentId: attachment.id,
      localPath: attachment.localPath,
      fileName: attachment.fileName,
      mimeType: attachment.mimeType,
    );

    if (result.success && result.remoteUrl != null) {
      await _repository.markAsSynced(attachmentId, result.remoteUrl!);
      return true;
    }

    return false;
  }

  /// Sincroniza todos los adjuntos pendientes de una transacción.
  ///
  /// Retorna el número de adjuntos sincronizados exitosamente.
  Future<int> syncAllPending(String transactionId) async {
    final attachments =
        await _repository.getAttachmentsForTransaction(transactionId);
    final pending = attachments.where((a) => !a.isSynced).toList();

    if (pending.isEmpty) return 0;

    final pendingData = pending
        .map((a) => PendingAttachmentData(
              id: a.id,
              localPath: a.localPath,
              fileName: a.fileName,
              mimeType: a.mimeType,
            ))
        .toList();

    final results = await _storageSync.syncPendingAttachments(pendingData);

    int syncedCount = 0;
    for (final entry in results.entries) {
      if (entry.value.success && entry.value.remoteUrl != null) {
        await _repository.markAsSynced(entry.key, entry.value.remoteUrl!);
        syncedCount++;
      }
    }

    return syncedCount;
  }

  /// Sincroniza todos los adjuntos pendientes del sistema.
  ///
  /// Retorna el número total de adjuntos sincronizados.
  Future<int> syncAllPendingGlobal() async {
    final pending = await _repository.getPendingSyncAttachments();
    if (pending.isEmpty) return 0;

    final pendingData = pending
        .map((a) => PendingAttachmentData(
              id: a.id,
              localPath: a.localPath,
              fileName: a.fileName,
              mimeType: a.mimeType,
            ))
        .toList();

    final results = await _storageSync.syncPendingAttachments(pendingData);

    int syncedCount = 0;
    for (final entry in results.entries) {
      if (entry.value.success && entry.value.remoteUrl != null) {
        await _repository.markAsSynced(entry.key, entry.value.remoteUrl!);
        syncedCount++;
      }
    }

    return syncedCount;
  }

  // ==================== STREAMS ====================

  /// Stream de adjuntos de una transacción.
  Stream<List<AttachmentData>> watchAttachmentsForTransaction(
      String transactionId) {
    return _repository.watchAttachmentsForTransaction(transactionId);
  }

  // ==================== LIMPIEZA ====================

  /// Libera recursos del servicio de archivos.
  void dispose() {
    _fileService.dispose();
  }
}
