import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:powersync/powersync.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'powersync_schema.dart';
import 'supabase_connector.dart';

/// Singleton que maneja la instancia de PowerSync
/// y proporciona el path del archivo SQLite para Drift
class PowerSyncDatabaseManager {
  static PowerSyncDatabaseManager? _instance;
  static PowerSyncDatabaseManager get instance {
    _instance ??= PowerSyncDatabaseManager._();
    return _instance!;
  }

  PowerSyncDatabaseManager._();

  PowerSyncDatabase? _database;
  String? _dbPath;
  SupabaseConnector? _connector;

  /// Obtiene el path de la base de datos SQLite
  /// Drift usará este mismo archivo para sus operaciones
  String get dbPath {
    if (_dbPath == null) {
      throw StateError('PowerSync no ha sido inicializado. Llama a initialize() primero.');
    }
    return _dbPath!;
  }

  /// Obtiene la instancia de PowerSyncDatabase
  PowerSyncDatabase get database {
    if (_database == null) {
      throw StateError('PowerSync no ha sido inicializado. Llama a initialize() primero.');
    }
    return _database!;
  }

  /// Indica si PowerSync está inicializado
  bool get isInitialized => _database != null;

  /// Inicializa PowerSync con el cliente de Supabase
  Future<void> initialize(SupabaseClient supabase) async {
    if (_database != null) {
      return; // Ya inicializado
    }

    // Obtener el directorio de documentos
    final dir = await getApplicationDocumentsDirectory();
    _dbPath = p.join(dir.path, 'finanzas_familiares_powersync.db');

    // Crear la base de datos de PowerSync
    _database = PowerSyncDatabase(
      schema: schema,
      path: _dbPath!,
    );

    // Crear el conector de Supabase
    _connector = SupabaseConnector(supabase);

    // Inicializar la base de datos
    await _database!.initialize();

    // Conectar con el backend (si hay credenciales disponibles)
    await _connectIfAuthenticated();
  }

  /// Conecta con PowerSync si el usuario está autenticado
  Future<void> _connectIfAuthenticated() async {
    if (_database == null || _connector == null) return;

    try {
      final credentials = await _connector!.fetchCredentials();
      if (credentials != null) {
        await _database!.connect(connector: _connector!);
      }
    } catch (_) {
      // Si falla la conexión, continuamos en modo offline
      // En producción usar logger apropiado
    }
  }

  /// Reconecta después de login
  Future<void> reconnect() async {
    if (_database == null || _connector == null) return;

    await _database!.connect(connector: _connector!);
  }

  /// Desconecta (logout)
  Future<void> disconnect() async {
    await _database?.disconnect();
  }

  /// Fuerza sincronización completa
  Future<void> sync() async {
    if (_database == null) return;

    // Esperar a que se complete una sincronización
    await _database!.waitForFirstSync();
  }

  /// Cierra la base de datos
  Future<void> close() async {
    await _database?.close();
    _database = null;
    _dbPath = null;
    _connector = null;
    _instance = null;
  }
}
