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
    ├── testing/            # Testing PWA, Supabase, RLS
    ├── data-testing/       # Generacion de datos de prueba
    └── error-tracker/      # Documentacion de errores y anti-patrones
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
    B -->|Corregir error| G[error-tracker skill]

    C --> H[Hook: pre-build]
    H --> I[flutter build apk]
    I --> J[Hook: post-build]
    J --> K[Copia a releases/]

    D --> L[Skill: testing]
    L --> M[Ejecutar suite]
    M --> N[Hook: post-test]

    E --> O[Tests + Build + Deploy]
    F --> P[Docs + Tests + Build + Git + Deploy]
    
    G --> Q[Buscar errores similares]
    Q --> R[Documentar solucion]
    R --> S[Generar test regresion]
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

### data-testing
- Generacion de datos de prueba
- Patrones de datos colombianos
- Import/export de datos
- Escenarios de testing

### error-tracker (NUEVO)
- Documentacion acumulativa de errores
- Registro de anti-patrones (soluciones que NO funcionan)
- Deteccion automatica de errores recurrentes
- Generacion de tests de regresion
- Historial de soluciones por error

#### Workflow de Error Tracking

```bash
# 1. Antes de corregir, buscar errores similares
python .error-tracker/scripts/search_errors.py "mensaje"

# 2. Documentar error y solucion
python .error-tracker/scripts/add_error.py

# 3. Generar test de regresion
python .error-tracker/scripts/generate_test.py ERR-XXXX

# 4. Si la solucion falla
python .error-tracker/scripts/mark_failed.py ERR-XXXX
```

Ver [ERROR_TRACKER_GUIDE.md](../docs/ERROR_TRACKER_GUIDE.md) para documentacion completa.

## Uso

1. **Consulta rapida**: Lee CLAUDE.md
2. **Ejecutar tarea**: Usa comando `/nombre-comando`
3. **Conocimiento profundo**: Consulta skill especifico
4. **Automatizacion**: Los hooks se ejecutan automaticamente
5. **Corregir errores**: Usa skill `error-tracker` para documentar
