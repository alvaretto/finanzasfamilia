# Finanzas Familiares AS

App de finanzas personales y familiares multiplataforma con soporte offline-first.

**Moneda por defecto**: COP (Peso Colombiano) - con soporte internacional (USD, EUR, MXN, ARS, PEN, CLP, BRL)

## Quick Start

```bash
# Desarrollo
flutter pub get && flutter run

# Build Android
flutter build apk --release

# Tests (suite completa 350+)
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

Ver [Testing Strategy](.claude/skills/testing/TESTING_STRATEGY.md) para detalles.

## Skills Disponibles

| Skill | Descripcion |
|-------|-------------|
| `sync-management` | Offline-first, sync silencioso |
| `financial-analysis` | Calculos financieros, ratios |
| `flutter-architecture` | Patrones Flutter + Riverpod |
| `testing` | Tests PWA, auth, RLS, performance |

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

## Documentacion

- [Testing Strategy](.claude/skills/testing/TESTING_STRATEGY.md)
- [PWA/Offline Tests](.claude/skills/testing/PWA_OFFLINE_TESTS.md)
- [Supabase Auth](.claude/skills/testing/SUPABASE_AUTH_TESTS.md)
- [Security RLS](.claude/skills/testing/SECURITY_RLS_TESTS.md)
- [Sync Management](.claude/skills/sync-management/SKILL.md)
- [CHANGELOG](CHANGELOG.md)

## Estado del Proyecto

- **Version**: 1.9.0
- **Tests**: 350+ (10 categorias)
- **Coverage**: Unit/Widget/Integration 100%
- **Moneda**: COP (Peso Colombiano) por defecto
- **Locales**: es_CO, es_MX, en_US, pt_BR soportados
