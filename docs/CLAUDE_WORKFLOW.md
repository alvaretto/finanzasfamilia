# Flujo de Trabajo .claude - Finanzas Familiares

Diagrama del sistema de automatizacion y Progressive Disclosure implementado en `.claude/`.

## Diagrama Principal

```mermaid
flowchart TB
    subgraph User["Usuario"]
        U[Desarrollador/Claude]
    end

    subgraph ClaudeConfig[".claude Configuration"]
        CM[CLAUDE.md<br/>Progressive Disclosure]

        subgraph Skills["Skills Layer"]
            S1[sync-management]
            S2[financial-analysis]
            S3[flutter-architecture]
            S4[testing]
            S5[data-testing]
            S6[error-tracker]
        end

        subgraph Commands["Commands Layer"]
            C1[/build-apk]
            C2[/run-tests]
            C3[/sync-check]
            C4[/analyze-finances]
            C5[/pre-release]
            C6[/deploy]
        end

        subgraph Hooks["Hooks Layer"]
            H1[post-flutter-build]
            H2[post-test-run]
            H3[pre-provider-edit]
            H4[post-model-edit]
            H5[pre-commit]
            H6[pre-build]
        end
    end

    subgraph ErrorTracking[".error-tracker System"]
        ET1[errors/*.json]
        ET2[patterns.json]
        ET3[anti-patterns.json]
        ET4[index.md]
    end

    subgraph App["Finanzas Familiares App"]
        subgraph Core["Core Layer"]
            DB[(Drift/SQLite)]
            SB[Supabase Client]
            RT[Router]
            TH[Theme]
        end

        subgraph Features["Features Layer"]
            F1[Auth]
            F2[Accounts]
            F3[Transactions]
            F4[Budgets]
            F5[Goals]
            F6[Reports]
            F7[AI Chat]
            F8[Family]
        end

        subgraph Providers["State Management"]
            P1[Account Provider]
            P2[Transaction Provider]
            P3[Budget Provider]
            P4[Goal Provider]
        end
    end

    subgraph Testing["Testing Suite"]
        T1[Unit Tests]
        T2[Widget Tests]
        T3[Integration Tests]
        T4[AI Chat Tests]
        T5[Security Tests]
        T6[Performance Tests]
        T7[PWA Tests]
        T8[Android Tests]
        T9[Production Tests]
        T10[Regression Tests]
    end

    subgraph Output["Build Output"]
        APK[Android APK]
        LIN[Linux Binary]
    end

    %% User interactions
    U --> CM
    U --> Commands

    %% CLAUDE.md references skills
    CM --> Skills

    %% Error tracker integration
    S6 --> ErrorTracking
    ErrorTracking --> T10

    %% Commands trigger actions
    C1 --> APK
    C2 --> Testing
    C5 --> Testing
    C5 --> APK
    C6 --> APK

    %% Hooks automate workflows
    H1 --> APK
    H3 --> Providers
    H4 --> DB
    H5 --> Testing
    H6 --> Testing

    %% Skills provide knowledge
    S1 --> Providers
    S2 --> Features
    S3 --> Core
    S4 --> Testing
    S5 --> Testing

    %% App architecture
    Core --> Features
    Features --> Providers
    Providers --> DB
    Providers --> SB

    %% Sync flow
    DB <-->|Offline-First| SB
```

## Flujo de Error Tracking

```mermaid
flowchart TB
    subgraph Trigger["Disparador"]
        ERR[Error Detectado]
        FIX[Bug Corregido]
        FAIL[Solucion Fallo]
    end

    subgraph Search["Busqueda Previa"]
        S1[search_errors.py]
        S2[detect_recurrence.py]
    end

    subgraph Document["Documentacion"]
        D1[add_error.py]
        D2[Crear ERR-XXXX.json]
        D3[Actualizar patterns.json]
        D4[Regenerar index.md]
    end

    subgraph TestGen["Generacion Tests"]
        T1[generate_test.py]
        T2[test/regression/unit/]
        T3[test/regression/widget/]
        T4[test/regression/integration/]
    end

    subgraph FailedSolution["Solucion Fallida"]
        F1[mark_failed.py]
        F2[Mover a anti_patterns]
        F3[Actualizar anti-patterns.json]
        F4[Estado: reopened]
    end

    %% Flujo principal
    ERR --> S1
    ERR --> S2
    S1 --> |Similar encontrado| D1
    S2 --> |Recurrente| D1
    S1 --> |Nuevo| D1

    FIX --> D1
    D1 --> D2
    D2 --> D3
    D3 --> D4

    D2 --> T1
    T1 --> T2
    T1 --> T3
    T1 --> T4

    FAIL --> F1
    F1 --> F2
    F2 --> F3
    F3 --> F4
    F4 --> |Nueva solucion| D1
```

