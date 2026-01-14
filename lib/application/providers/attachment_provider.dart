import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/adapters/attachment_file_adapter.dart';

// Re-exportar tipos del dominio para acceso desde presentation layer
export '../../domain/repositories/attachment_repository.dart'
    show AttachmentData, AttachmentSyncStatus, OcrResultData;
import '../../data/adapters/attachment_storage_adapter.dart';
import '../../data/local/daos/transaction_attachments_dao.dart';
import '../../data/repositories/drift_attachment_repository.dart';
import '../../domain/repositories/attachment_repository.dart';
import '../../domain/services/attachment_management_service.dart';
import '../services/attachment_service.dart';
import '../services/storage_sync_service.dart';
import 'database_provider.dart';

part 'attachment_provider.g.dart';

// ============================================================
// PROVIDERS DE INFRAESTRUCTURA
// ============================================================

/// Provider del servicio de adjuntos de aplicación (cámara, galería, OCR)
@riverpod
AttachmentService attachmentService(Ref ref) {
  final service = AttachmentService();
  ref.onDispose(() => service.dispose());
  return service;
}

/// Provider del servicio de sincronización de Storage
@riverpod
StorageSyncService storageSyncService(Ref ref) {
  return StorageSyncService(Supabase.instance.client);
}

/// Provider del DAO de adjuntos
@riverpod
TransactionAttachmentsDao transactionAttachmentsDao(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  return TransactionAttachmentsDao(db);
}

/// Provider del repositorio de adjuntos
@riverpod
AttachmentRepository attachmentRepository(Ref ref) {
  final dao = ref.watch(transactionAttachmentsDaoProvider);
  return DriftAttachmentRepository(dao);
}

/// Provider del adaptador de archivos
@riverpod
AttachmentFileService attachmentFileService(Ref ref) {
  final service = ref.watch(attachmentServiceProvider);
  return AttachmentFileAdapter(service);
}

/// Provider del adaptador de storage
@riverpod
AttachmentStorageSync attachmentStorageSync(Ref ref) {
  final service = ref.watch(storageSyncServiceProvider);
  return AttachmentStorageAdapter(service);
}

/// Provider del servicio de gestión de adjuntos (dominio)
@riverpod
AttachmentManagementService attachmentManagementService(Ref ref) {
  return AttachmentManagementService(
    repository: ref.watch(attachmentRepositoryProvider),
    fileService: ref.watch(attachmentFileServiceProvider),
    storageSync: ref.watch(attachmentStorageSyncProvider),
  );
}

// ============================================================
// PROVIDERS DE DOMINIO
// ============================================================

/// Provider de adjuntos de una transacción específica (stream)
@riverpod
Stream<List<AttachmentData>> transactionAttachments(
  Ref ref,
  String transactionId,
) {
  final service = ref.watch(attachmentManagementServiceProvider);
  return service.watchAttachmentsForTransaction(transactionId);
}

/// Provider del espacio de almacenamiento usado por adjuntos
@riverpod
Future<int> attachmentsStorageUsed(Ref ref) async {
  final service = ref.watch(attachmentManagementServiceProvider);
  return service.getTotalStorageUsed();
}

/// Provider de adjuntos pendientes de sincronización
@riverpod
Future<List<AttachmentData>> pendingSyncAttachments(Ref ref) async {
  final service = ref.watch(attachmentManagementServiceProvider);
  return service.getPendingSyncAttachments();
}

// ============================================================
// NOTIFIER PRINCIPAL
// ============================================================

/// Notifier para gestionar adjuntos de transacciones
/// Delega toda la lógica de negocio a AttachmentManagementService
@riverpod
class AttachmentsNotifier extends _$AttachmentsNotifier {
  @override
  Future<List<AttachmentData>> build(String transactionId) async {
    final service = ref.watch(attachmentManagementServiceProvider);
    return service.getAttachmentsForTransaction(transactionId);
  }

  AttachmentManagementService get _service =>
      ref.read(attachmentManagementServiceProvider);

  /// Captura una imagen desde la cámara y la agrega como adjunto
  Future<AttachmentData?> captureFromCamera({bool processOcr = true}) async {
    final result = await _service.captureFromCamera(
      transactionId: transactionId,
      processOcr: processOcr,
    );

    if (result != null) {
      ref.invalidateSelf();
    }

    return result;
  }

  /// Selecciona una imagen desde la galería y la agrega como adjunto
  Future<AttachmentData?> pickFromGallery({bool processOcr = true}) async {
    final result = await _service.pickFromGallery(
      transactionId: transactionId,
      processOcr: processOcr,
    );

    if (result != null) {
      ref.invalidateSelf();
    }

    return result;
  }

  /// Reprocesa OCR para un adjunto existente
  Future<OcrResultData?> reprocessOcr(String attachmentId) async {
    final result = await _service.reprocessOcr(attachmentId);
    ref.invalidateSelf();
    return result;
  }

  /// Elimina un adjunto
  Future<void> deleteAttachment(String attachmentId) async {
    await _service.deleteAttachment(attachmentId);
    ref.invalidateSelf();
  }

  /// Elimina todos los adjuntos de la transacción
  Future<void> deleteAllAttachments() async {
    await _service.deleteAllAttachments(transactionId);
    ref.invalidateSelf();
  }

  /// Sincroniza un adjunto específico a Supabase Storage
  Future<bool> syncAttachment(String attachmentId) async {
    final result = await _service.syncAttachment(attachmentId);
    if (result) {
      ref.invalidateSelf();
    }
    return result;
  }

  /// Sincroniza todos los adjuntos pendientes de esta transacción
  Future<int> syncAllPending() async {
    final count = await _service.syncAllPending(transactionId);
    if (count > 0) {
      ref.invalidateSelf();
    }
    return count;
  }
}

// ============================================================
// SINCRONIZACIÓN GLOBAL
// ============================================================

/// Notifier para sincronización global de adjuntos
@riverpod
class GlobalAttachmentSync extends _$GlobalAttachmentSync {
  @override
  AttachmentSyncStatus build() {
    _updatePendingCount();
    return const AttachmentSyncStatus();
  }

  Future<void> _updatePendingCount() async {
    final service = ref.read(attachmentManagementServiceProvider);
    final pending = await service.getPendingSyncAttachments();
    state = state.copyWith(pendingCount: pending.length);
  }

  /// Sincroniza todos los adjuntos pendientes del sistema
  Future<int> syncAllPendingAttachments() async {
    if (state.isSyncing) return 0;

    state = state.copyWith(isSyncing: true, lastError: null);

    try {
      final service = ref.read(attachmentManagementServiceProvider);
      final syncedCount = await service.syncAllPendingGlobal();

      // Actualizar conteo de pendientes
      final remaining = await service.getPendingSyncAttachments();

      state = state.copyWith(
        isSyncing: false,
        pendingCount: remaining.length,
        syncedCount: state.syncedCount + syncedCount,
      );

      // Invalidar provider de pendientes
      ref.invalidate(pendingSyncAttachmentsProvider);

      return syncedCount;
    } catch (e) {
      state = state.copyWith(
        isSyncing: false,
        lastError: e.toString(),
      );
      return 0;
    }
  }
}
