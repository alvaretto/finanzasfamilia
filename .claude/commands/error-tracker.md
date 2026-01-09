# Error Tracker - Documentar y Resolver Errores

Cuando encuentres un error, sigue este protocolo:

## 1. Clasificar el Error

| Tipo | Descripción | Prioridad |
|------|-------------|-----------|
| BUILD | Error de compilación/build_runner | CRÍTICA |
| RUNTIME | Error en tiempo de ejecución | ALTA |
| TEST | Test fallando | ALTA |
| LINT | Warning de análisis estático | MEDIA |
| DEPRECATION | API deprecada | BAJA |

## 2. Documentar en docs/ERRORS.md

```markdown
### [FECHA] ERROR_TYPE: Descripción breve

**Archivo:** `path/to/file.dart:línea`
**Error:**
```
Mensaje de error completo
```

**Causa raíz:** Explicación técnica
**Solución:** Cambios realizados
**Prevención:** Cómo evitarlo en el futuro
```

## 3. Resolver

1. Leer el archivo afectado PRIMERO
2. Identificar causa raíz (no síntomas)
3. Aplicar fix mínimo necesario
4. Ejecutar tests relacionados
5. Documentar solución

## 4. Patrones Comunes en Este Proyecto

### Drift/build_runner
- Ejecutar: `dart run build_runner build --delete-conflicting-outputs`
- Si falla: verificar imports y anotaciones

### Riverpod 3.0
- Usar `Ref` en lugar de `*Ref` (deprecated)
- AsyncNotifier: no usar `update` como nombre de método (conflicto con base)

### Flutter Tests
- Usar `tester.pumpAndSettle()` para animaciones
- Override providers en tests con `overrideWith`
- Import conflicts: usar `hide` para resolver ambigüedades

### Drift imports
- Si hay conflicto con `isNull`/`isNotNull`:
  ```dart
  import 'package:drift/drift.dart' hide isNull, isNotNull;
  ```

## 5. Comandos de Verificación

```bash
# Verificar build
flutter analyze
flutter test

# Regenerar código
dart run build_runner build --delete-conflicting-outputs

# Limpiar cache
flutter clean && flutter pub get
```
