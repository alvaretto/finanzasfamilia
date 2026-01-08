# Finanzas Familiares v2

App de finanzas personales y familiares con Asistente IA integrado.
**Arquitectura:** Offline-First + AI Online

## Quick Start

```bash
# 1. Configurar entorno (primera vez)
./scripts/setup_manjaro_env.sh

# 2. Instalar dependencias
fvm flutter pub get

# 3. Ejecutar
fvm flutter run

# 4. Tests
fvm flutter test
```

## Stack

| Tecnologia | Uso |
|------------|-----|
| Flutter 3.27+ (FVM) | Framework UI |
| Riverpod | State management |
| PowerSync + Drift | Offline-first sync |
| Supabase | Backend (Auth, DB, Edge Functions) |
| Claude 3.5 Sonnet | AI Assistant (via Edge Functions) |

## Estructura

```
lib/src/
├── core/               # Infraestructura
│   ├── database/       # Drift + PowerSync
│   ├── network/        # Supabase client
│   └── theme/          # Diseño
├── features/
│   ├── ai_assistant/   # Chat con Fina (IA)
│   ├── auth/           # Google Sign-In
│   ├── transactions/   # Ingresos/Gastos
│   ├── accounts/       # Cuentas (Nequi, Efectivo)
│   └── dashboard/      # Resumen
└── shared/             # Widgets comunes
```

## Comandos FVM

| Comando | Descripcion |
|---------|-------------|
| `fvm flutter run` | Ejecutar app |
| `fvm flutter test` | Ejecutar tests |
| `fvm flutter build apk` | Build Android |
| `fvm flutter pub get` | Instalar deps |
| `fvm use <version>` | Cambiar Flutter |

## Slash Commands

| Comando | Descripcion |
|---------|-------------|
| `/setup` | Configurar FVM + Emulador |
| `/run` | Iniciar emulador + app |

## Documentacion

- [AI Architecture](.claude/docs/ai_architecture.md) - Integracion Claude
- [Schema Plan](.claude/docs/schema_plan.md) - PowerSync schema
- [UI/UX Flow](.claude/docs/ui_ux_flow.md) - Flujos de usuario

## Referencias de Diseno

- [Guia Modo Personal](.claude/references/GUIA_MODO_PERSONAL_nuevo.md)
- [Estructura Cuentas](.claude/references/nuevo-mermaid2.md)

## Principios

1. **Offline-First**: PowerSync sincroniza en background
2. **Trust Local First**: Auth persiste localmente
3. **AI Online-Only**: Chat requiere conexion
4. **Privacy-First**: Solo datos agregados al AI

## Moneda

COP (Peso Colombiano) por defecto.
