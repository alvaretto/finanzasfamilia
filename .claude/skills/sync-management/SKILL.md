---
name: sync-management
description: Maneja sincronizacion offline-first entre SQLite local (Drift) y Supabase. Incluye sync silencioso, resolucion de conflictos, y manejo de conectividad. Usar cuando se implemente logica de sincronizacion, escenarios offline, o resolucion de conflictos.
---

# Sync Management

Skill para gestionar la sincronizacion offline-first en Finanzas Familiares.

## Quick Start

### Sync Silencioso (Background)
```dart
// No muestra errores al usuario - para syncs automaticos
await repository.syncWithSupabase(userId, showError: false);
```

### Sync Manual (Con feedback)
```dart
// Muestra errores - cuando el usuario solicita sync
await repository.syncWithSupabase(userId, showError: true);
```

## Arquitectura

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Widget    │────>│  Provider   │────>│ Repository  │
└─────────────┘     └─────────────┘     └─────────────┘
                                              │
                    ┌─────────────────────────┼─────────────────────────┐
                    │                         │                         │
                    v                         v                         v
              ┌───────────┐           ┌─────────────┐           ┌─────────────┐
              │   Drift   │           │  Supabase   │           │Connectivity │
              │  (Local)  │           │  (Remote)   │           │   Check     │
              └───────────┘           └─────────────┘           └─────────────┘
```

## Patron de Implementacion

Todos los providers siguen este patron:

```dart
/// Sincronizar con servidor
/// [showError] - Si es false, errores se ignoran silenciosamente
Future<void> syncData({bool showError = true}) async {
  if (state.isSyncing) return;

  state = state.copyWith(isSyncing: true, errorMessage: null);

  try {
    await _repository.syncWithSupabase(userId);
    state = state.copyWith(isSyncing: false);
  } catch (e) {
    state = state.copyWith(
      isSyncing: false,
      errorMessage: showError ? 'Error de sincronizacion' : null,
    );
  }
}
```

## Archivos Clave

| Archivo | Descripcion |
|---------|-------------|
| `account_provider.dart` | Sync de cuentas |
| `transaction_provider.dart` | Sync de transacciones |
| `budget_provider.dart` | Sync de presupuestos |
| `goal_provider.dart` | Sync de metas |

## Documentacion Detallada

- [SYNC_STRATEGIES.md](SYNC_STRATEGIES.md) - Estrategias de sincronizacion
- [CONFLICT_RESOLUTION.md](CONFLICT_RESOLUTION.md) - Resolucion de conflictos
- [CONNECTIVITY.md](CONNECTIVITY.md) - Manejo de conectividad

## Scripts de Validacion

```bash
# Ejecutar tests de sync
flutter test test/integration/sync_test.dart

# Verificar estado de sync
dart run .claude/skills/sync-management/scripts/check_sync_status.dart
```
