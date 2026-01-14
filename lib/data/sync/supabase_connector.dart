import 'dart:developer' as developer;

import 'package:powersync/powersync.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/env_config.dart';

/// Conector de PowerSync con Supabase - MODO READ-ONLY
///
/// ARQUITECTURA: Download-only sync
/// - PowerSync descarga datos de Supabase → Drift (lectura rápida local)
/// - Writes van DIRECTO a Supabase (sin pasar por PowerSync)
/// - Evita FK violations del upload queue de PowerSync
///
/// Flujo:
/// 1. App escribe → Supabase directo
/// 2. Supabase notifica cambio → PowerSync
/// 3. PowerSync descarga → Drift local
/// 4. App lee → Drift local (rápido)
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

    // Obtener URL de PowerSync desde variables de entorno (runtime)
    final powerSyncUrl = EnvConfig.powerSyncUrl;

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

  /// Upload deshabilitado - writes van directo a Supabase
  ///
  /// Este método se llama cuando hay cambios locales pendientes,
  /// pero en nuestra arquitectura read-only, simplemente descartamos
  /// el queue local porque los writes ya fueron a Supabase directamente.
  @override
  Future<void> uploadData(PowerSyncDatabase database) async {
    final transaction = await database.getNextCrudTransaction();

    if (transaction == null) {
      return;
    }

    // MODO READ-ONLY: Descartar operaciones locales
    // Los writes ya fueron directamente a Supabase
    _log('Descartando ${transaction.crud.length} operaciones locales (modo read-only)');

    // Marcar como completado para limpiar el queue
    await transaction.complete();
    onSyncComplete?.call();
  }

  /// Log interno para debugging
  void _log(String message) {
    developer.log(
      message,
      name: 'SupabaseConnector',
    );
  }
}