## Ciclo de Vida del Error

```mermaid
stateDiagram-v2
    [*] --> Open: Error detectado
    
    Open --> Investigating: Buscando solucion
    Investigating --> Resolved: Solucion aplicada
    
    Resolved --> Reopened: Solucion fallo
    Reopened --> Investigating: Nueva investigacion
    
    Resolved --> [*]: Test de regresion pasa
    
    note right of Reopened
        Solucion anterior
        movida a anti-patterns
    end note
    
    note right of Resolved
        Test de regresion
        generado automaticamente
    end note
```

## Workflow de Correccion de Errores

```mermaid
sequenceDiagram
    participant D as Desarrollador
    participant S as search_errors.py
    participant A as add_error.py
    participant G as generate_test.py
    participant T as flutter test
    participant M as mark_failed.py

    D->>S: Buscar "RLS recursion"
    S-->>D: ERR-0023 similar (85%)
    
    Note over D: Revisa anti-patrones
    
    D->>D: Implementa solucion
    D->>A: Documentar error
    A-->>D: ERR-0024.json creado
    
    D->>G: Generar test ERR-0024
    G-->>D: err_0024_regression_test.dart
    
    D->>T: flutter test regression/
    
    alt Test pasa
        T-->>D: OK - Commit
    else Test falla
        T-->>D: Error persiste
        D->>M: mark_failed ERR-0024
        M-->>D: Movido a anti-patterns
        Note over D: Volver a intentar
    end
```

## Estructura del Error Tracker

```mermaid
flowchart LR
    subgraph ErrorTracker[".error-tracker/"]
        subgraph Errors["errors/"]
            E1[ERR-0001.json]
            E2[ERR-0002.json]
            E3[ERR-XXXX.json]
        end
        
        subgraph Scripts["scripts/"]
            SC1[add_error.py]
            SC2[search_errors.py]
            SC3[detect_recurrence.py]
            SC4[mark_failed.py]
            SC5[generate_test.py]
            SC6[rebuild_index.py]
        end
        
        P[patterns.json]
        AP[anti-patterns.json]
        I[index.md]
    end
    
    subgraph Tests["test/regression/"]
        TU[unit/]
        TW[widget/]
        TI[integration/]
    end
    
    SC5 --> Tests
    Errors --> SC2
    Errors --> SC3
    SC1 --> Errors
    SC4 --> AP
```

## Flujo de Sincronizacion Offline-First

```mermaid
sequenceDiagram
    participant U as Usuario
    participant P as Provider
    participant R as Repository
    participant L as SQLite Local
    participant S as Supabase Remote

    U->>P: Crear transaccion
    P->>R: createTransaction(data)
    R->>L: INSERT (isSynced=false)
    L-->>R: Success
    R-->>P: TransactionModel
    P-->>U: UI actualizada

    Note over R,S: Sync en background (timer 5min)

    alt Online
        R->>S: upsert(unsynced items)
        S-->>R: Success
        R->>L: UPDATE isSynced=true
        R->>S: SELECT remote changes
        S-->>R: Remote data
        R->>L: Merge (Last Write Wins)
    else Offline
        Note over R,S: Sync se pospone
    end
```

## Flujo de Commands

```mermaid
flowchart LR
    subgraph Commands
        C1[/build-apk]
        C2[/run-tests]
        C3[/sync-check]
        C4[/pre-release]
        C5[/deploy]
    end

    subgraph Actions
        A1[flutter build apk --release]
        A2[flutter test]
        A3[Verificar providers sync]
        A4[Tests + Build + Validate]
        A5[Build + Copy to releases/]
    end

    subgraph Outputs
        O1[APK en build/]
        O2[Test results]
        O3[Sync report]
        O4[Release candidate]
        O5[APK en releases/]
    end

    C1 --> A1 --> O1
    C2 --> A2 --> O2
    C3 --> A3 --> O3
    C4 --> A4 --> O4
    C5 --> A5 --> O5
```

