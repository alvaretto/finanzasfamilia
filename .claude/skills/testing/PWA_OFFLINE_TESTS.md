# PWA/Offline Testing Guide

## Objetivo
Verificar que la app funciona correctamente sin conexion a internet y sincroniza datos cuando vuelve la conexion.

## Test Mode de Supabase

```dart
// En setUpAll()
SupabaseClientProvider.enableTestMode();

// En tearDownAll()
SupabaseClientProvider.reset();
```

## Tests Implementados

### 1. Operaciones CRUD Offline
- Crear, leer, actualizar, eliminar sin conexion
- Verificar que `isSynced = false` en registros nuevos
- Verificar persistencia en DB local

### 2. Sync Queue
- Registros no sincronizados se acumulan
- `getUnsyncedAccounts()` retorna cola correcta
- `syncWithSupabase()` no falla sin conexion

### 3. Batch Operations
- Multiples operaciones en paralelo
- Transacciones concurrentes
- No bloqueo de UI

### 4. Error Handling
- Errores de red no crashean app
- Estado local se preserva tras error
- Retry automatico cuando vuelve conexion

## Patrones de Test

### Test Offline-First Basico
```dart
test('Operacion funciona offline', () async {
  final repo = MyRepository(); // Usara test mode

  // Crear dato
  final item = await repo.create(myData);

  // Verificar estado local
  expect(item.isSynced, false);

  // Sync no falla
  await expectLater(
    repo.syncWithSupabase(userId),
    completes,
  );
});
```

### Test de Persistencia
```dart
test('Datos persisten', () async {
  final repo1 = MyRepository();
  await repo1.create(myData);

  // Nueva instancia
  final repo2 = MyRepository();
  final found = await repo2.getById(id);

  expect(found, isNotNull);
});
```

## Metricas

- Creacion de registro: < 100ms
- Lectura por ID: < 50ms
- Query con filtro: < 200ms
- Sync completo: < 5s (100 registros)
