---
name: error-tracker
description: |
  Sistema de documentación y aprendizaje de errores para proyectos Flutter/Supabase.
  Usar cuando: (1) Se corrige un bug o error, (2) Una solución previa falla y necesita reintento,
  (3) Se necesita consultar errores pasados antes de resolver uno nuevo, (4) Se requiere generar
  tests de regresión para errores corregidos. Dispara automáticamente al mencionar "error",
  "bug", "fix", "solución", "corregir", "falla", "no funciona", "reaparece".
---

# Error Tracker

Sistema de documentación acumulativa de errores y soluciones con generación automática de tests.

## Estructura en el Proyecto

```
.error-tracker/
├── errors/              # JSONs individuales por error
│   └── ERR-XXXX.json
├── index.md             # Índice Markdown auto-generado
├── patterns.json        # Patrones para detección automática
└── anti-patterns.json   # Soluciones que NO funcionan
```

## Workflow Principal

### Al Corregir un Error

1. **Antes de implementar la solución**: Buscar errores similares
   ```bash
   python .error-tracker/scripts/search_errors.py "descripción del error"
   ```

2. **Documentar el error y solución**:
   ```bash
   python .error-tracker/scripts/add_error.py
   ```

3. **Generar test de regresión**:
   ```bash
   python .error-tracker/scripts/generate_test.py ERR-XXXX
   ```

### Cuando una Solución Falla

1. **Marcar solución como fallida**:
   ```bash
   python .error-tracker/scripts/mark_failed.py ERR-XXXX
   ```
   Esto mueve la solución a `anti-patterns.json` y reabre el error.

2. **Aplicar nueva solución** y documentar con `add_error.py --update ERR-XXXX`

## Detección Automática de Errores Recurrentes

El script `detect_recurrence.py` compara mensajes de error contra `patterns.json`:

```bash
python .error-tracker/scripts/detect_recurrence.py "mensaje de error"
```

Retorna errores similares previamente documentados con sus soluciones y anti-patrones.

## Integración con Tests

Los tests generados se ubican en:
- **Unit tests**: `test/regression/unit/`
- **Integration tests**: `test/regression/integration/`
- **Widget tests**: `test/regression/widget/`

El generador analiza el error y determina el tipo de test apropiado.

## Campos del Error (JSON)

Ver [references/schema.md](references/schema.md) para el esquema completo.

Campos clave:
- `id`: Identificador único (ERR-XXXX)
- `title`: Título descriptivo breve
- `description`: Descripción detallada
- `error_message`: Mensaje de error exacto
- `stack_trace`: Stack trace si aplica
- `affected_files`: Lista de archivos afectados
- `solution`: Objeto con código antes/después
- `anti_patterns`: Lista de soluciones que NO funcionan
- `status`: open | resolved | reopened
- `related_tests`: Tests de regresión asociados
- `tags`: Etiquetas para búsqueda (flutter, supabase, rls, sync, etc.)

## Scripts Disponibles

| Script | Descripción |
|--------|-------------|
| `add_error.py` | Documentar nuevo error o actualizar existente |
| `search_errors.py` | Buscar errores por texto, tags, o archivo |
| `mark_failed.py` | Marcar solución como fallida |
| `generate_test.py` | Generar test de regresión |
| `detect_recurrence.py` | Detectar si error ya fue documentado |
| `rebuild_index.py` | Regenerar index.md |

## Ejemplo de Uso

```python
# Antes de corregir un error, buscar similares:
# > python .error-tracker/scripts/search_errors.py "RLS policy infinite recursion"

# Encontró ERR-0023: "RLS Recursion en family_members"
# Ver anti-patterns: Usar SECURITY DEFINER sin materializar vista
# Solución correcta: Crear función helper con SECURITY DEFINER

# Después de corregir:
# > python .error-tracker/scripts/add_error.py
# > python .error-tracker/scripts/generate_test.py ERR-0024
```