## Flujo de Hooks

```mermaid
flowchart TB
    subgraph Triggers["Trigger Events"]
        T1[flutter build completa]
        T2[flutter test completa]
        T3[Editar *_provider.dart]
        T4[Editar *_model.dart]
        T5[git commit]
        T6[flutter build inicia]
    end

    subgraph Hooks["Hook Actions"]
        H1[post-flutter-build<br/>Notifica exito]
        H2[post-test-run<br/>Sugiere coverage]
        H3[pre-provider-edit<br/>Recordar sync silencioso]
        H4[post-model-edit<br/>Recordar build_runner]
        H5[pre-commit<br/>Ejecutar tests]
        H6[pre-build<br/>Ejecutar tests]
    end

    subgraph Results["Resultados"]
        R1[Mensaje de confirmacion]
        R2[flutter test --coverage]
        R3[Patron showError=false]
        R4[dart run build_runner build]
        R5[Tests pasan -> commit OK]
        R6[Tests pasan -> build OK]
    end

    T1 --> H1 --> R1
    T2 --> H2 --> R2
    T3 --> H3 --> R3
    T4 --> H4 --> R4
    T5 --> H5 --> R5
    T6 --> H6 --> R6
```

## Progressive Disclosure Structure

```mermaid
flowchart TB
    subgraph Level1["Nivel 1: Quick Start"]
        L1[CLAUDE.md<br/>Comandos basicos<br/>flutter run, build]
    end

    subgraph Level2["Nivel 2: Arquitectura"]
        L2[Stack tecnologico<br/>Estructura de carpetas]
    end

    subgraph Level3["Nivel 3: Skills"]
        S1[sync-management/]
        S2[financial-analysis/]
        S3[flutter-architecture/]
        S4[testing/]
        S5[data-testing/]
        S6[error-tracker/]
    end

    subgraph Level4["Nivel 4: Detalles"]
        D1[SYNC_STRATEGY.md]
        D2[OFFLINE_FIRST.md]
        D3[CONFLICT_RESOLUTION.md]
        D4[TESTING_STRATEGY.md]
        D5[ERROR_TRACKER_GUIDE.md]
    end

    L1 --> L2
    L2 --> L3
    L3 --> Level4
    S1 --> D1
    S1 --> D2
    S1 --> D3
    S4 --> D4
    S6 --> D5
```

## Arquitectura de Testing

```mermaid
flowchart TB
    subgraph TestSuite["Suite de Tests (500+)"]
        subgraph Unit["Unit Tests"]
            U1[Models]
            U2[Repositories]
            U3[Utils]
        end

        subgraph Widget["Widget Tests"]
            W1[Screens]
            W2[Components]
            W3[Forms]
        end

        subgraph Integration["Integration Tests"]
            I1[User Flows]
            I2[E2E Scenarios]
        end

        subgraph Specialized["Specialized Tests"]
            SP1[AI Chat]
            SP2[Security]
            SP3[Performance]
            SP4[PWA/Offline]
            SP5[Android Compat]
            SP6[Production]
        end

        subgraph Regression["Regression Tests"]
            RG1[Auto-generated]
            RG2[From error-tracker]
        end
    end

    subgraph Commands["Test Commands"]
        C1[/run-tests]
        C2[/quick-test]
        C3[/test-category]
        C4[/pre-release]
    end

    subgraph ErrorTracker["Error Tracker"]
        ET[generate_test.py]
    end

    C1 --> TestSuite
    C2 --> Unit
    C2 --> Widget
    C3 --> Specialized
    C4 --> TestSuite
    ET --> Regression
```

## Flujo de Estado con Riverpod

```mermaid
flowchart TB
    subgraph UI["UI Layer"]
        S1[AccountsScreen]
        S2[TransactionsScreen]
        S3[DashboardScreen]
    end

    subgraph Providers["Riverpod Providers"]
        P1[accountsProvider<br/>StateNotifier]
        P2[transactionsProvider<br/>StateNotifier]
        P3[dashboardProvider<br/>Computed]
    end

    subgraph State["State Classes"]
        ST1[AccountsState]
        ST2[TransactionsState]
        ST3[DashboardState]
    end

    subgraph Repos["Repositories"]
        R1[AccountRepository]
        R2[TransactionRepository]
    end

    subgraph Data["Data Sources"]
        D1[(SQLite)]
        D2[Supabase]
    end

    S1 -->|ref.watch| P1
    S2 -->|ref.watch| P2
    S3 -->|ref.watch| P3

    P1 --> ST1
    P2 --> ST2
    P3 --> ST3

    P1 -->|CRUD| R1
    P2 -->|CRUD| R2

    R1 --> D1
    R1 -.->|sync| D2
    R2 --> D1
    R2 -.->|sync| D2

    P3 -->|depends| P1
    P3 -->|depends| P2
```

