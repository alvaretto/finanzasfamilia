# Estrategia de Sincronización

## Arquitectura de Sync

```
┌─────────────────────────────────────────────────────────────────┐
│                         CLIENTE                                  │
│  ┌─────────────────┐      ┌─────────────────┐                   │
│  │   Drift/SQLite  │◄────►│   PowerSync     │                   │
│  │   (Local DB)    │      │   (Sync Engine) │                   │
│  └─────────────────┘      └────────┬────────┘                   │
│                                    │                             │
└────────────────────────────────────┼─────────────────────────────┘
                                     │ WebSocket / HTTP
                                     ▼
┌────────────────────────────────────────────────────────────────┐
│                        POWERSYNC SERVICE                        │
│  ┌─────────────────┐      ┌─────────────────┐                  │
│  │   Sync Rules    │      │   Conflict      │                  │
│  │   (Bucket Def)  │      │   Resolution    │                  │
│  └─────────────────┘      └─────────────────┘                  │
│                                    │                            │
└────────────────────────────────────┼────────────────────────────┘
                                     │
                                     ▼
┌────────────────────────────────────────────────────────────────┐
│                         SUPABASE                                │
│  ┌─────────────────┐      ┌─────────────────┐                  │
│  │   PostgreSQL    │      │   Auth          │                  │
│  │   (Source DB)   │      │   (User Auth)   │                  │
│  └─────────────────┘      └─────────────────┘                  │
└────────────────────────────────────────────────────────────────┘
```

## Flujo de Sincronización

### 1. Escritura (Optimistic Update)

```dart
// 1. Usuario crea transacción
await transactionsDao.insert(newTransaction);

// 2. UI se actualiza inmediatamente (optimistic)
// El stream de Drift notifica a los listeners

// 3. PowerSync detecta cambio local
// Lo agrega a la cola de sync

// 4. Cuando hay conexión, PowerSync envía a Supabase
// El cambio se persiste en PostgreSQL

// 5. Otros dispositivos del usuario reciben el cambio
// via PowerSync real-time sync
```

### 2. Lectura (Local First)

```dart
// Siempre lee de SQLite local
Stream<List<TransactionEntry>> watchAll() {
  return (select(transactions)
    ..orderBy([(t) => OrderingTerm.desc(t.date)]))
    .watch();
}

// PowerSync actualiza SQLite en background
// Los streams de Drift notifican automáticamente
```

### 3. Conflictos (Last-Write-Wins)

```dart
// Cada registro tiene timestamps
class BaseTable extends Table {
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

// PowerSync usa updatedAt para resolver conflictos
// El registro con updatedAt más reciente gana
```

## Configuración de PowerSync

### Schema Sync

```dart
// lib/data/sync/schema.dart
final schema = Schema([
  Table('transactions', [
    Column.text('id'),
    Column.text('type'),
    Column.real('amount'),
    Column.text('description'),
    Column.text('account_id'),
    Column.text('category_id'),
    Column.integer('date'),
    Column.integer('created_at'),
    Column.integer('updated_at'),
  ]),
  // ... más tablas
]);
```

### Connector

```dart
// lib/data/sync/powersync_connector.dart
class PowerSyncConnector extends PowerSyncBackendConnector {
  final SupabaseClient supabase;

  @override
  Future<PowerSyncCredentials?> fetchCredentials() async {
    final session = supabase.auth.currentSession;
    if (session == null) return null;

    return PowerSyncCredentials(
      endpoint: powerSyncUrl,
      token: session.accessToken,
      userId: session.user.id,
    );
  }

  @override
  Future<void> uploadData(PowerSyncDatabase database) async {
    final batch = await database.getCrudBatch();
    if (batch == null) return;

    for (final op in batch.crud) {
      await _uploadOperation(op);
    }

    await batch.complete();
  }
}
```

## Estados de Sincronización

```dart
enum SyncStatus {
  /// Conectado y sincronizado
  synced,

  /// Sincronizando activamente
  syncing,

  /// Desconectado, cambios pendientes
  offline,

  /// Error de sincronización
  error,
}
```

### Provider de Estado

