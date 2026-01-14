import '../../application/services/storage_sync_service.dart' as app;
import '../../domain/repositories/attachment_repository.dart';

/// Adapter que conecta StorageSyncService (application) con la interfaz de dominio.
class AttachmentStorageAdapter implements AttachmentStorageSync {
  final app.StorageSyncService _service;

  AttachmentStorageAdapter(this._service);

  @override
  Future<SyncResult> uploadAttachment({
    required String attachmentId,
    required String localPath,
    required String fileName,
    required String mimeType,
  }) async {
    final result = await _service.uploadAttachment(
      attachmentId: attachmentId,
      localPath: localPath,
      fileName: fileName,
      mimeType: mimeType,
    );

    return SyncResult(
      success: result.success,
      remoteUrl: result.remoteUrl,
      error: result.error,
    );
  }

  @override
  Future<bool> deleteAttachment({
    required String attachmentId,
    required String fileName,
  }) async {
    return _service.deleteAttachment(
      attachmentId: attachmentId,
      fileName: fileName,
    );
  }

  @override
  Future<Map<String, SyncResult>> syncPendingAttachments(
    List<PendingAttachmentData> attachments,
  ) async {
    final pendingList = attachments
        .map((a) => app.PendingAttachment(
              id: a.id,
              localPath: a.localPath,
              fileName: a.fileName,
              mimeType: a.mimeType,
            ))
        .toList();

    final results = await _service.syncPendingAttachments(pendingList);

    return results.map((key, value) => MapEntry(
          key,
          SyncResult(
            success: value.success,
            remoteUrl: value.remoteUrl,
            error: value.error,
          ),
        ));
  }
}
