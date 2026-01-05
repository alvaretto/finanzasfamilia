# Esquema de Errores

## Estructura JSON Completa

```json
{
  "id": "ERR-0001",
  "title": "Título breve del error",
  "description": "Descripción detallada del problema y contexto",
  "severity": "critical | high | medium | low",
  "status": "open | resolved | reopened | investigating",
  
  "error_details": {
    "message": "Mensaje de error exacto",
    "stack_trace": "Stack trace completo si aplica",
    "error_type": "runtime | compile | logic | ui | network | database",
    "reproducibility": "always | sometimes | rare"
  },
  
  "context": {
    "affected_files": [
      {
        "path": "lib/features/accounts/providers/account_provider.dart",
        "lines": [45, 67],
        "function": "fetchAccounts"
      }
    ],
    "environment": {
      "flutter_version": "3.24.0",
      "platform": "web | android | ios | linux",
      "mode": "debug | release | profile"
    },
    "user_action": "Qué estaba haciendo el usuario cuando ocurrió",
    "prerequisites": "Condiciones necesarias para reproducir"
  },
  
  "solution": {
    "summary": "Resumen de la solución aplicada",
    "changes": [
      {
        "file": "lib/features/accounts/providers/account_provider.dart",
        "before": "código anterior",
        "after": "código corregido",
        "explanation": "Por qué este cambio resuelve el problema"
      }
    ],
    "root_cause": "Causa raíz identificada",
    "applied_at": "2026-01-05T10:30:00Z",
    "verified": true
  },
  
  "anti_patterns": [
    {
      "attempted_solution": "Descripción de lo que se intentó",
      "code_change": "código que se probó",
      "why_failed": "Por qué no funcionó",
      "side_effects": "Efectos secundarios observados",
      "attempted_at": "2026-01-04T15:00:00Z"
    }
  ],
  
  "related_tests": [
    {
      "path": "test/regression/unit/err_0001_account_fetch_test.dart",
      "type": "unit | integration | widget | e2e",
      "generated_at": "2026-01-05T11:00:00Z"
    }
  ],
  
  "metadata": {
    "created_at": "2026-01-04T14:00:00Z",
    "updated_at": "2026-01-05T11:00:00Z",
    "resolved_at": "2026-01-05T10:30:00Z",
    "reopened_count": 0,
    "tags": ["supabase", "rls", "sync", "accounts"],
    "related_errors": ["ERR-0005", "ERR-0012"],
    "references": [
      "https://supabase.com/docs/guides/auth/row-level-security"
    ]
  },
  
  "detection_patterns": {
    "error_regex": "regex para detectar este error",
    "keywords": ["palabras", "clave", "para", "matching"],
    "file_patterns": ["**/providers/*_provider.dart"]
  }
}
```

## Campos Requeridos

| Campo | Requerido | Descripción |
|-------|-----------|-------------|
| `id` | ✅ | Auto-generado (ERR-XXXX) |
| `title` | ✅ | Máx 100 caracteres |
| `description` | ✅ | Sin límite |
| `severity` | ✅ | Nivel de severidad |
| `status` | ✅ | Estado actual |
| `error_details.message` | ✅ | Mensaje exacto |
| `context.affected_files` | ✅ | Al menos 1 archivo |
| `solution` | ⚠️ | Requerido al resolver |
| `metadata.tags` | ✅ | Al menos 1 tag |

## Tags Predefinidos

### Por Tecnología
- `flutter`, `dart`, `riverpod`, `drift`, `supabase`

### Por Área
- `auth`, `sync`, `rls`, `database`, `ui`, `navigation`, `network`

### Por Tipo
- `performance`, `memory`, `crash`, `logic`, `ui-glitch`

### Por Feature
- `accounts`, `transactions`, `budgets`, `goals`, `ai-chat`, `reports`

## Estados del Error

```
open ──────► resolved
  ▲            │
  │            ▼
  └──────── reopened ──► investigating ──► resolved
```

- **open**: Error recién documentado
- **investigating**: Buscando solución
- **resolved**: Solución aplicada y verificada
- **reopened**: Solución falló, vuelve a estar activo
