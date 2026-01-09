import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:powersync/powersync.dart' as ps;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../application/providers/sync_status_provider.dart';
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

  ps.PowerSyncDatabase? _database;
  String? _dbPath;
  SupabaseConnector? _connector;
  StreamSubscription<ps.SyncStatus>? _syncStatusSubscription;
  WidgetRef? _ref;

  /// Obtiene el path de la base de datos SQLite
  /// Drift usará este mismo archivo para sus operaciones
  String get dbPath {
    if (_dbPath == null) {
      throw StateError(
          'PowerSync no ha sido inicializado. Llama a initialize() primero.');
    }
    return _dbPath!;
  }

  /// Obtiene la instancia de PowerSyncDatabase
  ps.PowerSyncDatabase get database {
    if (_database == null) {
      throw StateError(
          'PowerSync no ha sido inicializado. Llama a initialize() primero.');
    }
    return _database!;
  }

  /// Indica si PowerSync está inicializado
  bool get isInitialized => _database != null;

  /// Inicializa PowerSync con el cliente de Supabase
  /// [ref] - WidgetRef para actualizar el SyncStatusProvider
  Future<void> initialize(SupabaseClient supabase, {WidgetRef? ref}) async {
    if (_database != null) {
      return; // Ya inicializado
    }

    _ref = ref;
    _log('Inicializando PowerSync...');

    // Obtener el directorio de documentos
    final dir = await getApplicationDocumentsDirectory();
    _dbPath = p.join(dir.path, 'finanzas_familiares_powersync.db');

    _log('Database path: $_dbPath');

    // Crear la base de datos de PowerSync
    _database = ps.PowerSyncDatabase(
      schema: schema,
      path: _dbPath!,
    );

    // Crear el conector de Supabase con callbacks
    _connector = SupabaseConnector(
      supabase,
      onSyncError: _onSyncError,
      onSyncComplete: _onSyncComplete,
    );

    // Inicializar la base de datos
    await _database!.initialize();
    _log('PowerSync database inicializada');

    // Configurar listener de estado de sync
    _setupSyncStatusListener();

    // Conectar con el backend (si hay credenciales disponibles)
    await _connectIfAuthenticated();
  }

  /// Configura el listener para cambios de estado de sync
  void _setupSyncStatusListener() {
    _syncStatusSubscription?.cancel();
    _syncStatusSubscription = _database!.statusStream.listen(
      _handleSyncStatusChange,
      onError: (error) {
        _log('Error en statusStream: $error');
        _onSyncError('Error de sincronización: $error');
      },
    );
  }

  /// Maneja cambios en el estado de sincronización
  void _handleSyncStatusChange(ps.SyncStatus status) {
    _log('SyncStatus: connected=${status.connected}, '
        'downloading=${status.downloading}, '
        'uploading=${status.uploading}');

    _ref?.read(syncStatusProvider.notifier).updateFromPowerSync(
          connected: status.connected,
          downloading: status.downloading,
          uploading: status.uploading,
        );

    // Si completó sync, marcar timestamp
    if (!status.downloading && !status.uploading && status.connected) {
      _ref?.read(syncStatusProvider.notifier).markSynced();
    }
  }

  /// Callback cuando hay error de sync
  void _onSyncError(String error) {
    _log('Error de sync: $error');
    _ref?.read(syncStatusProvider.notifier).addError(error);
  }

  /// Callback cuando sync completa exitosamente
  void _onSyncComplete() {
    _log('Sync completado');
    _ref?.read(syncStatusProvider.notifier).markSynced();
  }

  /// Conecta con PowerSync si el usuario está autenticado
  Future<void> _connectIfAuthenticated() async {
    if (_database == null || _connector == null) return;

    try {
      final credentials = await _connector!.fetchCredentials();
      if (credentials != null) {
        _log('Conectando con PowerSync...');
        await _database!.connect(connector: _connector!);
        _log('Conectado a PowerSync');
      } else {
        _log('Sin credenciales - modo offline');
        _ref?.read(syncStatusProvider.notifier).setOfflineMode();
      }
    } catch (e) {
      _log('Error conectando a PowerSync: $e');
      _onSyncError('Error de conexión: $e');
      // Si falla la conexión, continuamos en modo offline
    }
  }

  /// Reconecta después de login
  Future<void> reconnect() async {
    if (_database == null || _connector == null) return;

    _log('Reconectando a PowerSync...');

    try {
      await _database!.connect(connector: _connector!);
      _log('Reconectado exitosamente');
    } catch (e) {
      _log('Error en reconexión: $e');
      _onSyncError('Error al reconectar: $e');
    }
  }

  /// Desconecta (logout)
  Future<void> disconnect() async {
    _log('Desconectando de PowerSync...');
    await _database?.disconnect();
    _ref?.read(syncStatusProvider.notifier).setOfflineMode();
  }

  /// Fuerza sincronización completa
  Future<void> sync() async {
    if (_database == null) return;

    _log('Forzando sincronización...');

    try {
      // Esperar a que se complete una sincronización
      await _database!.waitForFirstSync();
      _log('Sincronización completa');
    } catch (e) {
      _log('Error en sync forzado: $e');
      _onSyncError('Error de sincronización: $e');
    }
  }

  /// Cierra la base de datos
  Future<void> close() async {
    _log('Cerrando PowerSync...');
    _syncStatusSubscription?.cancel();
    await _database?.close();
    _database = null;
    _dbPath = null;
    _connector = null;
    _ref = null;
    _instance = null;
  }

  /// Log interno para debugging
  void _log(String message) {
    developer.log(
      message,
      name: 'PowerSyncManager',
    );
  }
}
