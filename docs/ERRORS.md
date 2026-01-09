# Error Tracker - Historial de Errores Resueltos

Este documento registra errores encontrados y sus soluciones para referencia futura.

---

## 2026-01-08

### BUILD: Conflicto de imports Drift/Matcher

**Archivo:** `test/data/local/daos/recurring_transactions_dao_test.dart:1`
**Error:**
```
'isNotNull' is imported from both 'package:drift/...' and 'package:matcher/...'
```

**Causa raíz:** Drift exporta `isNull`/`isNotNull` que conflictúan con los matchers de flutter_test.
**Solución:** Agregar `hide` al import de Drift:
```dart
import 'package:drift/drift.dart' hide isNull, isNotNull;
```
**Prevención:** Siempre usar `hide` en imports de Drift en archivos de test.

---

### RUNTIME: Método 'update' conflicto con AsyncNotifier

**Archivo:** `lib/application/providers/recurring_transactions_provider.dart`
**Error:**
```
The method 'RecurringTransactionsNotifier.update' has fewer positional arguments than those of overridden method 'AsyncNotifierBase.update'
```

**Causa raíz:** `AsyncNotifier` tiene un método `update()` heredado. Nombrar un método propio `update` causa conflicto.
**Solución:** Renombrar a `updateRecurring()` u otro nombre descriptivo.
**Prevención:** En Notifiers, evitar nombres de métodos que puedan conflictuar con la clase base: `update`, `state`, `ref`, `build`.

---

### BUILD: Provider no definido 'databaseProvider'

**Archivo:** `lib/application/providers/recurring_transactions_provider.dart`
**Error:**
```
Undefined name 'databaseProvider'
```

**Causa raíz:** El provider de base de datos se llama `appDatabaseProvider`, no `databaseProvider`.
**Solución:** Cambiar a `ref.watch(appDatabaseProvider)`.
**Prevención:** Verificar nombres de providers existentes en `database_provider.dart` antes de usarlos.

---

## Plantilla para Nuevos Errores

```markdown
### [TIPO]: Descripción breve

**Archivo:** `path/to/file.dart:línea`
**Error:**
```
Mensaje completo
```

**Causa raíz:**
**Solución:**
**Prevención:**
```
