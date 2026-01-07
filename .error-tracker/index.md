# 📋 Índice de Errores

*Última actualización: 2026-01-07 03:38 UTC*

## Resumen

| Métrica | Valor |
|---------|-------|
| Total errores | 5 |
| Abiertos | 0 |
| Reabiertos | 0 |
| Resueltos | 5 |
| Anti-patrones documentados | 11 |

---

## ✅ Resueltos Recientes

- **[ERR-0004](errors/ERR-0004.json)**: Teclado numérico no aparece en campo de balance al crear cuenta (2026-01-06)
- **[ERR-0005](errors/ERR-0005.json)**: Anti-patrón: amount: i.toDouble() en loops que generan transacciones (2026-01-06)
- **[ERR-0001](errors/ERR-0001.json)**: API Key no carga al iniciar la app después de actualización (2026-01-05)
- **[ERR-0003](errors/ERR-0003.json)**: Cuentas fantasma 'Préstamos' aparecen en Dashboard con balance $0 (2026-01-05)
- **[ERR-0002](errors/ERR-0002.json)**: MCP servers no conectan - configuracion incorrecta en ~/.claude.json (2026-01-05)

---

## 🏷️ Por Tags

- `accounts`: 1 errores (0 abiertos)
- `ai_chat`: 1 errores (0 abiertos)
- `android`: 1 errores (0 abiertos)
- `anti-pattern`: 1 errores (0 abiertos)
- `async`: 1 errores (0 abiertos)
- `claude-code`: 1 errores (0 abiertos)
- `configuration`: 1 errores (0 abiertos)
- `dashboard`: 1 errores (0 abiertos)
- `data-cleanup`: 1 errores (0 abiertos)
- `data-generation`: 1 errores (0 abiertos)
- `deduplication`: 1 errores (0 abiertos)
- `flutter`: 3 errores (0 abiertos)
- `flutter_secure_storage`: 1 errores (0 abiertos)
- `focusnode`: 1 errores (0 abiertos)
- `initialization`: 1 errores (0 abiertos)
- `keyboard`: 1 errores (0 abiertos)
- `mcp`: 1 errores (0 abiertos)
- `modal-bottom-sheet`: 1 errores (0 abiertos)
- `performance`: 1 errores (0 abiertos)
- `recurrent`: 1 errores (0 abiertos)
- `riverpod`: 1 errores (0 abiertos)
- `setup`: 1 errores (0 abiertos)
- `testing`: 1 errores (0 abiertos)
- `textfield`: 1 errores (0 abiertos)
- `ux`: 1 errores (0 abiertos)
- `validation`: 1 errores (0 abiertos)
- `visual-bug`: 1 errores (0 abiertos)

---

## 🔧 Comandos Rápidos

```bash
# Buscar errores similares
python .error-tracker/scripts/search_errors.py "mensaje"

# Detectar si error ya existe
python .error-tracker/scripts/detect_recurrence.py "mensaje"

# Agregar nuevo error
python .error-tracker/scripts/add_error.py

# Marcar solución como fallida
python .error-tracker/scripts/mark_failed.py ERR-XXXX

# Generar test de regresión
python .error-tracker/scripts/generate_test.py ERR-XXXX
```