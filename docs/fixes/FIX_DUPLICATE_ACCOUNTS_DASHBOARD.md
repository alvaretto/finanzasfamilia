# Corrección: Cuentas Duplicadas en Dashboard

## Fecha de Corrección
2026-01-05

## Bug Reportado
"Sigo viendo tres veces 'Préstamos' en 'Tus Cuentas' del Dashboard"

## Síntomas
- La sección "💰 Tus Cuentas" en el Dashboard mostraba la misma cuenta "Préstamos" tres veces
- El balance total podría estar mal calculado debido a los duplicados

## Causa Raíz
1. **Sincronización sin validación**: El proceso de sincronización con Supabase no validaba si ya existía una cuenta con el mismo nombre y tipo antes de insertarla
2. **Inserción remota duplicada**: Al sincronizar desde el servidor, las cuentas se insertaban sin verificar duplicados locales
3. **UI sin deduplicación**: El Dashboard mostraba todas las cuentas sin filtrar duplicados

## Archivos Modificados

### 1. `lib/features/accounts/data/repositories/account_repository.dart`
- Agregado `accountExistsByNameAndType()` - Valida si existe cuenta duplicada
- Agregado `getUniqueAccounts()` - Obtiene cuentas únicas deduplicadas
- Agregado `removeDuplicateAccounts()` - Limpia duplicados existentes
- Agregado `DuplicateAccountException` - Excepción para manejo de errores
- Modificado `createAccount()` - Ahora valida antes de crear
- Modificado `updateAccount()` - Ahora valida antes de actualizar
- Modificado `syncWithSupabase()` - Limpia duplicados y valida antes de insertar

### 2. `lib/features/accounts/presentation/providers/account_provider.dart`
- Agregado `uniqueActiveAccounts` getter - Retorna cuentas sin duplicados
- Agregado `cleanDuplicates()` - Método para limpiar duplicados manualmente
- Agregado `uniqueActiveAccountsProvider` - Provider para acceso global
- Modificado manejo de errores para `DuplicateAccountException`

### 3. `lib/features/dashboard/presentation/screens/dashboard_screen.dart`
- Modificado `_buildBalanceCard()` - Ahora usa `uniqueActiveAccounts`
- Modificado `RefreshIndicator` - Limpia duplicados al refrescar

## Tests Agregados

### `test/features/accounts/account_deduplication_test.dart`
- Test deduplicación por nombre y tipo
- Test mantiene cuentas con mismo nombre pero diferente tipo
- Test ignora variaciones de capitalización
- Test solo considera cuentas activas
- Test ordenamiento alfabético
- Test escenario real: 3 préstamos → 1

## Lógica de Deduplicación

```dart
// Clave única: nombre_normalizado + tipo
final key = '${account.name.trim().toLowerCase()}_${account.type.name}';

// En caso de duplicados, mantener el de mayor balance
accounts.sort((a, b) => b.balance.compareTo(a.balance));
```

## Prevención Futura

1. **Validación en creación**: `createAccount()` lanza excepción si existe duplicado
2. **Validación en actualización**: `updateAccount()` verifica conflictos con otras cuentas
3. **Limpieza en sincronización**: `syncWithSupabase()` limpia duplicados antes de procesar
4. **Limpieza en UI**: Dashboard puede disparar `cleanDuplicates()` al refrescar

## Cómo Verificar la Corrección

1. Abrir la app en el Dashboard
2. Hacer pull-to-refresh para limpiar duplicados
3. Verificar que cada cuenta aparezca solo una vez en "💰 Tus Cuentas"
4. Verificar que el balance total sea correcto

## Rollback (si es necesario)

Si la corrección causa problemas:
1. Revertir a la versión anterior del branch `main`
2. Los datos de cuentas no se ven afectados (soft-delete de duplicados)

## Notas Adicionales

- Los duplicados se marcan como inactivos (soft-delete), no se eliminan permanentemente
- La cuenta con mayor balance se conserva en caso de duplicados
- El usuario puede crear cuentas con el mismo nombre si son de diferente tipo
