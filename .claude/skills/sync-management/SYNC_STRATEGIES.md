# Estrategias de Sincronizacion

## 1. Sync Automatico Silencioso

Los syncs automaticos NUNCA deben mostrar errores al usuario:

```dart
// En _init() del provider
_connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) {
  final hasConnection = results.any((r) => r != ConnectivityResult.none);
  if (hasConnection && !state.isSyncing) {
    syncData(showError: false);  // Silencioso
  }
});
```

### Cuando usar sync silencioso:
- Al iniciar la app
- Al recuperar conectividad
- En background cada N minutos
- Despues de operaciones CRUD locales

### Cuando mostrar errores:
- Cuando el usuario presiona "Sincronizar"
- Cuando el usuario hace pull-to-refresh

## 2. Sync en Background

```dart
void _trySyncInBackground() async {
  final results = await Connectivity().checkConnectivity();
  final hasConnection = results.any((r) => r != ConnectivityResult.none);
  if (hasConnection) {
    syncData(showError: false);
  }
}
```

Llamar despues de:
- `createItem()`
- `updateItem()`
- `deleteItem()`

## 3. Rate Limiting

Supabase tiene limites de rate. Implementar backoff:

```dart
int _retryCount = 0;
Duration _getBackoffDuration() {
  final seconds = math.pow(2, _retryCount).toInt().clamp(1, 32);
  return Duration(seconds: seconds);
}

Future<void> syncWithRetry() async {
  try {
    await syncData();
    _retryCount = 0;
  } catch (e) {
    _retryCount++;
    await Future.delayed(_getBackoffDuration());
    // Solo reintentar si hay conexion
  }
}
```

## 4. Batch Sync

Para listas grandes, sincronizar en batches:

```dart
Future<void> syncInBatches(List<Model> items, {int batchSize = 50}) async {
  for (var i = 0; i < items.length; i += batchSize) {
    final batch = items.skip(i).take(batchSize).toList();
    await _uploadBatch(batch);
    // Pequeña pausa entre batches
    await Future.delayed(const Duration(milliseconds: 100));
  }
}
```

## 5. Sync Selectivo

Solo sincronizar items modificados:

```dart
// En Drift table
BoolColumn get synced => boolean().withDefault(const Constant(false))();
DateTimeColumn get updatedAt => dateTime().nullable()();

// Query items pendientes
Future<List<Transaction>> getPendingSync() {
  return (select(transactions)..where((t) => t.synced.equals(false))).get();
}
```

## 6. Estado de Sync en UI

```dart
// En el provider state
class DataState {
  final bool isSyncing;
  final DateTime? lastSyncAt;
  final int pendingSyncCount;

  bool get hasPendingChanges => pendingSyncCount > 0;
}

// En UI
if (state.isSyncing) {
  return CircularProgressIndicator();
}
if (state.hasPendingChanges) {
  return Badge(label: '${state.pendingSyncCount}');
}
```
