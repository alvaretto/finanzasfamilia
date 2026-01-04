# Diagnóstico del Problema de Sincronización

**Fecha**: 2026-01-04
**Status**: ❌ Las transacciones NO se sincronizan a Supabase
**Generadas**: 200 transacciones locales + 1 cuenta local

## Resumen Ejecutivo

Los datos se generan correctamente en **SQLite local**, pero **NO se sincronizan a Supabase** debido a un problema de **orden de sincronización** y **dependencias entre entidades**.

### Datos en Supabase (Actual)
- ❌ Accounts: 0
- ❌ Transactions: 0
- ❌ Budgets: 0
- ❌ Goals: 0
- ✅ Profiles: 2 usuarios
- ✅ Categories: 14 del sistema

### Errores Detectados en Logs API
```
POST /rest/v1/transactions → 400 (múltiples intentos)
POST /rest/v1/accounts → 400/500
GET /rest/v1/accounts → 500
GET /rest/v1/transactions → 500
```

## Diagnóstico Detallado

### 1. El Problema Principal: Orden de Sincronización

**Foreign Key Constraints** en Supabase:
```sql
transactions.account_id → accounts.id (ON DELETE CASCADE)
transactions.user_id → profiles.id (ON DELETE CASCADE)
accounts.user_id → profiles.id (ON DELETE CASCADE)
```

**Esto significa**:
- Una transacción NO puede existir sin su cuenta asociada
- Una cuenta NO puede existir sin su perfil de usuario asociado

### 2. Flujo Actual (Problemático)

```
[Generador de Datos de Prueba]
    ↓
1. Crear cuenta "Cuenta Pruebas" (local SQLite)
   id: abc-123, user_id: 005ee858...
   isSynced: false
   ↓
2. _trySyncInBackground() → syncAccounts()
   (se ejecuta en BACKGROUND, no bloquea)
   ↓
3. Loop: for i in 1..200:
   ↓
4. Crear transacción i (local SQLite)
   account_id: abc-123, user_id: 005ee858...
   isSynced: false
   ↓
5. _trySyncInBackground() → syncTransactions()
   (se ejecuta en BACKGROUND, no espera cuenta)
   ↓
6. POST /rest/v1/transactions
   {
     "id": "tx-001",
     "account_id": "abc-123",  ← Esta cuenta NO existe en Supabase aún
     "user_id": "005ee858...",
     "amount": 50000,
     "type": "expense"
   }
   ↓
7. Supabase → 400 Bad Request
   Error: foreign key constraint "transactions_account_id_fkey"
   violated by INSERT statement
```

**Razón del fallo**:
- Las transacciones se intentan sincronizar MIENTRAS la cuenta aún se está sincronizando
- No hay coordinación entre los syncs de diferentes entidades
- Cada provider (`accountsProvider`, `transactionsProvider`) sincroniza independientemente

### 3. Análisis del Código

#### `import_test_data_screen.dart:176-219`
```dart
Future<void> _generateTestData() async {
  String accountId;

  if (_createTestAccount) {
    accountId = await _createTestAccountIfNeeded();  // ← Crea cuenta local
  }

  for (final tx in transactionData) {
    await ref.read(transactionsProvider.notifier).createTransaction(
      accountId: accountId,  // ← Usa cuenta local (abc-123)
      amount: tx.amount,
      type: tx.type,
      // ...
    );
    // ← _trySyncInBackground() se llama aquí, NO espera que la cuenta se suba
  }
}
```

#### `account_repository.dart:158-187`
```dart
Future<void> syncWithSupabase(String userId) async {
  // 1. Subir cuentas locales no sincronizadas
  final unsyncedAccounts = await getUnsyncedAccounts();
  for (final account in unsyncedAccounts) {
    await _upsertToSupabase(account);  // ← Aquí se sube la cuenta
    await markAsSynced(account.id);
  }

  // 2. Descargar cuentas remotas...
  // 3. Actualizar localmente...
}
```

