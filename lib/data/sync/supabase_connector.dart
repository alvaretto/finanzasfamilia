import 'package:powersync/powersync.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Conector de PowerSync con Supabase
/// Maneja la autenticación y las credenciales para sincronización
class SupabaseConnector extends PowerSyncBackendConnector {
  final SupabaseClient _supabase;

  SupabaseConnector(this._supabase);

  @override
  Future<PowerSyncCredentials?> fetchCredentials() async {
    final session = _supabase.auth.currentSession;

    if (session == null) {
      // Usuario no autenticado - modo offline puro
      return null;
    }

    // En producción, esto debería obtener el token de PowerSync
    // desde un endpoint de tu backend
    const powerSyncUrl = String.fromEnvironment(
      'POWERSYNC_URL',
      defaultValue: '',
    );

    if (powerSyncUrl.isEmpty) {
      return null;
    }

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

    try {
      for (final op in transaction.crud) {
        await _uploadOperation(op);
      }
      await transaction.complete();
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        // Conflicto de clave única - ignorar y continuar
        await transaction.complete();
      } else {
        rethrow;
      }
    }
  }

  Future<void> _uploadOperation(CrudEntry op) async {
    final table = op.table;
    final data = Map<String, dynamic>.from(op.opData ?? {});

    // Convertir campos de Drift a Supabase
    _convertFieldNames(data);

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

  /// Convierte nombres de campos de snake_case de Drift
  /// a los nombres esperados por Supabase
  void _convertFieldNames(Map<String, dynamic> data) {
    // Los nombres ya están en snake_case, no se requiere conversión
    // Este método existe para futuras transformaciones si son necesarias
  }
}
