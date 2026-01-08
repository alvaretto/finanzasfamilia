import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:powersync/powersync.dart';

import 'schema.dart';
import 'supabase_connector.dart';

/// Singleton para acceso a la base de datos PowerSync
class AppDatabase {
  static PowerSyncDatabase? _instance;
  static SupabaseConnector? _connector;

  static PowerSyncDatabase get instance {
    if (_instance == null) {
      throw StateError('Database not initialized. Call AppDatabase.initialize() first.');
    }
    return _instance!;
  }

  static bool get isInitialized => _instance != null;

  /// Inicializa la base de datos PowerSync
  static Future<void> initialize() async {
    if (_instance != null) return;

    final dir = await getApplicationDocumentsDirectory();
    final path = join(dir.path, 'finanzas_familiares.db');

    _instance = PowerSyncDatabase(
      schema: schema,
      path: path,
    );

    await _instance!.initialize();

    if (kDebugMode) {
      print('[DB] PowerSync initialized at: $path');
    }
  }

  /// Conecta con Supabase para sincronización
  static Future<void> connect({
    required String supabaseUrl,
    required String powersyncUrl,
    required String Function() getAccessToken,
    required String? Function() getUserId,
  }) async {
    if (_instance == null) {
      throw StateError('Database not initialized');
    }

    _connector = SupabaseConnector(
      supabaseUrl: supabaseUrl,
      powersyncUrl: powersyncUrl,
      getAccessToken: getAccessToken,
      getUserId: getUserId,
    );

    await _instance!.connect(connector: _connector!);

    if (kDebugMode) {
      print('[DB] Connected to PowerSync sync service');
    }
  }

  /// Desconecta la sincronización
  static Future<void> disconnect() async {
    await _instance?.disconnect();
    if (kDebugMode) {
      print('[DB] Disconnected from sync service');
    }
  }

  /// Ejecutar query raw
  static Future<List<Map<String, dynamic>>> rawQuery(String sql, [List<Object?> args = const []]) async {
    final results = await _instance!.getAll(sql, args);
    return results.map((row) => Map<String, dynamic>.from(row)).toList();
  }

  /// Watch query (reactivo)
  static Stream<List<Map<String, dynamic>>> watch(String sql, [List<Object?> args = const []]) {
    return _instance!.watch(sql, parameters: args).map(
      (results) => results.map((row) => Map<String, dynamic>.from(row)).toList(),
    );
  }

  /// Ejecutar dentro de transacción
  static Future<T> transaction<T>(Future<T> Function(PowerSyncDatabase tx) action) async {
    return await _instance!.writeTransaction((tx) async {
      // PowerSync usa el mismo db object en transacciones
      return await action(_instance!);
    });
  }

  /// Limpiar base de datos (para logout)
  static Future<void> clear() async {
    await _instance?.disconnectAndClear();
    _instance = null;
    _connector = null;
    if (kDebugMode) {
      print('[DB] Database cleared');
    }
  }
}
