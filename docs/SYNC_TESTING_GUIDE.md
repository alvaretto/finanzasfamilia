# Guía de Prueba de Sincronización

Esta guía te ayuda a verificar que los datos se sincronizan correctamente desde la app hacia Supabase.

## Estado Actual (2026-01-04)

### Usuarios Registrados
- **Alvaro Angel Molina** (alvaroangelm@gmail.com) - Último login: 15:04
- **Maria Conde** (condenada.marucha@gmail.com) - Último login: 15:45

### Datos en Supabase
- ✅ Profiles: 2 usuarios
- ✅ Categories: 14 categorías del sistema
- ❌ Accounts: 0 (sin cuentas)
- ❌ Transactions: 0 (sin transacciones)
- ❌ Budgets: 0
- ❌ Goals: 0

## Flujo de Sincronización

### Arquitectura Offline-First

```
[APP Flutter]
     ↓
[SQLite Local (Drift)]  ← Siempre se guarda aquí PRIMERO (isSynced = false)
     ↓
[Connectivity Check]    ← Verifica si hay internet
     ↓
[syncWithSupabase()]   ← Sube datos no sincronizados
     ↓
[Supabase Cloud]       ← Base de datos remota
```

### Proceso de Sync

1. **Crear Dato Local**:
   ```dart
   // import_test_data_screen.dart:208
   await ref.read(transactionsProvider.notifier).createTransaction(
     accountId: accountId,
     amount: tx.amount,
     type: tx.type,
     description: tx.description,
     date: tx.date,
   );
   ```

2. **Guardar en SQLite**:
   ```dart
   // transaction_repository.dart:114
   await _db.into(_db.transactions).insert(companion);
   // isSynced = false (línea 128)
   ```

3. **Intentar Sync en Background**:
   ```dart
   // transaction_provider.dart:202
   _trySyncInBackground();  // Verifica conectividad y sincroniza
   ```

4. **Subir a Supabase**:
   ```dart
   // transaction_repository.dart:442
   final unsynced = await getUnsyncedTransactions();
   for (final tx in unsynced) {
     await _upsertToSupabase(tx);  // línea 471
     await markAsSynced(tx.id);
   }
   ```

## Pasos para Probar la Sincronización

### 1. Verificar Conectividad

Desde la app:
1. Abrir **Configuración**
2. Revisar el indicador de **Sincronización**
3. Debería mostrar: ✅ "Última: hace X minutos"

### 2. Generar Datos de Prueba

1. Abrir **Configuración** → **Datos de Prueba**
2. Configurar:
   - Cantidad de transacciones: **50**
   - Días hacia atrás: **30**
   - ✅ Crear cuenta de prueba
3. Presionar **Generar Datos**
4. Esperar mensaje: "Se generaron 50 transacciones"

### 3. Forzar Sincronización Manual

1. Ir a **Configuración**
2. Presionar el botón **Sincronización** 🔄
3. Esperar mensaje: "Sincronización completada" (verde)

### 4. Verificar en Supabase (con Claude)

Pedirle a Claude que ejecute:

```sql
-- Verificar cuentas
SELECT id, user_id, name, balance, currency
FROM public.accounts
ORDER BY created_at DESC;

-- Verificar transacciones
SELECT COUNT(*) as total, type
FROM public.transactions
GROUP BY type;

-- Verificar última transacción
SELECT id, description, amount, type, date
FROM public.transactions
ORDER BY created_at DESC
LIMIT 5;
```

## Checklist de Diagnóstico

Si los datos NO se sincronizan, verificar:

### ✅ Conectividad
- [ ] El dispositivo tiene internet
- [ ] No está en modo avión
- [ ] WiFi o datos móviles activos

### ✅ Autenticación
- [ ] El usuario está logueado (ver email en Configuración)
- [ ] La sesión no expiró
- [ ] El token de autenticación es válido

### ✅ Supabase Client
- [ ] `SupabaseClientProvider.isInitialized == true`
- [ ] `_isOnline == true` en los repositorios
- [ ] No hay errores en los logs de Supabase