---

## Flujo /full-workflow Completo

```mermaid
flowchart TD
    START(["/full-workflow"]) --> DOCS["1. Actualizar Docs"]
    DOCS --> |README, Manual, Walkthrough| DEPS["2. flutter pub get"]
    DEPS --> RUNNER["3. dart run build_runner build -d"]
    RUNNER --> ANALYZE["4. flutter analyze"]
    ANALYZE --> TEST_CRIT["5. Tests Criticos"]

    TEST_CRIT --> CRIT_OK{Pasaron?}
    CRIT_OK --> |Si| TEST_ALL["6. Tests Completos"]
    CRIT_OK --> |No| FIX["Corregir + Error Track"]
    FIX --> TEST_CRIT

    TEST_ALL --> REG["6.5 Tests Regresion"]
    REG --> BUILD["7. flutter build apk --release"]
    BUILD --> COPY["8. cp APK ~/Descargas/"]
    COPY --> GIT_ADD["9. git add -A"]
    GIT_ADD --> GIT_COMMIT["10. git commit -m 'detallado'"]
    GIT_COMMIT --> GIT_PUSH["11. git push --force"]
    GIT_PUSH --> DEPLOY["12. adb install -r"]
    DEPLOY --> VERIFY["13. Verificar App"]
    VERIFY --> REPORT(["Reporte Final"])

    subgraph Tests Criticos
        TC1[unit/]
        TC2[widget/]
        TC3[integration/]
    end

    subgraph Tests Adicionales
        TA1[pwa/]
        TA2[performance/]
        TA3[supabase/]
        TA4[regression/]
    end

    TEST_CRIT --> TC1
    TEST_CRIT --> TC2
    TEST_CRIT --> TC3
    TEST_ALL --> TA1
    TEST_ALL --> TA2
    TEST_ALL --> TA3
    REG --> TA4
```

## Mapa de Dependencias de Skills

```mermaid
mindmap
    root((Skills))
        sync-management
            Offline-First Strategy
            Sync Silencioso
            Conflict Resolution
            Queue Management
        financial-analysis
            Balance Calculations
            Financial Ratios
            Category Management
            Amount Validation
        flutter-architecture
            Repository Pattern
            Riverpod Providers
            GoRouter Navigation
            State Management
        testing
            Unit Tests
            Widget Tests
            Integration Tests
            PWA/Offline Tests
            Supabase/RLS Tests
            Performance Tests
        data-testing
            In-App Generator
            RPA Python CLI
            Test Data Patterns
            Import/Export
        error-tracker
            Error Documentation
            Anti-Patterns Registry
            Recurrence Detection
            Regression Test Generation
            Solution History
```

## Ciclo de Vida de Release

```mermaid
stateDiagram-v2
    [*] --> Development: Nuevo feature/fix

    Development --> ErrorSearch: Buscar errores similares
    ErrorSearch --> Development: Revisar anti-patrones
    
    Development --> Testing: Codigo listo
    Testing --> Development: Tests fallan
    Testing --> ErrorDoc: Tests pasan
    
    ErrorDoc --> Build: Documentar error si aplica
    Build --> Documentation: APK generado
    Documentation --> Git: Docs actualizados
    Git --> Deploy: Push exitoso

    Deploy --> Verification: Instalado
    Verification --> [*]: Release completo
    Verification --> Development: Problemas encontrados
```

---

## Leyenda

| Simbolo | Significado |
|---------|-------------|
| `-->` | Flujo directo |
| `-.->` | Flujo opcional/async |
| `<-->` | Bidireccional |
| `[(DB)]` | Base de datos |
| `[/cmd]` | Comando slash |

---

**Version**: 2.2.0
**Ultima actualizacion**: 2026-01-05
**Tests**: 500+
**Skills**: 6 dominios
**Commands**: 11