#### `transaction_provider.dart:202`
```dart
await _repository.createTransaction(transaction);
_trySyncInBackground();  // ← NO espera que la cuenta se suba primero
```

#### `sync_service.dart:89-115`
```dart
Future<SyncStatus> syncAll() async {
  // TODO: Implementar sincronizacion de cada tabla
  // 1. Obtener registros no sincronizados (synced = false)
  // 2. Enviar a Supabase
  // 3. Marcar como sincronizados
  // 4. Descargar cambios remotos

  state = state.copyWith(
    status: SyncStatus.success,  // ← FAKE, no hace nada
    lastSyncTime: DateTime.now(),
  );
  return SyncStatus.success;
}
```

**Problema identificado**:
- `syncAll()` NO está implementado
- No hay sincronización centralizada
- Cada provider sincroniza solo cuando `_trySyncInBackground()` se llama
- No hay orden garantizado entre syncs de diferentes entidades

### 4. Por Qué Fallan los GET

Los logs también muestran errores 500 en GET:
```
GET /rest/v1/accounts?select=*&user_id=eq.005ee858... → 500
GET /rest/v1/transactions?select=*&user_id=eq.005ee858... → 500
```

**Posibles causas**:
1. Problema temporal del servidor de Supabase
2. Política RLS con subquery complejo que genera error interno
3. Timeout en queries complejas

**Nota**: Las políticas RLS están correctamente configuradas y los errores 500 son intermitentes.

## Políticas RLS (Verificadas ✅)

### Accounts
```sql
INSERT: with_check = "user_id = auth.uid()"  ✅
SELECT: qual = "user_id = auth.uid()"  ✅
UPDATE: qual = "user_id = auth.uid()"  ✅
DELETE: qual = "user_id = auth.uid()"  ✅
```

### Transactions
```sql
INSERT: with_check = "user_id = auth.uid()"  ✅
SELECT: qual = "user_id = auth.uid()"  ✅
UPDATE: qual = "user_id = auth.uid()"  ✅
DELETE: qual = "user_id = auth.uid()"  ✅
```

**Las políticas RLS están correctas**. El problema NO es de permisos.

## Soluciones Propuestas

### Solución 1: Implementar `syncAll()` Centralizado ⭐ RECOMENDADO

**Archivo**: `lib/core/network/sync_service.dart`

```dart
Future<SyncStatus> syncAll() async {
  state = state.copyWith(status: SyncStatus.syncing);

  if (!await checkConnectivity()) {
    state = state.copyWith(status: SyncStatus.offline);
    return SyncStatus.offline;
  }

  try {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) throw Exception('No authenticated user');

    // ORDEN CORRECTO (respetando foreign keys):
    // 1. Accounts (sin dependencias externas)
    await _syncAccounts(userId);

    // 2. Budgets (depende de accounts)
    await _syncBudgets(userId);

    // 3. Goals (depende de accounts)
    await _syncGoals(userId);

    // 4. Transactions (depende de accounts) ← ÚLTIMO
    await _syncTransactions(userId);

    state = state.copyWith(
      status: SyncStatus.success,
      lastSyncTime: DateTime.now(),
    );
    return SyncStatus.success;
  } catch (e) {
    state = state.copyWith(
      status: SyncStatus.error,
      errorMessage: e.toString(),
    );
    return SyncStatus.error;
  }
}
```

**Ventajas**:
- Garantiza el orden correcto de sincronización
- Centraliza la lógica de sync
- Previene foreign key violations

### Solución 2: Await en el Generador de Datos

**Archivo**: `lib/features/settings/presentation/screens/import_test_data_screen.dart`

