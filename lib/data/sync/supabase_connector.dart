import 'dart:developer' as developer;

import 'package:powersync/powersync.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Conector de PowerSync con Supabase
///
/// Maneja la autenticación y las credenciales para sincronización.
/// Implementa la lógica de upload de cambios locales a Supabase.
class SupabaseConnector extends PowerSyncBackendConnector {
  final SupabaseClient _supabase;

  /// Callback opcional para notificar errores de sync
  final void Function(String error)? onSyncError;

  /// Callback opcional para notificar sync exitoso
  final void Function()? onSyncComplete;

  SupabaseConnector(
    this._supabase, {
    this.onSyncError,
    this.onSyncComplete,
  });

  @override
  Future<PowerSyncCredentials?> fetchCredentials() async {
    final session = _supabase.auth.currentSession;

    if (session == null) {
      _log('No hay sesión activa - modo offline');
      return null;
    }

    // Obtener URL de PowerSync desde variables de entorno
    const powerSyncUrl = String.fromEnvironment(
      'POWERSYNC_URL',
      defaultValue: '',
    );

    if (powerSyncUrl.isEmpty) {
      _log('POWERSYNC_URL no configurado - sync deshabilitado');
      return null;
    }

    _log('Credenciales obtenidas para user: ${session.user.id}');

    return PowerSyncCredentials(
      endpoint: powerSyncUrl,
      token: session.accessToken,
      userId: session.user.id,
    );
  }

  @override
  Future<void> uploadData(PowerSyncDatabase database) async {
    final transaction = await database.getNextCrudTransaction();

    if (transaction == null) {
      return;
    }

    _log('Procesando ${transaction.crud.length} operaciones CRUD');

    try {
      for (final op in transaction.crud) {
        await _uploadOperation(op);
      }
      await transaction.complete();
      onSyncComplete?.call();
      _log('Transacción completada exitosamente');
    } on PostgrestException catch (e) {
      final handled = await _handlePostgrestError(e, transaction);
      if (!handled) {
        // Propagar error si no fue manejado
        rethrow;
      }
    } catch (e) {
      _log('Error inesperado en upload: $e');
      onSyncError?.call('Error de sincronización: $e');
      rethrow;
    }
  }

  /// Procesa una operación CRUD individual
  Future<void> _uploadOperation(CrudEntry op) async {
    final table = op.table;
    final data = Map<String, dynamic>.from(op.opData ?? {});

    // Agregar user_id si no está presente
    _ensureUserId(data);

    _log('${op.op.name.toUpperCase()} en $table: ${op.id}');

    switch (op.op) {
      case UpdateType.put:
        await _supabase.from(table).upsert(data);
        break;
      case UpdateType.patch:
        await _supabase.from(table).update(data).eq('id', op.id);
        break;
      case UpdateType.delete:
        await _supabase.from(table).delete().eq('id', op.id);
        break;
    }
  }

  /// Maneja errores de Postgrest específicos
  /// Retorna true si el error fue manejado y se puede continuar
  Future<bool> _handlePostgrestError(
    PostgrestException e,
    CrudTransaction transaction,
  ) async {
    _log('Error PostgrestException: ${e.code} - ${e.message}');

    switch (e.code) {
      case '23505':
        // Conflicto de clave única - el registro ya existe
        // Marcar como completado y continuar
        _log('Conflicto de clave única - ignorando');
        await transaction.complete();
        return true; // Error manejado

      case '23503':
        // Violación de foreign key - el registro padre no existe
        _log('Violación de FK - registro padre no existe');
        onSyncError?.call('Error: registro relacionado no encontrado');
        return false; // Debe propagarse

      case '42501':
        // Permiso denegado (RLS)
        _log('Permiso denegado por RLS');
        onSyncError?.call('Error de permisos');
        return false; // Debe propagarse

      default:
        onSyncError?.call('Error de base de datos: ${e.message}');
        return false; // Debe propagarse
    }
  }

  /// Asegura que el user_id esté presente en los datos
  void _ensureUserId(Map<String, dynamic> data) {
    if (!data.containsKey('user_id')) {
      final session = _supabase.auth.currentSession;
      if (session != null) {
        data['user_id'] = session.user.id;
      }
    }
  }

  /// Log interno para debugging
  void _log(String message) {
    developer.log(
      message,
      name: 'SupabaseConnector',
    );
  }
}
