# Claude Code Configuration - Finanzas Familiares

## Progressive Disclosure Architecture

```
.claude/
├── README.md                 # Este archivo - indice principal
├── settings.local.json       # Configuracion local
├── hooks.json               # Definicion de hooks
├── commands/                # Slash commands disponibles
│   ├── build-apk.md        # /build-apk
│   ├── deploy.md           # /deploy
│   ├── full-release.md     # /full-release
│   ├── full-workflow.md    # /full-workflow
│   ├── quick-test.md       # /quick-test
│   ├── run-tests.md        # /run-tests
│   ├── test-all.md         # /test-all
│   ├── test-category.md    # /test-category
│   ├── sync-check.md       # /sync-check
│   └── analyze-finances.md # /analyze-finances
├── hooks/                   # Scripts de hooks
│   └── *.sh                # Scripts ejecutables
└── skills/                  # Conocimiento especializado
    ├── sync-management/     # Offline-first, sincronizacion
    ├── financial-analysis/  # Calculos financieros
    ├── flutter-architecture/# Patrones Flutter + Riverpod
    └── testing/            # Testing PWA, Supabase, RLS
```

## Niveles de Disclosure

### Nivel 1: Quick Reference (CLAUDE.md)
- Stack tecnologico
- Comandos basicos
- Estructura del proyecto

### Nivel 2: Commands (/commands)
- Automatizacion de tareas comunes
- Workflows predefinidos

### Nivel 3: Skills (/skills)
- Conocimiento profundo por dominio
- Patrones y mejores practicas
- Documentacion tecnica detallada

### Nivel 4: Hooks (/hooks)
- Automatizacion de triggers
- Validaciones pre/post acciones

## Flujo de Trabajo Automatizado

```mermaid
graph TD
    A[Usuario solicita tarea] --> B{Tipo de tarea?}
    B -->|Build| C[/build-apk]
    B -->|Test| D[/run-tests]
    B -->|Release| E[/full-release]
    B -->|Workflow completo| F[/full-workflow]

    C --> G[Hook: pre-build]
    G --> H[flutter build apk]
    H --> I[Hook: post-build]
    I --> J[Copia a releases/]

    D --> K[Skill: testing]
    K --> L[Ejecutar suite]
    L --> M[Hook: post-test]

    E --> N[Tests + Build + Deploy]
    F --> O[Docs + Tests + Build + Git + Deploy]
```

## Comandos Disponibles

| Comando | Descripcion | Skill Asociado |
|---------|-------------|----------------|
| `/build-apk` | Construir APK release | - |
| `/deploy` | Deploy a emulador/dispositivo | - |
| `/full-release` | Tests + Build + Deploy | testing |
| `/full-workflow` | Workflow completo | all |
| `/quick-test` | Tests rapidos | testing |
| `/run-tests` | Suite completa | testing |
| `/test-all` | Todos los tests | testing |
| `/test-category` | Tests por categoria | testing |
| `/sync-check` | Verificar sync | sync-management |
| `/analyze-finances` | Analizar logica financiera | financial-analysis |

## Hooks Automaticos

| Hook | Trigger | Accion |
|------|---------|--------|
| `pre-commit` | Antes de git commit | Valida formato y tests criticos |
| `pre-build` | Antes de flutter build | Ejecuta tests unitarios |
| `post-build` | Despues de build exitoso | Copia APK a releases/ |
| `post-test-write` | Al crear archivo de test | Sugiere setup correcto |
| `pre-provider-edit` | Al editar provider | Recuerda sync silencioso |
| `post-model-edit` | Al editar modelo | Recuerda build_runner |

## Skills por Dominio

### sync-management
- Estrategia offline-first
- Sync silencioso vs manual
- Manejo de conflictos
- Queue de operaciones pendientes

### financial-analysis
- Calculos de balance
- Ratios financieros
- Categorias de transacciones
- Validacion de montos

### flutter-architecture
- Patron Repository
- Riverpod providers
- Navegacion con go_router
- Manejo de estado

### testing
- Tests unitarios con Drift in-memory
- Tests de integracion PWA
- Tests de seguridad RLS
- Tests de performance

## Uso

1. **Consulta rapida**: Lee CLAUDE.md
2. **Ejecutar tarea**: Usa comando `/nombre-comando`
3. **Conocimiento profundo**: Consulta skill especifico
4. **Automatizacion**: Los hooks se ejecutan automaticamente
