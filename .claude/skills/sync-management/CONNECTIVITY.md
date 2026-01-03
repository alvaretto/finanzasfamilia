# Manejo de Conectividad

## Verificacion de Conexion

```dart
import 'package:connectivity_plus/connectivity_plus.dart';

Future<bool> hasConnection() async {
  final results = await Connectivity().checkConnectivity();
  return results.any((r) => r != ConnectivityResult.none);
}
```

## Escuchar Cambios de Conectividad

```dart
class MyNotifier extends StateNotifier<MyState> {
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  void _init() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
      (results) {
        final hasConnection = results.any((r) => r != ConnectivityResult.none);
        if (hasConnection && !state.isSyncing) {
          syncData(showError: false);
        }
      },
    );
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}
```

## Estados de Conexion

```dart
enum ConnectionState {
  online,       // Conexion activa
  offline,      // Sin conexion
  syncing,      // Sincronizando
  syncPending,  // Cambios locales pendientes
}

// En UI
Widget buildConnectionIndicator(ConnectionState state) {
  return switch (state) {
    ConnectionState.online => Icon(Icons.cloud_done, color: Colors.green),
    ConnectionState.offline => Icon(Icons.cloud_off, color: Colors.grey),
    ConnectionState.syncing => CircularProgressIndicator(),
    ConnectionState.syncPending => Icon(Icons.cloud_upload, color: Colors.orange),
  };
}
```

## Modo Offline Graceful

```dart
Future<T> executeWithFallback<T>({
  required Future<T> Function() onlineAction,
  required Future<T> Function() offlineAction,
}) async {
  if (await hasConnection()) {
    try {
      return await onlineAction();
    } catch (e) {
      // Fallback a offline si falla la red
      return await offlineAction();
    }
  }
  return await offlineAction();
}

// Uso
final accounts = await executeWithFallback(
  onlineAction: () => _fetchFromSupabase(),
  offlineAction: () => _fetchFromDrift(),
);
```

## Deteccion de Tipo de Conexion

```dart
Future<void> smartSync() async {
  final results = await Connectivity().checkConnectivity();

  if (results.contains(ConnectivityResult.wifi)) {
    // WiFi: sync completo
    await fullSync();
  } else if (results.contains(ConnectivityResult.mobile)) {
    // Datos moviles: solo cambios criticos
    await lightSync();
  }
  // Sin conexion: no hacer nada
}
```

## Retry con Conectividad

```dart
Future<void> retryWhenOnline(Future<void> Function() action) async {
  if (await hasConnection()) {
    await action();
    return;
  }

  // Esperar conexion
  await for (final results in Connectivity().onConnectivityChanged) {
    if (results.any((r) => r != ConnectivityResult.none)) {
      await action();
      break;
    }
  }
}
```
