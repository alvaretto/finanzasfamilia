import 'package:flutter/foundation.dart';
import 'package:powersync/powersync.dart';

/// Conector de PowerSync para Supabase
class SupabaseConnector extends PowerSyncBackendConnector {
  final String supabaseUrl;
  final String powersyncUrl;
  final String Function() getAccessToken;
  final String? Function() getUserId;

  SupabaseConnector({
    required this.supabaseUrl,
    required this.powersyncUrl,
    required this.getAccessToken,
    required this.getUserId,
  });

  @override
  Future<PowerSyncCredentials?> fetchCredentials() async {
    final userId = getUserId();
    if (userId == null) {
      return null;
    }

    final token = getAccessToken();

    return PowerSyncCredentials(
      endpoint: powersyncUrl,
      token: token,
      userId: userId,
    );
  }

  @override
  Future<void> uploadData(PowerSyncDatabase database) async {
    final tx = await database.getCrudBatch();
    if (tx == null) return;

    for (final op in tx.crud) {
      await _uploadOperation(op);
    }

    await tx.complete();
  }

  Future<void> _uploadOperation(CrudEntry op) async {
    // TODO: Implementar upload a Supabase via REST API
    if (kDebugMode) {
      print('[Sync] Upload: ${op.op} ${op.table} ${op.id}');
    }
  }
}
