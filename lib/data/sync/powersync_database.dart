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

/// Nombre del archivo de base de datos compartido entre Drift y PowerSync
/// CRÍTICO: Ambos DEBEN usar el mismo archivo para que la sincronización funcione
const String kSharedDatabaseFileName = 'finanzas_familiares.db';

/// Estadísticas del upload queue de PowerSync
class UploadQueueStats {
  final int count;
  final int size;
  final String? error;

  UploadQueueStats({
    required this.count,
    required this.size,
    this.error,
  });

  bool get isEmpty => count == 0;
  bool get hasError => error != null;

  @override
  String toString() => 'UploadQueueStats(count: $count, error: $error)';
}

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

  /// Indica si se completó la primera sincronización
  bool _hasCompletedFirstSync = false;

  /// Completer para esperar la primera sincronización
  Completer<void>? _firstSyncCompleter;

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

  /// Indica si ya se completó la primera sincronización
  bool get hasCompletedFirstSync => _hasCompletedFirstSync;

  /// Inicializa PowerSync con el cliente de Supabase
  /// [ref] - WidgetRef para actualizar el SyncStatusProvider
  Future<void> initialize(SupabaseClient supabase, {WidgetRef? ref}) async {
    if (_database != null) {
      return; // Ya inicializado
    }

    _ref = ref;
    _log('Inicializando PowerSync...');

    // Obtener el directorio de documentos
    // IMPORTANTE: Usar el mismo path que Drift para compartir la base de datos
    final dir = await getApplicationDocumentsDirectory();
    _dbPath = p.join(dir.path, kSharedDatabaseFileName);

    _log('Database path (compartido con Drift): $_dbPath');

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
      _hasCompletedFirstSync = true;
      _log('Sincronización completa');
    } catch (e) {
      _log('Error en sync forzado: $e');
      _onSyncError('Error de sincronización: $e');
    }
  }

  /// Espera a que se complete la primera sincronización después de login
  /// Retorna true si se sincronizaron datos, false si timeout o error
  /// [timeout] - Tiempo máximo de espera (default: 30 segundos)
  Future<bool> waitForInitialSync({Duration timeout = const Duration(seconds: 30)}) async {
    if (_database == null) {
      _log('waitForInitialSync: PowerSync no inicializado');
      return false;
    }

    // Si ya sincronizó, retornar inmediatamente
    if (_hasCompletedFirstSync) {
      _log('waitForInitialSync: Ya se completó la primera sincronización');
      return true;
    }

    // Verificar si hay sesión activa
    final credentials = await _connector?.fetchCredentials();
    if (credentials == null) {
      _log('waitForInitialSync: Sin credenciales, modo offline');
      return false;
    }

    _log('waitForInitialSync: Esperando primera sincronización...');
    _firstSyncCompleter = Completer<void>();

    try {
      // Asegurarse de que está conectado
      if (!(_database!.currentStatus.connected)) {
        await _database!.connect(connector: _connector!);
      }

      // Esperar la primera sincronización con timeout
      await _database!.waitForFirstSync().timeout(
        timeout,
        onTimeout: () {
          _log('waitForInitialSync: Timeout esperando sincronización');
          throw TimeoutException('Timeout esperando sincronización inicial');
        },
      );

      _hasCompletedFirstSync = true;
      _firstSyncCompleter?.complete();
      _log('waitForInitialSync: Primera sincronización completada');
      return true;
    } on TimeoutException {
      _log('waitForInitialSync: Timeout - continuando sin esperar');
      _firstSyncCompleter?.complete();
      return false;
    } catch (e) {
      _log('waitForInitialSync: Error - $e');
      _firstSyncCompleter?.completeError(e);
      return false;
    } finally {
      _firstSyncCompleter = null;
    }
  }

  /// Reconecta y espera sincronización inicial (para usar después de login)
  /// Retorna true si la sincronización fue exitosa
  Future<bool> reconnectAndSync({Duration timeout = const Duration(seconds: 30)}) async {
    _log('reconnectAndSync: Iniciando reconexión post-login...');

    // Resetear el flag de sincronización para forzar nueva descarga
    _hasCompletedFirstSync = false;

    // Reconectar
    await reconnect();

    // Monitorear upload queue antes de sincronizar
    await _monitorUploadQueue();

    // Esperar sincronización
    final result = await waitForInitialSync(timeout: timeout);

    // Monitorear upload queue después de sincronizar
    await _monitorUploadQueue();

    return result;
  }

  /// Obtiene estadísticas del upload queue
  /// CRÍTICO: Detecta si hay operaciones pendientes que no se han subido
  Future<UploadQueueStats> getUploadQueueStats() async {
    if (_database == null) {
      return UploadQueueStats(count: 0, size: 0);
    }

    try {
      final tx = await _database!.getNextCrudTransaction();
      if (tx == null) {
        return UploadQueueStats(count: 0, size: 0);
      }

      final count = tx.crud.length;
      _log('Upload queue: $count operaciones pendientes');

      // Log detallado de operaciones pendientes
      final byTable = <String, int>{};
      for (final op in tx.crud) {
        byTable[op.table] = (byTable[op.table] ?? 0) + 1;
      }
      for (final entry in byTable.entries) {
        _log('  - ${entry.key}: ${entry.value} ops');
      }

      return UploadQueueStats(count: count, size: count);
    } catch (e) {
      _log('Error obteniendo upload queue stats: $e');
      return UploadQueueStats(count: 0, size: 0, error: e.toString());
    }
  }

  /// Monitorea el upload queue y emite warnings si hay operaciones pendientes
  Future<void> _monitorUploadQueue() async {
    final stats = await getUploadQueueStats();

    if (stats.count > 0) {
      _log('WARNING: Upload queue tiene ${stats.count} operaciones pendientes');
      _ref?.read(syncStatusProvider.notifier).setPendingUploads(stats.count);

      if (stats.error != null) {
        _onSyncError('Error en upload queue: ${stats.error}');
      }
    } else {
      _log('Upload queue vacío - todos los datos sincronizados');
      _ref?.read(syncStatusProvider.notifier).setPendingUploads(0);
    }
  }

  /// Fuerza el procesamiento del upload queue
  /// Útil para reintentar uploads fallidos
  Future<bool> forceUpload() async {
    if (_database == null || _connector == null) {
      _log('forceUpload: PowerSync no inicializado');
      return false;
    }

    _log('forceUpload: Forzando upload de datos pendientes...');

    try {
      // Obtener todas las transacciones pendientes
      var tx = await _database!.getNextCrudTransaction();
      var totalProcessed = 0;

      while (tx != null) {
        _log('forceUpload: Procesando ${tx.crud.length} operaciones...');

        try {
          await _connector!.uploadData(_database!);
          totalProcessed += tx.crud.length;
          _log('forceUpload: Batch completado');
        } catch (e) {
          _log('forceUpload: Error en batch - $e');
          _onSyncError('Error subiendo datos: $e');
          return false;
        }

        // Obtener siguiente transacción
        tx = await _database!.getNextCrudTransaction();
      }

      _log('forceUpload: Completado - $totalProcessed operaciones procesadas');
      return true;
    } catch (e) {
      _log('forceUpload: Error general - $e');
      _onSyncError('Error en forceUpload: $e');
      return false;
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
