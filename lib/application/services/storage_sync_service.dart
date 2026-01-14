import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Resultado de una operación de sincronización
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

/// Servicio para sincronizar adjuntos con Supabase Storage
class StorageSyncService {
  final SupabaseClient _supabase;
  static const String _bucketName = 'transaction-attachments';

  StorageSyncService(this._supabase);

  /// Verifica si el usuario está autenticado
  bool get isAuthenticated => _supabase.auth.currentUser != null;

  /// Obtiene el ID del usuario actual
  String? get currentUserId => _supabase.auth.currentUser?.id;

  /// Sube un archivo a Supabase Storage
  Future<SyncResult> uploadAttachment({
    required String attachmentId,
    required String localPath,
    required String fileName,
    required String mimeType,
  }) async {
    if (!isAuthenticated) {
      return SyncResult.failure('Usuario no autenticado');
    }

    try {
      final file = File(localPath);
      if (!await file.exists()) {
        return SyncResult.failure('Archivo local no encontrado');
      }

      final userId = currentUserId!;
      final remotePath = _buildRemotePath(userId, attachmentId, fileName);
      final bytes = await file.readAsBytes();

      await _supabase.storage.from(_bucketName).uploadBinary(
            remotePath,
            bytes,
            fileOptions: FileOptions(
              contentType: mimeType,
              upsert: true,
            ),
          );

      final publicUrl = _supabase.storage
          .from(_bucketName)
          .getPublicUrl(remotePath);

      debugPrint('StorageSyncService: Uploaded $fileName to $remotePath');
      return SyncResult.success(publicUrl);
    } on StorageException catch (e) {
      debugPrint('StorageSyncService: StorageException - ${e.message}');
      return SyncResult.failure('Error de almacenamiento: ${e.message}');
    } catch (e) {
      debugPrint('StorageSyncService: Error uploading - $e');
      return SyncResult.failure('Error al subir archivo: $e');
    }
  }

  /// Descarga un archivo desde Supabase Storage
  Future<File?> downloadAttachment({
    required String remoteUrl,
    required String localPath,
  }) async {
    if (!isAuthenticated) {
      debugPrint('StorageSyncService: No autenticado para descargar');
      return null;
    }

    try {
      final remotePath = _extractPathFromUrl(remoteUrl);
      if (remotePath == null) {
        debugPrint('StorageSyncService: No se pudo extraer path de URL');
        return null;
      }

      final bytes = await _supabase.storage
          .from(_bucketName)
          .download(remotePath);

      final file = File(localPath);
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes);

      debugPrint('StorageSyncService: Downloaded to $localPath');
      return file;
    } on StorageException catch (e) {
      debugPrint('StorageSyncService: StorageException - ${e.message}');
      return null;
    } catch (e) {
      debugPrint('StorageSyncService: Error downloading - $e');
      return null;
    }
  }

  /// Elimina un archivo de Supabase Storage
  Future<bool> deleteAttachment({
    required String attachmentId,
    required String fileName,
  }) async {
    if (!isAuthenticated) return false;

    try {
      final userId = currentUserId!;
      final remotePath = _buildRemotePath(userId, attachmentId, fileName);

      await _supabase.storage.from(_bucketName).remove([remotePath]);

      debugPrint('StorageSyncService: Deleted $remotePath');
      return true;
    } on StorageException catch (e) {
      debugPrint('StorageSyncService: Error deleting - ${e.message}');
      return false;
    } catch (e) {
      debugPrint('StorageSyncService: Error deleting - $e');
      return false;
    }
  }

  /// Construye la ruta remota para un archivo
  String _buildRemotePath(String userId, String attachmentId, String fileName) {
    final extension = p.extension(fileName);
    return '$userId/$attachmentId$extension';
  }

  /// Extrae el path relativo de una URL pública
  String? _extractPathFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;

      final bucketIndex = pathSegments.indexOf(_bucketName);
      if (bucketIndex == -1 || bucketIndex >= pathSegments.length - 1) {
        return null;
      }

      return pathSegments.sublist(bucketIndex + 1).join('/');
    } catch (e) {
      return null;
    }
  }

  /// Sincroniza múltiples adjuntos pendientes
  Future<Map<String, SyncResult>> syncPendingAttachments(
    List<PendingAttachment> attachments,
  ) async {
    final results = <String, SyncResult>{};

    for (final attachment in attachments) {
      final result = await uploadAttachment(
        attachmentId: attachment.id,
        localPath: attachment.localPath,
        fileName: attachment.fileName,
        mimeType: attachment.mimeType,
      );
      results[attachment.id] = result;

      // Pequeña pausa entre uploads para evitar rate limiting
      if (attachments.length > 1) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }

    return results;
  }

  /// Obtiene el tamaño total usado en Storage por el usuario
  Future<int> getStorageUsed() async {
    if (!isAuthenticated) return 0;

    try {
      final userId = currentUserId!;
      final files = await _supabase.storage.from(_bucketName).list(path: userId);

      int totalSize = 0;
      for (final file in files) {
        if (file.metadata != null && file.metadata!['size'] != null) {
          totalSize += (file.metadata!['size'] as num).toInt();
        }
      }

      return totalSize;
    } catch (e) {
      debugPrint('StorageSyncService: Error getting storage used - $e');
      return 0;
    }
  }
}

/// Representa un adjunto pendiente de sincronización
class PendingAttachment {
  final String id;
  final String localPath;
  final String fileName;
  final String mimeType;

  const PendingAttachment({
    required this.id,
    required this.localPath,
    required this.fileName,
    required this.mimeType,
  });
}