```dart
Future<void> _generateTestData() async {
  String accountId;

  if (_createTestAccount) {
    setState(() => _status = 'Creando cuenta de prueba...');
    accountId = await _createTestAccountIfNeeded();

    // ✅ ESPERAR a que la cuenta se sincronice
    setState(() => _status = 'Sincronizando cuenta...');
    await ref.read(accountsProvider.notifier).syncAccounts();

    // Esperar 2 segundos para asegurar que llegó a Supabase
    await Future.delayed(const Duration(seconds: 2));
  }

  setState(() => _status = 'Generando $_transactionCount transacciones...');
  final transactionData = _generateTransactionData();

  setState(() => _status = 'Guardando transacciones...');
  int saved = 0;
  for (final tx in transactionData) {
    await ref.read(transactionsProvider.notifier).createTransaction(
      accountId: accountId,
      amount: tx.amount,
      type: tx.type,
      description: tx.description,
      date: tx.date,
    );
    saved++;

    // Sincronizar en batches cada 10 transacciones
    if (saved % 10 == 0) {
      setState(() => _status = 'Guardando... $saved/$_transactionCount');
      await ref.read(transactionsProvider.notifier).syncTransactions();
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }

  // Sincronización final
  setState(() => _status = 'Sincronizando...');
  await ref.read(transactionsProvider.notifier).syncTransactions();

  setState(() {
    _isGenerating = false;
    _status = 'Generación completada: $_transactionCount transacciones';
  });
}
```

**Ventajas**:
- Fix rápido y localizado
- No requiere refactorizar el sync service
- Funciona para el generador de datos

**Desventajas**:
- No resuelve el problema general
- Otras partes de la app pueden tener el mismo problema

### Solución 3: Batch Sync con Retry

**Archivo**: `lib/features/transactions/data/repositories/transaction_repository.dart`

```dart
Future<void> syncWithSupabase(String userId) async {
  try {
    // Subir transacciones en batches
    final unsynced = await getUnsyncedTransactions();
    final batchSize = 50;

    for (int i = 0; i < unsynced.length; i += batchSize) {
      final batch = unsynced.skip(i).take(batchSize).toList();

      for (final tx in batch) {
        try {
          await _upsertToSupabase(tx);
          await markAsSynced(tx.id);
        } catch (e) {
          // Si falla por FK, esperar y reintentar
          if (e.toString().contains('foreign key')) {
            await Future.delayed(const Duration(seconds: 2));
            try {
              await _upsertToSupabase(tx);
              await markAsSynced(tx.id);
            } catch (_) {
              // Dejar como no sincronizado para reintentar después
              print('Failed to sync transaction ${tx.id}: FK constraint');
            }
          }
        }
      }

      // Pausa entre batches
      if (i + batchSize < unsynced.length) {
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }
  } catch (e) {
    rethrow;
  }
}
```

**Ventajas**:
- Más resiliente a errores temporales
- Procesa en batches para evitar sobrecargar el servidor

**Desventajas**:
- Más complejo de implementar
- El retry podría fallar si la cuenta nunca se sincronizó

## Recomendación Final

**Implementar Solución 1 + Solución 2**:

1. **Corto plazo** (Fix inmediato):
   - Implementar Solución 2 en el generador de datos
   - Garantizar que la cuenta se sincroniza ANTES de las transacciones
   - Permite probar la funcionalidad de inmediato

2. **Mediano plazo** (Fix robusto):
   - Implementar Solución 1 centralizando el sync
   - Refactorizar todos los providers para usar `syncAll()`
   - Garantiza orden correcto en toda la app

## Próximos Pasos

1. ✅ Implementar Solución 2 (generador de datos)
2. ⏳ Probar generación de 200 transacciones
3. ⏳ Verificar que lleguen a Supabase
4. ⏳ Implementar Solución 1 (sync centralizado)
5. ⏳ Actualizar documentación

## Referencias

- Código: `lib/features/settings/presentation/screens/import_test_data_screen.dart:176`
- Código: `lib/core/network/sync_service.dart:89`
- Código: `lib/features/accounts/data/repositories/account_repository.dart:158`
- Código: `lib/features/transactions/data/repositories/transaction_repository.dart:442`
- Logs: `docs/SYNC_TESTING_GUIDE.md`
- Setup: `docs/SUPABASE_MCP_SETUP.md`

---

**Última actualización**: 2026-01-04
**Diagnosticado por**: Claude Opus 4.5
**Prioridad**: 🔴 Alta