```dart
@riverpod
class SyncStatusNotifier extends _$SyncStatusNotifier {
  @override
  SyncState build() => SyncState.disconnected();

  void updateStatus(SyncStatus status) {
    state = state.copyWith(
      status: status,
      lastStatusChange: DateTime.now(),
    );
  }

  void markSynced() {
    state = state.copyWith(
      status: SyncStatus.synced,
      lastSyncTime: DateTime.now(),
    );
  }

  void addError(String error) {
    state = state.copyWith(
      status: SyncStatus.error,
      errors: [...state.errors, error],
    );
  }
}
```

## UI de Estado de Sync

```dart
class SyncStatusIndicator extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(syncStatusProvider);

    return Icon(
      _getIcon(status.status),
      color: _getColor(status.status),
    );
  }

  IconData _getIcon(SyncStatus status) {
    switch (status) {
      case SyncStatus.synced:
        return Icons.cloud_done;
      case SyncStatus.syncing:
        return Icons.sync;
      case SyncStatus.offline:
        return Icons.cloud_off;
      case SyncStatus.error:
        return Icons.cloud_error;
    }
  }

  Color _getColor(SyncStatus status) {
    switch (status) {
      case SyncStatus.synced:
        return Colors.green;
      case SyncStatus.syncing:
        return Colors.orange;
      case SyncStatus.offline:
        return Colors.grey;
      case SyncStatus.error:
        return Colors.red;
    }
  }
}
```

## Manejo de Conectividad

```dart
// Detectar cambios de red
@riverpod
class ConnectivityNotifier extends _$ConnectivityNotifier {
  StreamSubscription? _subscription;

  @override
  ConnectivityResult build() {
    _subscription = Connectivity().onConnectivityChanged.listen((result) {
      state = result;
      _onConnectivityChanged(result);
    });

    ref.onDispose(() => _subscription?.cancel());

    return ConnectivityResult.none;
  }

  void _onConnectivityChanged(ConnectivityResult result) {
    if (result != ConnectivityResult.none) {
      // Reconectado - trigger sync
      ref.read(syncStatusProvider.notifier).triggerSync();
    }
  }
}
```

## Estrategia de Retry

```dart
class SyncRetryStrategy {
  static const maxRetries = 3;
  static const initialDelay = Duration(seconds: 1);

  Future<void> syncWithRetry() async {
    var retries = 0;
    var delay = initialDelay;

    while (retries < maxRetries) {
      try {
        await _performSync();
        return; // Éxito
      } catch (e) {
        retries++;
        if (retries >= maxRetries) rethrow;

        await Future.delayed(delay);
        delay *= 2; // Exponential backoff
      }
    }
  }
}
```

## Tablas Sincronizadas

| Tabla | Sync | Notas |
|-------|------|-------|
| categories | ✅ | Taxonomía compartida |
| accounts | ✅ | Cuentas del usuario |
| transactions | ✅ | Transacciones financieras |
| transaction_details | ✅ | Detalles de compras |
| journal_entries | ✅ | Asientos contables |
| budgets | ✅ | Presupuestos mensuales |
| recurring_transactions | ✅ | Pagos automáticos |
| measurement_units | ❌ | Solo local (catálogo fijo) |
| places | ✅ | Lugares personalizados |
| payment_methods | ✅ | Métodos de pago |

## Consideraciones de Seguridad

### Row-Level Security (RLS)

```sql
-- En Supabase, cada tabla tiene RLS
-- Solo el dueño puede ver sus datos
CREATE POLICY "Users can only access own data"
ON transactions
FOR ALL
USING (auth.uid() = user_id);
```

### Datos Sensibles

- Tokens de auth NUNCA se sincronizan
- Credenciales bancarias NUNCA se almacenan
- Montos y transacciones están cifrados en tránsito (TLS)

## Métricas de Sync

```dart
// Monitorear salud de sync
class SyncMetrics {
  DateTime? lastSuccessfulSync;
  int pendingChanges;
  int failedAttempts;
  Duration? averageSyncTime;

  bool get isHealthy =>
    failedAttempts < 3 &&
    pendingChanges < 100 &&
    (lastSuccessfulSync == null ||
     DateTime.now().difference(lastSuccessfulSync!) < Duration(hours: 24));
}
```
