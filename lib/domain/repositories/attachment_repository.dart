// Interface de repositorio para adjuntos de transacciones.
// Define operaciones CRUD y sincronización de adjuntos.

/// Datos de un adjunto en el dominio.
class AttachmentData {
  final String id;
  final String transactionId;
  final String fileName;
  final String mimeType;
  final String localPath;
  final String? remoteUrl;
  final int fileSize;
  final String? ocrText;
  final double? ocrAmount;
  final bool isSynced;
  final DateTime createdAt;

  const AttachmentData({
    required this.id,
    required this.transactionId,
    required this.fileName,
    required this.mimeType,
    required this.localPath,
    this.remoteUrl,
    required this.fileSize,
    this.ocrText,
    this.ocrAmount,
    required this.isSynced,
    required this.createdAt,
  });

  /// Formatea el tamaño del archivo para mostrar.
  String get formattedSize {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    }
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Verifica si es una imagen.
  bool get isImage => mimeType.startsWith('image/');

  /// Verifica si es un PDF.
  bool get isPdf => mimeType == 'application/pdf';
}

/// Datos para crear un adjunto.
class CreateAttachmentData {
  final String transactionId;
  final String fileName;
  final String mimeType;
  final String localPath;
  final int fileSize;
  final String? ocrText;
  final double? ocrAmount;

  const CreateAttachmentData({
    required this.transactionId,
    required this.fileName,
    required this.mimeType,
    required this.localPath,
    required this.fileSize,
    this.ocrText,
    this.ocrAmount,
  });
}

/// Resultado de OCR.
class OcrResultData {
  final String fullText;
  final double? detectedAmount;
  final List<String> lines;

  const OcrResultData({
    required this.fullText,
    this.detectedAmount,
    required this.lines,
  });

  bool get hasAmount => detectedAmount != null;
  bool get isEmpty => fullText.isEmpty;
}

/// Resultado de sincronización de un adjunto.
class SyncResult {
  final bool success;
  final String? remoteUrl;
  final String? error;

  const SyncResult({
    required this.success,
    this.remoteUrl,
    this.error,
  });

  factory SyncResult.success(String remoteUrl) => SyncResult(
        success: true,
        remoteUrl: remoteUrl,
      );

  factory SyncResult.failure(String error) => SyncResult(
        success: false,
        error: error,
      );
}

/// Estado de sincronización global de adjuntos.
class AttachmentSyncStatus {
  final bool isSyncing;
  final int pendingCount;
  final int syncedCount;
  final String? lastError;

  const AttachmentSyncStatus({
    this.isSyncing = false,
    this.pendingCount = 0,
    this.syncedCount = 0,
    this.lastError,
  });

  AttachmentSyncStatus copyWith({
    bool? isSyncing,
    int? pendingCount,
    int? syncedCount,
    String? lastError,
  }) {
    return AttachmentSyncStatus(
      isSyncing: isSyncing ?? this.isSyncing,
      pendingCount: pendingCount ?? this.pendingCount,
      syncedCount: syncedCount ?? this.syncedCount,
      lastError: lastError,
    );
  }
}

/// Interface de repositorio para adjuntos.
abstract class AttachmentRepository {
  /// Obtiene adjuntos de una transacción.
  Future<List<AttachmentData>> getAttachmentsForTransaction(
      String transactionId);

  /// Obtiene un adjunto por ID.
  Future<AttachmentData?> getAttachmentById(String id);

  /// Obtiene adjuntos pendientes de sincronización.
  Future<List<AttachmentData>> getPendingSyncAttachments();

  /// Inserta un nuevo adjunto.
  Future<void> insertAttachment(String id, CreateAttachmentData data);

  /// Actualiza datos de OCR de un adjunto.
  Future<void> updateOcrData(String id, String? ocrText, double? ocrAmount);

  /// Marca un adjunto como sincronizado.
  Future<void> markAsSynced(String id, String remoteUrl);

  /// Elimina un adjunto.
  Future<void> deleteAttachment(String id);

  /// Elimina todos los adjuntos de una transacción.
  Future<void> deleteAttachmentsForTransaction(String transactionId);

  /// Stream de adjuntos de una transacción.
  Stream<List<AttachmentData>> watchAttachmentsForTransaction(
      String transactionId);

  /// Calcula el espacio total usado por adjuntos.
  Future<int> getTotalStorageUsed();
}

/// Interface para operaciones de archivo local.
abstract class AttachmentFileService {
  /// Captura una imagen desde la cámara.
  /// Retorna null si el usuario cancela.
  Future<CapturedImageData?> captureFromCamera();

  /// Selecciona una imagen desde la galería.
  /// Retorna null si el usuario cancela.
  Future<CapturedImageData?> pickFromGallery();

  /// Procesa una imagen con OCR.
  Future<OcrResultData> processWithOcr(String imagePath);

  /// Elimina un archivo local.
  Future<void> deleteLocalFile(String path);

  /// Obtiene el espacio total usado.
  Future<int> getTotalStorageUsed();

  /// Libera recursos.
  void dispose();
}

/// Datos de una imagen capturada.
class CapturedImageData {
  final String localPath;
  final String fileName;
  final String mimeType;
  final int fileSize;

  const CapturedImageData({
    required this.localPath,
    required this.fileName,
    required this.mimeType,
    required this.fileSize,
  });
}

/// Interface para sincronización con storage remoto.
abstract class AttachmentStorageSync {
  /// Sube un adjunto al storage remoto.
  Future<SyncResult> uploadAttachment({
    required String attachmentId,
    required String localPath,
    required String fileName,
    required String mimeType,
  });

  /// Elimina un adjunto del storage remoto.
  Future<bool> deleteAttachment({
    required String attachmentId,
    required String fileName,
  });

  /// Sincroniza múltiples adjuntos pendientes.
  Future<Map<String, SyncResult>> syncPendingAttachments(
    List<PendingAttachmentData> attachments,
  );
}

/// Datos de un adjunto pendiente de sincronización.
class PendingAttachmentData {
  final String id;
  final String localPath;
  final String fileName;
  final String mimeType;

  const PendingAttachmentData({
    required this.id,
    required this.localPath,
    required this.fileName,
    required this.mimeType,
  });
}
