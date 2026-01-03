# Resolucion de Conflictos

## Estrategia: Last Write Wins (LWW)

Finanzas Familiares usa LWW con timestamps.

### Principio
```
Si local.updatedAt > remote.updatedAt:
  mantener local
sino:
  usar remote
```

### Implementacion

```dart
Future<void> resolveConflict(Model local, Model remote) async {
  final localTime = local.updatedAt ?? local.createdAt;
  final remoteTime = remote.updatedAt ?? remote.createdAt;

  if (localTime.isAfter(remoteTime)) {
    // Local gana - subir a Supabase
    await _supabase.from('table').upsert(local.toJson());
  } else {
    // Remote gana - actualizar local
    await _drift.update(tables).write(remote.toDrift());
  }
}
```

## Casos Especiales

### 1. Creacion Simultanea (mismo UUID)

Improbable con UUIDs, pero manejar:

```dart
if (local.id == remote.id && local.createdAt == remote.createdAt) {
  // Merge: combinar campos no-null de ambos
  final merged = local.copyWith(
    description: remote.description ?? local.description,
    notes: remote.notes ?? local.notes,
  );
  await _save(merged);
}
```

### 2. Eliminacion vs Actualizacion

```dart
// En Supabase: soft delete
// deleted_at: timestamp | null

if (remote.deletedAt != null && local.deletedAt == null) {
  // Remote fue eliminado pero local tiene cambios
  if (local.updatedAt.isAfter(remote.deletedAt)) {
    // Restaurar: local gana
    await _supabase.from('table').upsert({
      ...local.toJson(),
      'deleted_at': null,
    });
  } else {
    // Eliminar local
    await _drift.delete(local);
  }
}
```

### 3. Transacciones Dependientes

Si una transaccion referencia una cuenta eliminada:

```dart
Future<void> syncTransaction(Transaction tx) async {
  // Verificar que la cuenta existe
  final account = await _getAccount(tx.accountId);
  if (account == null) {
    // Reasignar a cuenta por defecto o marcar como huerfana
    tx = tx.copyWith(accountId: defaultAccountId);
  }
  await _sync(tx);
}
```

## Prevencion de Conflictos

### 1. Bloqueo Optimista

```dart
// Incluir version en updates
Future<void> updateWithVersion(Model item) async {
  final result = await _supabase
    .from('table')
    .update(item.toJson())
    .eq('id', item.id)
    .eq('version', item.version)  // Solo si version coincide
    .select();

  if (result.isEmpty) {
    // Conflicto detectado - refetch y reintentar
    final fresh = await _fetch(item.id);
    throw ConflictException(fresh);
  }
}
```

### 2. Timestamps Precisos

```dart
// Usar microsegundos para mayor precision
final now = DateTime.now().toUtc();
// ISO 8601 con microsegundos
final timestamp = now.toIso8601String();
```

## Logging de Conflictos

```dart
void logConflict(Model local, Model remote, String resolution) {
  // Solo en debug, nunca datos sensibles
  debugPrint('Conflict: ${local.id}');
  debugPrint('Resolution: $resolution');
  debugPrint('Local: ${local.updatedAt}');
  debugPrint('Remote: ${remote.updatedAt}');
}
```
