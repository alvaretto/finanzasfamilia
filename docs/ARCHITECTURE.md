# Arquitectura Offline-First

## Filosofía

La aplicación está diseñada bajo el principio **"Local First, Sync Later"**:

1. **Todas las operaciones son locales primero** - El usuario nunca espera por la red
2. **La sincronización es transparente** - Ocurre en background cuando hay conexión
3. **Los conflictos se resuelven automáticamente** - Last-write-wins con timestamps

## Capas de la Arquitectura

```
┌─────────────────────────────────────────────────────┐
│                  PRESENTATION                        │
│  (Screens, Widgets, Theme)                          │
│  - Material 3 Design                                │
│  - Riverpod para estado reactivo                    │
└─────────────────────────┬───────────────────────────┘
                          │
┌─────────────────────────▼───────────────────────────┐
│                  APPLICATION                         │
│  (Providers, Services)                              │
│  - AsyncNotifiers para operaciones async            │
│  - Streams para datos reactivos                     │
└─────────────────────────┬───────────────────────────┘
                          │
┌─────────────────────────▼───────────────────────────┐
│                    DOMAIN                            │
│  (Entities, Repositories, Services)                 │
│  - AccountingService (Partida Doble)                │
│  - Modelos con Freezed                              │
└─────────────────────────┬───────────────────────────┘
                          │
┌─────────────────────────▼───────────────────────────┐
│                     DATA                             │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐ │
│  │   LOCAL     │  │    SYNC     │  │   REMOTE    │ │
│  │   (Drift)   │◄─┤ (PowerSync) ├─►│ (Supabase)  │ │
│  │   SQLite    │  │             │  │  Postgres   │ │
│  └─────────────┘  └─────────────┘  └─────────────┘ │
└─────────────────────────────────────────────────────┘
```

## Flujo de Datos

### Escritura (Create/Update/Delete)

```
Usuario → UI → Provider → DAO → SQLite Local
                                     │
                                     ▼
                              PowerSync Queue
                                     │
                              (Cuando online)
                                     ▼
                              Supabase (Postgres)
```

### Lectura

```
SQLite Local → DAO → Provider → UI
     ▲
     │ (Sync en background)
     │
PowerSync ← Supabase
```

## Componentes Clave

### 1. Drift (Base de Datos Local)

```dart
// Tablas definidas en lib/data/local/tables/
@DataClassName('TransactionEntry')
class Transactions extends Table {
  TextColumn get id => text()();
  RealColumn get amount => real()();
  // ...
}

// DAOs en lib/data/local/daos/
@DriftAccessor(tables: [Transactions])
class TransactionsDao extends DatabaseAccessor<AppDatabase> {
  Stream<List<TransactionEntry>> watchAll();
  Future<void> insert(TransactionsCompanion entry);
}
```

### 2. Riverpod 3.0 (Estado)

```dart
// Provider de DAO
@riverpod
TransactionsDao transactionsDao(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  return TransactionsDao(db);
}

// Stream Provider para datos reactivos
@riverpod
Stream<List<TransactionEntry>> transactions(Ref ref) {
  final dao = ref.watch(transactionsDaoProvider);
  return dao.watchAll();
}

// AsyncNotifier para operaciones
@riverpod
class TransactionsNotifier extends _$TransactionsNotifier {
  Future<void> create({...}) async {
    final dao = ref.read(transactionsDaoProvider);
    await dao.insert(...);
    ref.invalidateSelf(); // Refresh
  }
}
```

### 3. PowerSync (Sincronización)

```dart
// Configuración en lib/data/sync/
class PowerSyncConnector {
  Future<void> initialize();
  Stream<SyncStatus> get statusStream;
  Future<void> sync();
}
```

### 4. AccountingService (Partida Doble)

El usuario ve un formulario simple, pero internamente se registran asientos contables:

```dart
// Usuario: "Compré café por $5,000 con Nequi"
// Sistema registra:
await accountingService.recordExpense(
  amount: 5000,
  expenseCategory: 'Gastos:Alimentación:Restaurantes',
  paymentAccount: 'Activos:Bancos:Nequi',
);

// Genera 2 journal entries:
// Dr. Gastos:Alimentación:Restaurantes  $5,000
// Cr. Activos:Bancos:Nequi              $5,000
```

## Estrategia de Conflictos

### Last-Write-Wins

```dart
// Cada registro tiene timestamps
DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

// PowerSync usa updatedAt para resolver conflictos
// El registro más reciente gana
```

### Soft Deletes

```dart
// Nunca eliminamos físicamente, solo marcamos
BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
DateTimeColumn get deletedAt => dateTime().nullable()();
```

## Manejo de Conectividad

```dart
// SyncStatusProvider detecta cambios de red
@riverpod
class SyncStatusNotifier extends _$SyncStatusNotifier {
  void _onConnectivityChanged(ConnectivityResult result) {
    if (result != ConnectivityResult.none) {
      _triggerSync(); // Auto-sync cuando vuelve la conexión
    }
  }
}

// UI muestra estado de sincronización
// - Verde: Sincronizado
// - Amarillo: Sincronizando
// - Gris: Offline (cambios pendientes)
// - Rojo: Error de sincronización
```

## Migraciones de Base de Datos

```dart
@override
int get schemaVersion => 3;

@override
MigrationStrategy get migration => MigrationStrategy(
  onCreate: (m) async {
    await m.createAll();
  },
  onUpgrade: (m, from, to) async {
    if (from < 2) {
      // Migración v1 → v2
    }
    if (from < 3) {
      // Migración v2 → v3: RecurringTransactions
      await m.createTable(recurringTransactions);
    }
  },
);
```

## Principios de Diseño

1. **Nunca bloquear la UI por red** - Usar optimistic updates
2. **Datos locales son la fuente de verdad** - La nube es backup
3. **Mínima latencia** - El usuario ve cambios instantáneamente
4. **Resiliente a desconexión** - Funciona 100% offline
5. **Sincronización incremental** - Solo cambios, no datos completos