### ✅ Datos Locales
- [ ] Los datos se guardaron en SQLite local
- [ ] El flag `isSynced == false` está presente
- [ ] No hay errores en la creación de transacciones

## Comandos de Verificación (Claude)

Claude Code puede ejecutar estos comandos para ayudar:

### Ver logs de Postgres
```
mcp__supabase__get_logs(
  project_id: "arawzleeiohoyhonisvo",
  service: "postgres"
)
```

### Ver logs de API
```
mcp__supabase__get_logs(
  project_id: "arawzleeiohoyhonisvo",
  service: "api"
)
```

### Ver logs de Auth
```
mcp__supabase__get_logs(
  project_id: "arawzleeiohoyhonisvo",
  service: "auth"
)
```

### Contar registros por tabla
```sql
SELECT
  'accounts' as tabla, COUNT(*) as total FROM public.accounts
UNION ALL
SELECT
  'transactions' as tabla, COUNT(*) as total FROM public.transactions
UNION ALL
SELECT
  'budgets' as tabla, COUNT(*) as total FROM public.budgets
UNION ALL
SELECT
  'goals' as tabla, COUNT(*) as total FROM public.goals;
```

## Problemas Conocidos

### Problema: Datos se guardan local pero no se sincronizan

**Síntomas**:
- Ver datos en la app
- No ver datos en Supabase
- Indicador de sync muestra "Sincronización completada" (sin errores)

**Posibles causas**:
1. `SupabaseClientProvider.isInitialized == false`
2. Token de autenticación expirado
3. Error silencioso en `_upsertToSupabase()` (línea 471)
4. RLS bloqueando el insert

**Solución**:
1. Revisar logs de API en Supabase
2. Verificar que el userId coincide con el usuario autenticado
3. Verificar políticas RLS en Supabase Dashboard

### Problema: Sync muestra error de red

**Síntomas**:
- Mensaje: "Error de sincronización (modo offline activo)"
- No hay internet o servidor caído

**Solución**:
1. Verificar conectividad
2. Los datos se guardan local y se sincronizarán automáticamente cuando haya conexión
3. Forzar sync manual cuando regrese la conexión

## Modo Silencioso vs Manual

### Sync Silencioso (Automático)
- Se ejecuta después de crear/actualizar/eliminar datos
- Se ejecuta cuando cambia la conectividad (offline → online)
- Los errores NO se muestran al usuario
- `showError: false`

### Sync Manual (Usuario)
- Se ejecuta al presionar el botón de sincronización en Configuración
- Los errores SÍ se muestran al usuario
- `showError: true`

## Referencias de Código

| Archivo | Línea | Descripción |
|---------|-------|-------------|
| `import_test_data_screen.dart` | 208 | Creación de transacciones de prueba |
| `transaction_provider.dart` | 173 | Método `createTransaction()` |
| `transaction_provider.dart` | 284 | Método `syncTransactions()` |
| `transaction_provider.dart` | 302 | Método `_trySyncInBackground()` |
| `transaction_repository.dart` | 114 | Método `createTransaction()` |
| `transaction_repository.dart` | 442 | Método `syncWithSupabase()` |
| `transaction_repository.dart` | 470 | Método `_upsertToSupabase()` |

## Próximos Pasos

Una vez que los datos se sincronicen correctamente:

1. ✅ Verificar que las transacciones aparecen en Supabase
2. ✅ Verificar que las cuentas tienen el balance correcto
3. ✅ Probar sincronización bidireccional (crear desde otro dispositivo)
4. ✅ Probar resolución de conflictos
5. ✅ Probar modo offline → online

## Soporte

Si necesitas ayuda con la sincronización:

1. Pídele a Claude que revise los logs de Supabase
2. Pídele a Claude que ejecute queries SQL para verificar los datos
3. Consulta la documentación en `docs/SUPABASE_MCP_SETUP.md`

---

**Última actualización**: 2026-01-04
**Estado**: En pruebas
