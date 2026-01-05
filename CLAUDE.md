# Finanzas Familiares AS

App de finanzas personales y familiares multiplataforma con soporte offline-first.

**Moneda por defecto**: COP (Peso Colombiano) - con soporte internacional (USD, EUR, MXN, ARS, PEN, CLP, BRL)

## Quick Start

```bash
# Desarrollo
flutter pub get && flutter run

# Build Android
flutter build apk --release

# Tests (suite completa 500+)
flutter test

# Tests rapidos (solo unit/widget)
flutter test test/unit/ test/widget/

# Workflow completo
# Ver /full-workflow para automatizacion
```

## Stack Tecnologico

| Tecnologia | Uso |
|------------|-----|
| Flutter 3.24+ | Framework UI multiplataforma |
| Riverpod 3.0 | State management |
| Drift + SQLite | Base de datos local |
| Supabase | Backend (Auth, DB, Sync) |
| go_router | Navegacion |
| fl_chart | Graficos |

## Estructura

```
lib/
├── core/           # Infraestructura (DB, network, theme)
├── features/       # Modulos por funcionalidad
│   ├── accounts/   # Cuentas bancarias y efectivo
│   ├── transactions/  # Ingresos, gastos, transferencias
│   ├── budgets/    # Presupuestos por categoria
│   ├── goals/      # Metas de ahorro
│   └── ai_chat/    # Asistente financiero (Fina)
└── shared/         # Widgets compartidos
```

## Testing Integral

Suite completa de tests para PWA Flutter + Supabase:

| Categoria | Path | Descripcion |
|-----------|------|-------------|
| Unit | `test/unit/` | Logica de negocio |
| Widget | `test/widget/` | Componentes UI |
| Integration | `test/integration/` | Flujos completos |
| E2E | `test/e2e/` | End-to-end agresivos |
| PWA/Offline | `test/pwa/` | Comportamiento offline-first |
| Supabase | `test/supabase/` | Auth y seguridad RLS |
| Performance | `test/performance/` | Rendimiento y memory |
| Android | `test/android/` | Compatibilidad dispositivos |
| Production | `test/production/` | Robustez extrema |
| Regression | `test/regression/` | Tests generados de errores corregidos |

Ver [Testing Strategy](.claude/skills/testing/TESTING_STRATEGY.md) para detalles.

## Skills Disponibles

| Skill | Descripcion |
|-------|-------------|
| `sync-management` | Offline-first, sync silencioso |
| `financial-analysis` | Calculos financieros, ratios |
| `flutter-architecture` | Patrones Flutter + Riverpod |
| `testing` | Tests PWA, auth, RLS, performance |
| `data-testing` | Generacion de datos de prueba |
| `error-tracker` | **Documentacion de errores y anti-patrones** |

## Error Tracker (Nuevo)

Sistema de documentacion acumulativa de errores con generacion automatica de tests de regresion.

### Workflow al Corregir Errores

```bash
# 1. Buscar errores similares ANTES de implementar
python .error-tracker/scripts/search_errors.py "descripcion del error"

# 2. Documentar error y solucion
python .error-tracker/scripts/add_error.py

# 3. Generar test de regresion
python .error-tracker/scripts/generate_test.py ERR-XXXX
```

### Cuando una Solucion Falla

```bash
# Marcar como fallida (mueve a anti-patterns)
python .error-tracker/scripts/mark_failed.py ERR-XXXX

# Detectar errores recurrentes
python .error-tracker/scripts/detect_recurrence.py "mensaje de error"
```

Ver [Error Tracker Guide](docs/ERROR_TRACKER_GUIDE.md) para documentacion completa.

## Comandos

| Comando | Descripcion |
|---------|-------------|
| `/test-all` | Suite completa de tests |
| `/test-category [cat]` | Tests de categoria especifica |
| `/quick-test` | Tests rapidos (unit + widget) |
| `/full-release` | Workflow completo de release |
| `/build-apk` | Construir APK |
| `/run-tests` | Ejecutar tests |

## Hooks Automaticos

| Hook | Trigger |
|------|---------|
| `pre-commit` | Antes de commit - valida tests y formato |
| `pre-build` | Antes de build - ejecuta tests |
| `post-build` | Despues de build - copia APK |
| `post-test-write` | Al crear test - sugiere setup |

## Principios Clave

1. **Offline-First**: Guardar local primero, sincronizar despues
2. **Sync Silencioso**: Syncs automaticos usan `showError: false`
3. **Test Mode**: Usar `SupabaseClientProvider.enableTestMode()` en tests
4. **RLS**: Filtrar siempre por userId en queries
5. **Error Tracking**: Documentar cada error corregido para evitar regresiones

## Documentacion

### Testing
- [Testing Strategy](.claude/skills/testing/TESTING_STRATEGY.md)
- [PWA/Offline Tests](.claude/skills/testing/PWA_OFFLINE_TESTS.md)
- [Supabase Auth](.claude/skills/testing/SUPABASE_AUTH_TESTS.md)
- [Security RLS](.claude/skills/testing/SECURITY_RLS_TESTS.md)

### Sincronizacion
- [Sync Management](.claude/skills/sync-management/SKILL.md)
- [Sync Testing Guide](docs/SYNC_TESTING_GUIDE.md)

### Error Tracking
- [Error Tracker Skill](.claude/skills/error-tracker/SKILL.md)
- [Error Tracker Guide](docs/ERROR_TRACKER_GUIDE.md)
- [Schema de Errores](.claude/skills/error-tracker/references/schema.md)

### Supabase
- [Supabase MCP Setup](docs/SUPABASE_MCP_SETUP.md) - Acceso permanente de Claude
- [Sync Testing Guide](docs/SYNC_TESTING_GUIDE.md) - Pruebas de sincronizacion

### General
- [CHANGELOG](CHANGELOG.md)
- [Claude Workflow](docs/CLAUDE_WORKFLOW.md)

## Estado del Proyecto

- **Version**: 1.9.3
- **Tests**: 500+ (12 categorias)
- **Coverage**: Unit/Widget/Integration/PWA 100%
- **Moneda**: COP (Peso Colombiano) por defecto
- **Locales**: es_CO, es_MX, en_US, pt_BR soportados
- **Ultima actualizacion**: 2026-01-05

## Workflow Automatizado

Para ejecutar el ciclo completo de desarrollo:

```bash
/full-workflow
```

Esto automatiza: Docs -> Tests -> Build -> Git -> Deploy

Ver [docs/CLAUDE_WORKFLOW.md](docs/CLAUDE_WORKFLOW.md) para diagramas detallados.
