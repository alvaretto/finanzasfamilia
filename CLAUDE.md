# Finanzas Familiares AS

App de finanzas personales y familiares multiplataforma con soporte offline-first.

## Quick Start

```bash
# Desarrollo
flutter pub get && flutter run

# Build Android
flutter build apk --release

# Tests
flutter test
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

## Skills Disponibles

Claude Code tiene skills especializados para este proyecto:

| Skill | Descripcion | Cuando usar |
|-------|-------------|-------------|
| `sync-management` | Offline-first, sync silencioso | Implementar sync, manejar offline |
| `financial-analysis` | Calculos financieros | Patrimonio neto, ratios, reportes |
| `flutter-architecture` | Patrones Flutter + Riverpod | Crear providers, widgets |
| `testing` | Tests unitarios, widgets, E2E | Crear o ejecutar tests |

## Comandos Personalizados

```
/build-apk          # Construir APK de release
/run-tests          # Ejecutar suite completa de tests
/sync-check         # Verificar implementacion de sync
/analyze-finances   # Analizar calculos financieros
```

## Convenciones

- **Archivos**: snake_case (`account_provider.dart`)
- **Clases**: PascalCase (`AccountProvider`)
- **Variables**: camelCase (`accountList`)
- **Providers**: camelCase + Provider (`accountsProvider`)

## Principios Clave

1. **Offline-First**: Guardar local primero, sincronizar despues
2. **Sync Silencioso**: Syncs automaticos no muestran errores (`showError: false`)
3. **Division por Cero**: Siempre proteger calculos financieros
4. **Null Safety**: Manejar campos opcionales correctamente

## Documentacion Detallada

Para informacion detallada, consulta los skills en `.claude/skills/`:

- [Sync Management](.claude/skills/sync-management/SKILL.md)
- [Financial Analysis](.claude/skills/financial-analysis/SKILL.md)
- [Flutter Architecture](.claude/skills/flutter-architecture/SKILL.md)
- [Testing](.claude/skills/testing/SKILL.md)

## Estado del Proyecto

- **Version**: 1.2.0
- **Tests**: 172 pasando (unit, widget, integration, production)
- **Changelog**: [CHANGELOG.md](CHANGELOG.md)
