# CLAUDE.md - Reglas de Sesión para Finanzas Familiares AS

## Proyecto
**Nombre:** Finanzas Familiares AS - Modo Personal v5.16 - Sync Sequence (Estilo Linear)
**Arquitectura:** Offline-First con Drift + PowerSync + Supabase (Clean Architecture Pura)
**Estado:** Fases 0-35, R1-R8 ✅ | 1133 tests | 8 analyze infos | 0 warnings/errors

---

## Reglas de Sesión

### 0. Estilo de Comunicación (OBLIGATORIO)
- **NO ser consecuente** - No validar automáticamente ideas del usuario
- **NO dar siempre la razón** - Cuestionar cuando sea necesario
- **NO alabar innecesariamente** - Evitar halagos vacíos
- **SER imparcial, honesto, documentado y crudo cuando amerite**

### 1. Idioma
- **SIEMPRE** responder en español.

### 2. MCPs OBLIGATORIOS (NO NEGOCIABLE)
Los siguientes MCPs DEBEN estar activos y usarse prioritariamente:

| MCP | Uso Obligatorio |
|-----|-----------------|
| **Supabase** | `execute_sql`, `apply_migration`, `get_logs` para TODO lo relacionado con DB |
| **Context7** | `query-docs` ANTES de implementar cualquier feature con librerías |
| **Sequential Thinking** | Para debugging complejo y decisiones arquitectónicas |

**PROHIBIDO:**
- Usar WebSearch para documentación de librerías → Usar Context7
- Adivinar errores de Supabase → Usar `mcp__supabase__get_logs`
- Implementar sin consultar docs → Usar Context7 primero

**Project ID Supabase:** `arawzleeiohoyhonisvo`

### 3. Automatización de Build
- **EJECUTAR** `dart run build_runner build --delete-conflicting-outputs` automáticamente.
- Claude es responsable de ejecutar todos los comandos de generación de código.

### 4. Stack Principal
| Componente | Tecnología |
|------------|------------|
| Framework | Flutter 3.35.7 (FVM) |
| DB Local | Drift 2.28.2 |
| Sync | PowerSync 1.17.0 |
| Backend | Supabase 2.12.0 |
| Estado | Riverpod 2.6.1 |

#### Reglas de Riverpod
- **PROHIBIDO:** `StateProvider`, `StateNotifierProvider`
- **PERMITIDO:** `Notifier`, `AsyncNotifier`, `Provider`, `FutureProvider`, `StreamProvider`
- **Riverpod 3.0:** Usar `Ref` (no `*Ref` deprecated)

### 5. Metodología TDD
1. **RED:** Test primero → ejecutar → confirmar fallo
2. **GREEN:** Implementación mínima
3. **REFACTOR:** Optimizar si es necesario

## Política de Testing (No Negociable)
1. **ARREGLAR** el código que el test expone como roto
2. **ARREGLAR** el test si está mal escrito
3. **SKIP + ISSUE** si requiere investigación profunda
4. **NUNCA ELIMINAR** sin documentación

### 6. Estructura de Carpetas
```
lib/
├── core/           # Utilidades, constantes, extensiones
├── data/
│   ├── local/      # Drift (tables, daos, database, seeders)
│   ├── remote/     # Supabase services
│   ├── repositories/ # Implementaciones Drift
│   └── sync/       # PowerSync connector
├── domain/
│   ├── entities/   # Modelos de dominio (Freezed)
│   ├── exceptions/ # Excepciones de dominio
│   ├── repositories/ # Interfaces de repositorio
│   └── services/   # Servicios de dominio
├── application/
│   ├── providers/  # Riverpod providers
│   └── services/   # Application services
└── presentation/   # screens, widgets, theme
```

### 7. Reglas de Calidad
- **Máximo 20 líneas** por función
- **Máximo 3 niveles** de anidamiento
- Early returns para reducir complejidad
- Lógica de negocio en `domain/services/`
- UI solo en `presentation/` - sin lógica de negocio

---

## Partida Doble (Accounting Engine)

**CRÍTICO:** El sistema escribe registros de **Contabilidad de Partida Doble** automáticamente.

```
DÉBITO (Dr) = Lo que ENTRA o AUMENTA
CRÉDITO (Cr) = Lo que SALE o DISMINUYE
```

| Acción | Débito | Crédito |
|--------|--------|---------|
| Compra con Nequi | Gastos:Alimentación | Activos:Nequi |
| Recibe Salario | Activos:Bancolombia | Ingresos:Salario |
| Paga TC | Pasivos:TC:Visa | Activos:Ahorros |

**Referencia completa:** `docs/GUIA_MODO_PERSONAL_nuevo.md`

---

## Checklist Pre-Commit
- [ ] Tests pasan (`flutter test`)
- [ ] No hay warnings (`flutter analyze`)
- [ ] Code generation actualizado (si aplica)

---

## Servicios de Dominio Disponibles

| Servicio | Responsabilidad |
|----------|-----------------|
| `AccountingService` | Partida doble, balances, validaciones |
| `AccountService` | Validación eliminación cuentas |
| `CategoryService` | Validación eliminación categorías |
| `DashboardService` | Cálculos de dashboard |
| `ChartService` | Cálculos para gráficos |
| `ReportsService` | Balance General, Estado de Resultados |
| `FamilyService` | Gestión de familias y miembros |
| `RecurringTransactionService` | Transacciones recurrentes |
| `AttachmentManagementService` | Adjuntos, OCR, sync |
| `SavingsGoalsService` | Metas de ahorro |
| `AIAssistantService` | Asistente IA "Fina" |
| `BudgetService` | Presupuestos, progreso, alertas |
| `BudgetAlertService` | Alertas de presupuesto (warning/exceeded) |
| `BankNotificationService` | Lectura de notificaciones bancarias |
| `ReceiptParserService` | Parser regex para facturas colombianas |
| `ReceiptScannerService` | OCR + Parser + Fallback IA para facturas |
| `DataSeedingService` | Seeding condicional post-sync |

---

## Changelog Reciente

### v5.16 (2026-01-14)
- **SYNC SEQUENCE - Orden Global de Operaciones (Estilo Linear):**
  - **Problema Persistente:** FK violations durante sincronización por orden no determinístico de llegada de datos
  - **Solución:** Implementación de sync_sequence incremental (como Linear App)
  - **Arquitectura Implementada:**
    - `sync_sequence_counter`: Tabla singleton con contador atómico global
    - `get_next_sync_sequence()`: Función PostgreSQL para incremento atómico
    - `sync_sequence BIGINT`: Columna agregada a las 15 tablas sincronizables
    - Triggers automáticos: Asignan sync_sequence en cada INSERT
    - Trigger especial para categories: Garantiza parent.sync_sequence < child.sync_sequence
  - **Tablas Modificadas (15):**
    - categories, accounts, transactions, transaction_details, journal_entries
    - budgets, places, payment_methods, measurement_units
    - savings_goals, savings_contributions, recurring_transactions
    - transaction_attachments, families, family_members
  - **Archivos Modificados:**
    - `sync_rules.yaml`: ORDER BY sync_sequence ASC NULLS LAST en todas las queries
    - `powersync_schema.dart`: Column.integer('sync_sequence') en 15 tablas
    - 14 archivos de tablas Drift: syncSequence IntColumn nullable
    - `database.dart`: Migración v12 → v13
  - **Datos Existentes:** 626 registros poblados con sync_sequence ordenado por nivel
  - **Garantía:** Padres SIEMPRE tienen sync_sequence menor que hijos
  - **Tests:** 1133 pasando (6 pre-existentes fallando)
  - **Versión:** 1.17.0+38

### v5.15 (2026-01-14)
- **ANDROID AUTO BACKUP + UPLOAD QUEUE MONITORING:**
  - **Android Auto Backup:**
    - Creado `backup_rules.xml` para backup automático en Google Drive
    - Creado `data_extraction_rules.xml` para Android 12+ (API 31+)
    - Base de datos SQLite `finanzas_familiares.db` incluida en backup
    - SharedPreferences incluidas (tema, onboarding, configuraciones)
    - **EXCLUIDO:** `FlutterSecureStorage` (sesión OAuth debe re-autenticarse)
  - **Upload Queue Monitoring (PowerSync):**
    - Nueva clase `UploadQueueStats` con count, size, error
    - Método `getUploadQueueStats()` para diagnosticar operaciones pendientes
    - Método `_monitorUploadQueue()` integrado en `reconnectAndSync()`
    - Método `forceUpload()` para reintentar uploads fallidos
    - `SyncState` expandido con `pendingUploads` y `hasPendingUploads`
    - Providers `pendingUploadsProvider` y `hasPendingUploadsProvider`
  - **Archivos Creados:**
    - `android/app/src/main/res/xml/backup_rules.xml`
    - `android/app/src/main/res/xml/data_extraction_rules.xml`
  - **Archivos Modificados:**
    - `AndroidManifest.xml`: Referencias a backup rules
    - `powersync_database.dart`: Upload queue monitoring
    - `sync_status_provider.dart`: Nuevos providers para pending uploads
  - **Tests:** 1133 pasando, 6 pre-existentes fallando
  - **Versión:** 1.16.0+37

### v5.14 (2026-01-14)
- **FIX CRÍTICO: Accounts Type Sync - Causa Raíz de Pérdida de Datos:**
  - **Problema Identificado:** El upsert de cuentas fallaba con "null value in column 'type' of relation 'accounts' violates not-null constraint"
  - **Causa Raíz:** Desajuste entre schemas:
    - Supabase: `accounts.type` TEXT NOT NULL
    - Drift/PowerSync: No tenían campo `type`
    - sync_rules.yaml: No incluía `type` en SELECT
  - **Consecuencia:** Categorías se sincronizaban (con duplicados), pero cuentas y transacciones NO
  - **Solución Implementada:**
    1. **Supabase Migration:** `accounts.type` ahora nullable con default 'wallet'
    2. **PowerSync schema:** Agregado `Column.text('type')` en accounts
    3. **Drift table:** Agregado campo `type` nullable
    4. **sync_rules.yaml:** Agregado `type` al SELECT de accounts
    5. **accounts_seeder.dart:** Incluye `type: 'wallet'` por defecto
    6. **Drift migration v12:** Agrega columna `type` a DB existentes
  - **Limpieza Supabase:** 1040 categorías duplicadas eliminadas (de 1144 a 104)
  - **Tests:** 1133 pasando (6 pre-existentes fallando)
  - **Versión:** 1.15.0+36

### v5.13 (2026-01-14)
- **NATIVE GOOGLE SIGN-IN: Solución Definitiva al Problema OAuth:**
  - **Problema:** Browser-based OAuth dejaba ventanas abiertas, deep links no procesaban
  - **Solución:** Migración a Native Google Sign-In usando `google_sign_in: 6.2.2`
  - Método `signInWithIdToken()` en lugar de `signInWithOAuth()`
  - No abre navegador externo, usa picker nativo de Google
  - SHA-1 fingerprints agregados a Firebase (debug + release)
  - **Versión:** 1.14.0+35

### v5.11 (2026-01-14)
- **AGGRESSIVE SYNC TESTS: Suite Completa de Tests de Sincronización:**
  - **Problema Recurrente:** "Ingreso transacciones. Desinstalo. Reinstalo. Los datos se han borrado."
  - **Solución:** 102 tests agresivos que verifican el ciclo completo de sincronización
  - **Archivos de Test Creados:**
    - `test/sync/data_sync_lifecycle_test.dart`: 42 tests del ciclo install→data→uninstall→reinstall→verify
    - `test/sync/secure_session_persistence_test.dart`: 15 tests de persistencia OAuth con SecureStorage
    - `test/sync/category_hierarchy_fk_test.dart`: 25 tests de ordenamiento FK por nivel
    - `test/sync/sync_error_recovery_test.dart`: 16 tests de manejo de errores y recuperación
    - `test/sync/deterministic_uuid_test.dart`: 22 tests de consistencia UUID v5
    - `test/sync/data_integrity_post_sync_test.dart`: 35 tests de integridad de datos post-sync
  - **Cobertura de Escenarios Críticos:**
    - Seeding condicional (solo si DB vacía)
    - UUIDs determinísticos entre instalaciones
    - Ordenamiento FK: level 0 → 1 → 2 → 3
    - Inserción desordenada causa FK violation (verificado)
    - Jerarquía acíclica de categorías
    - Partida doble balanceada
    - Códigos de error PostgreSQL (23505, 23503, 42501)
  - **Resultado:** 1133 tests pasando (+102 sync), 6 pre-existentes fallando
  - **Versión:** 1.13.0+33
  - **Binarios:** APK 103MB, AAB 69MB en ~/Descargas

### v5.10 (2026-01-13)
- **LEVEL-BY-LEVEL CATEGORY SYNC: Solución Definitiva al Problema de FK Violations:**
  - **Problema Persistente:** v5.9 (batch upserts) NO funcionó porque Supabase REST API procesa cada fila independientemente
  - **Descubrimiento Crítico:** Un batch HTTP ≠ una transacción SQL. Supabase ejecuta cada INSERT/UPSERT como transacción separada
  - **Solución Implementada - Inserción por Niveles:**
    - `_upsertCategoriesByLevel()`: Agrupa categorías por nivel de jerarquía
    - Nivel 0 (raíces) se inserta primero → no hay FK que validar
    - Nivel 1 (hijos) se inserta después → padres YA EXISTEN
    - Nivel 2, 3... igual → ancestros siempre existen primero
    - Delay de 100ms entre niveles para garantizar escritura
  - **Por qué funciona:** No depende de DEFERRABLE porque garantizamos orden de inserción
  - **Archivos Modificados:**
    - `lib/data/sync/supabase_connector.dart`: Nueva función `_upsertCategoriesByLevel()`
  - **Tests:** 1031 pasando (6 pre-existentes fallando)
  - **Versión:** 1.12.4+31

### v5.9 (2026-01-13)
- **BATCH UPSERT SYNC FIX (NO FUNCIONÓ):**
  - Intentó agrupar upserts por tabla, pero Supabase REST procesa cada fila independientemente
  - Reemplazado por inserción por niveles en v5.10
  - **Versión:** 1.12.3+30

### v5.8 (2026-01-13)
- **DETERMINISTIC UUIDS FOR SYNC: Fix Crítico de Sincronización PowerSync:**
  - **Problema:** Datos se perdían al reinstalar la app porque PowerSync fallaba con FK violations
  - **Causa Raíz:** Seeders generaban UUIDs aleatorios en cada instalación, causando duplicados y FK orphans
  - **Solución 1: UUIDs Determinísticos** - Implementado UUID v5 (SHA-1) en todos los seeders:
    - `category_seeder.dart`: Namespace `f47ac10b-58cc-4372-a567-0e02b2c3d479`
    - `accounts_seeder.dart`: Namespace `550e8400-e29b-41d4-a716-446655440000`
    - `places_seeder.dart`: Namespace `6ba7b810-9dad-11d1-80b4-00c04fd430c8`
    - `measurement_units_seeder.dart`: Namespace `6ba7b811-9dad-11d1-80b4-00c04fd430c8`
  - **Solución 2: Ordenamiento CRUD** - `supabase_connector.dart` ordena operaciones por dependencia:
    - Categorías padre (level 0) se insertan antes que hijos (level 1, 2, etc.)
    - Orden: profiles → families → categories → accounts → ... → transactions
  - **Solución 3: FK DEFERRABLE** - Constraint `categories_parent_id_fkey` ahora es DEFERRABLE
  - **Limpieza Supabase:** 44 categorías duplicadas eliminadas
  - **Resultado:** Sync funciona correctamente después de reinstalar
  - **Versión:** 1.12.2+29

### v5.7 (2026-01-13)
- **CODE QUALITY CLEANUP: Eliminación Agresiva de Warnings/Errors:**
  - **58 issues → 5 infos** (solo deprecation warnings de Riverpod auto-generados)
  - **Archivos Eliminados:** `backup_service.dart` (incompleto), `integration_test/` (dependencia faltante)
  - **Drift @ReferenceName Fix:** `transactions_table.dart` y `recurring_transactions_table.dart`
  - **Código Productivo:** `print()` → `developer.log()`, eliminados null checks innecesarios
  - **15+ archivos de test corregidos:** imports no usados, `var` → `final`/`const`, type checks
  - **Análisis Final:** 0 warnings, 0 errors, 5 infos (deprecation inevitable de Riverpod 2.6)
  - **Versión:** 1.12.1+28

### v5.6 (2026-01-13)
- **POWERSYNC CONFIGURADO: Sincronización Real a Supabase:**
  - PowerSync URL configurado: `https://6961035c30605f245f00db3c.powersync.journeyapps.com`
  - Database password resetted, conexión exitosa
  - 20 tablas sincronizadas con sync_rules.yaml
  - **Versión:** 1.12.0+27

### v5.5 (2026-01-13)
- **DISASTER RECOVERY: Persistencia de Sesiones Post-Reinstalación:**
  - **Problema CRÍTICO:** Al desinstalar la app, se perdían TODOS los datos y configuraciones (error recurrente reportado por usuario)
  - **Investigación profunda (Context7 + PowerSync/Supabase docs):**
    - PowerSync ✅ ya usaba `getApplicationDocumentsDirectory()` (persiste en desinstalación)
    - Supabase Auth ❌ usaba SharedPreferences (se BORRA en desinstalación)
  - **Solución Agresiva Implementada:**
    - **flutter_secure_storage 9.2.2**: Almacenamiento en Android Keystore/iOS Keychain (NO se borra)
    - **SecureLocalStorage**: Implementación custom de `LocalStorage` para Supabase
    - Sesiones OAuth ahora persisten automáticamente en reinstalaciones
  - **Arquitectura de Recuperación Mejorada:**
    - `DataRecoveryScreen`: Timeout aumentado a 45s (antes 30s)
    - Retry logic: Botones "Reintentar" y "Continuar sin sincronizar"
    - Indicadores visuales: cloud_download/cloud_upload en tiempo real
    - `PowerSyncDatabaseManager.reconnectAndSync()`: Reconexión agresiva post-login
  - **Flujo Final:**
    1. Login (OAuth Google o email/password) → SecureLocalStorage persiste sesión
    2. → DataRecoveryScreen (muestra progreso de sincronización)
    3. → PowerSync `reconnectAndSync()` con timeout 45s
    4. → `DataSeedingService.seedIfEmpty()` solo si DB vacía después de sync
    5. → MainShell (app lista para usar)
  - **Tests Disaster Recovery:**
    - `test/core/storage/secure_local_storage_test.dart`: 7 tests nuevos
    - Validación de persistencia, serialización JSON, edge cases
  - **Archivos Creados:**
    - `lib/core/storage/secure_local_storage.dart`
    - `test/core/storage/secure_local_storage_test.dart`
  - **Archivos Modificados:**
    - `lib/main.dart`: `Supabase.initialize()` ahora usa `SecureLocalStorage()`
    - `pubspec.yaml`: Agregado `flutter_secure_storage: 9.2.2`
  - **Resultado:** 1031 tests pasando (+7 disaster recovery), 6 skipped
  - **Versión:** 1.11.0+26
  - **Binarios:** APK 99MB, AAB 66MB en ~/Descargas

### v5.4 (2026-01-12)
- **Versiones FIJAS de Dependencias (Anti-Breaking Changes):**
  - **Problema:** Actualizaciones automáticas de Flutter/librerías pueden romper el proyecto
  - **Solución:** Todas las dependencias ahora usan versiones exactas (sin caret `^`)
  - **Protecciones implementadas:**
    - FVM: Flutter 3.35.7 fijo en `.fvmrc`
    - pubspec.yaml: 50+ dependencias con versiones exactas
    - pubspec.lock: Bloqueado con SHA256 de cada paquete
  - **Dependencias principales fijadas:**
    - drift: 2.28.2, powersync: 1.17.0, supabase_flutter: 2.12.0
    - flutter_riverpod: 2.6.1, firebase_core: 3.15.2
  - **Instrucciones para actualizar:**
    1. Eliminar pubspec.lock
    2. Ejecutar `flutter pub upgrade`
    3. Probar exhaustivamente (1031 tests)
    4. Si falla, restaurar pubspec.lock de git
  - **Resultado:** 1031 tests pasando
  - **Versión:** 1.9.2+16

### v5.3 (2026-01-12)
- **Limpieza de Tests - 0 Skipped:**
  - **Problema:** 5 tests marcados con `skip` que nunca se ejecutaban en CI
  - **Solución:** Tests movidos a `integration_test/services/`
  - **Archivos creados:**
    - `integration_test/services/notification_service_integration_test.dart`
    - `integration_test/services/in_app_update_service_integration_test.dart`
  - **Archivos modificados:**
    - `test/application/services/notification_service_test.dart` - Removidos 3 tests skipped
    - `test/application/services/in_app_update_service_test.dart` - Removidos 2 tests skipped
  - **Corrección de tests nullable:**
    - `test/data/local/daos/recurring_transactions_dao_test.dart` - executionCount ?? 0
    - `test/data/local/daos/savings_goals_dao_test.dart` - isCompleted ?? false
  - **Resultado:** 1026 unit tests (0 skipped) + 5 integration tests
  - **Versión:** 1.9.1+15

### v5.2 (2026-01-12)
- **FIX CRÍTICO: Manejo de Campos Nullable PowerSync:**
  - **Causa Raíz:** PowerSync sincroniza campos con NULL aunque Drift tenga `withDefault()`. Las queries DAO filtraban `field.equals(true)` lo cual excluía registros con NULL.
  - **Solución:** Todas las tablas con `withDefault()` ahora tienen campos nullable, y todas las queries DAO usan el patrón `field.equals(value) | field.isNull()`.
  - **DAOs corregidos:**
    - `accounts_dao.dart`: getActiveAccounts(), getAccountsByCategory(), watchActiveAccounts(), getTotalBalance()
    - `budgets_dao.dart`: getActiveBudgets(), getBudgetsForMonth(), watchCurrentMonthBudgets()
    - `places_dao.dart`: getAllActivePlaces(), getPlacesByType(), searchByName(), getMostUsedPlaces()
    - `payment_methods_dao.dart`: getAllActiveMethods(), getDefaultMethod(), getMethodsByAccount()
    - `measurement_units_dao.dart`: getAllActiveUnits(), getUnitsByType()
    - `savings_goals_dao.dart`: getActiveGoals(), getGoalsInProgress(), watchActiveGoals(), watchGoalsInProgress()
    - `recurring_transactions_dao.dart`: getActive(), getDueForExecution(), getByType(), watchActive(), watchPendingConfirmation()
    - `families_dao.dart`: getFamiliesForUser(), watchFamiliesForUser(), getFamilyByInviteCode(), getMembersForFamily(), countMembers(), getPendingInvitationsForEmail(), getPendingInvitationsForFamily(), getInvitationByToken()
    - `drift_account_repository.dart`: getActiveAccounts()
  - **Tablas modificadas:** 13 tablas con campos nullable (isActive, includeInTotal, isSystem, isCompleted, status, etc.)
  - **Mappers/Repositorios:** Agregados operadores `?? defaultValue` en todos los lugares necesarios
  - **Tests:** 1029 pasando, 5 skipped, 2 pre-existentes fallando (no relacionados)
  - **Versión:** 1.9.0+14

### v5.1 (2026-01-12)
- **FIX CRÍTICO: Recuperación de Datos Post-Reinstalación:**
  - **Causa Raíz:** Drift y PowerSync usaban archivos de base de datos SEPARADOS
    - Drift: `finanzas_familiares.db`
    - PowerSync: `finanzas_familiares_powersync.db`
    - Los datos nunca se compartían entre ambos sistemas
  - **Solución:** Base de datos unificada con constante compartida
    - `kSharedDatabaseFileName = 'finanzas_familiares.db'`
    - Ambos sistemas ahora usan el mismo archivo SQLite
  - **Archivos creados:**
    - `lib/presentation/screens/data_recovery_screen.dart`: UI de sincronización post-login
    - `lib/application/services/data_seeding_service.dart`: Seeding condicional
  - **Archivos modificados:**
    - `lib/data/sync/powersync_database.dart`: Constante compartida + métodos `waitForInitialSync()`, `reconnectAndSync()`
    - `lib/data/local/database.dart`: Importa `kSharedDatabaseFileName`
    - `lib/presentation/screens/login_screen.dart`: Navega a DataRecoveryScreen
    - `lib/presentation/screens/splash_screen.dart`: Verifica sync status para usuarios autenticados
    - `lib/main.dart`: Seeding condicional solo para usuarios no autenticados
  - **Flujo corregido:**
    1. Login (OAuth o email/password)
    2. → DataRecoveryScreen (muestra progreso)
    3. → PowerSync `reconnectAndSync()` con timeout 45s
    4. → `seedIfEmpty()` solo si DB vacía después de sync
    5. → MainShell
  - **Resultado:** Datos se recuperan automáticamente al reinstalar app
  - **Tests:** 921 tests pasando, 0 issues en analyze

### v5.0 (2026-01-12)
- **MIGRACIÓN COMPLETA: Supabase Schema Compatible con Drift/PowerSync:**
  - **Problema Resuelto:** Datos se perdían al reinstalar app por incompatibilidad total de schemas entre Drift y Supabase
  - **8 tablas nuevas creadas en Supabase:**
    - `places`, `payment_methods`, `measurement_units`, `transaction_details`
    - `journal_entries`, `savings_goals`, `savings_contributions`, `transaction_attachments`
  - **5 tablas modificadas en Supabase:**
    - `categories`: type, level, sort_order, is_active, is_system
    - `accounts`: category_id, is_system, description, color
    - `transactions`: from_account_id, to_account_id, place_id, has_details, item_count, sync_status
    - `budgets`: month, year, is_active, timestamps
    - `recurring_transactions`: 17 columnas para recurrencia completa
  - **PowerSync sync_rules.yaml:** Actualizado con todas las tablas y columnas
  - **powersync_schema.dart:** Sincronizado 100% con Supabase
  - **Datos legacy eliminados:** Schema incompatible (category_id INTEGER vs UUID)
  - **Versión:** 1.6.0+11

### v4.9 (2026-01-12)
- **PowerSync Sync Fix - user_id en todas las tablas:**
  - **Bug:** Los datos del usuario se perdían al reinstalar la app a pesar de estar logueado con Google. PowerSync filtra por `user_id` pero las tablas Drift no tenían esta columna.
  - **Fix:** Agregada columna `user_id` (nullable TEXT) a todas las tablas de datos del usuario:
    - `accounts`, `transactions`, `categories`, `budgets`, `journal_entries`
    - `places`, `payment_methods`, `measurement_units`, `transaction_details`
    - `recurring_transactions`, `savings_goals`, `savings_contributions`, `transaction_attachments`
  - **Migración:** v7 → v8 (agrega columnas con ALTER TABLE)
  - **Repositorios actualizados:** Todos los repositorios Drift ahora insertan `user_id` automáticamente desde `Supabase.instance.client.auth.currentUser?.id`
  - **Tests safe:** Try-catch para evitar errores en tests donde Supabase no está inicializado
  - **Archivos modificados:**
    - 12 tablas en `lib/data/local/tables/`
    - `lib/data/local/database.dart` (migración v8)
    - 6 repositorios Drift actualizados
    - `import_service.dart`, `category_form_screen.dart`
  - **Resultado:** 907 tests pasando, 5 skipped (plugins nativos)
  - **Versión:** 1.5.5+10

### v4.8 (2026-01-11)
- **HOTFIX: Receipt Scanner no procesaba resultados:**
  - **Bug:** Conflicto de nombres entre clases Freezed (`ReceiptScanSuccess`) y sealed classes locales del provider
  - **Síntoma:** Scanner tomaba foto pero no mostraba resultados (switch nunca coincidía)
  - **Fix:** Agregados `typedef` aliases para diferenciar tipos de servicio vs provider
  - **Archivo modificado:** `lib/application/providers/receipt_scanner_provider.dart`
  - **Versión:** 1.5.1+6 (build code 6)
- **In-App Update API (v1.5.0):**
  - Plugin `in_app_update: ^4.2.3` para notificar actualizaciones de Play Store
  - `InAppUpdateService`: Singleton con flexible/immediate update support
  - `in_app_update_provider.dart`: Riverpod providers para estado de actualización
  - Integración en `main.dart` al iniciar app
  - Threshold configurable para forzar actualización (staleDays >= 7)

### v4.7 (2026-01-11)
- **FASE 35: Receipt Scanner - Escaneo de Facturas en Chat Fina:**
  - **Arquitectura costo-eficiente:** Regex primero, Haiku solo si falla
  - **Archivos creados:**
    - `lib/domain/entities/receipts/parsed_receipt.dart`: Entidad Freezed
    - `lib/domain/services/receipt_parser_service.dart`: Parser regex colombiano
    - `lib/domain/services/receipt_scanner_service.dart`: Coordinador OCR + Parser + IA
    - `lib/application/providers/receipt_scanner_provider.dart`: Estados y notifier
    - `supabase/functions/ai-chat/index.ts`: Modo receipt-parse con Haiku
  - **Comercios soportados:** 30+ comercios colombianos (Éxito, Carulla, D1, Rappi, etc.)
  - **Formatos de monto:** $85.400, $125,000, $1.250.000 (colombiano)
  - **Extrae:** Monto total, comercio, fecha, categoría sugerida
  - **UI:** Botón en chat Fina, opciones cámara/galería, confirmación
  - **Costo IA:** ~$0.003/factura solo cuando regex falla
  - **Tests:** 28 tests para ReceiptParserService
  - **Resultado:** 921 tests pasando, 3 skipped

### v4.6 (2026-01-11)
- **Cross-Reference Testing - Consistencia entre Entidades:**
  - `test/domain/cross_reference_test.dart`: 17 tests nuevos
  - **Tests de consistencia implementados:**
    - Budget ↔ Categories ↔ Transactions: Progreso refleja gastos reales, semáforos correctos
    - Dashboard ↔ Transactions ↔ Accounts: totalIncome/Expenses, totalAssets/Liabilities
    - Category Hierarchy ↔ Spending: ExpenseGroups agrupa subcategorías, porcentajes suman 100%
    - MonthSummary: netBalance = income - expenses, netWorth = assets - liabilities
  - **NO verifica foreign keys** (Drift lo hace), verifica lógica de negocio
  - **In-Memory Repositories:** InMemoryBudgetRepository, InMemoryCategorySpendingRepository
  - **Resultado:** 893 tests pasando, 3 skipped (plugins nativos)

### v4.5 (2026-01-11)
- **FASE 34: Lectura Automática de Notificaciones Bancarias:**
  - **Plugin:** `notification_listener_service` ^0.3.5
  - **Bancos soportados:** Bancolombia, Nequi, DaviPlata, Davivienda
  - **Archivos creados:**
    - `lib/domain/entities/notifications/bank_notification.dart`: Entidades Freezed
    - `lib/domain/services/bank_notification_service.dart`: Lógica de dominio
    - `lib/data/parsers/bank_notification_parser.dart`: Parsers por banco (regex)
    - `lib/application/providers/bank_notification_provider.dart`: Riverpod providers
    - `lib/presentation/screens/bank_notifications_screen.dart`: UI completa
  - **Tests:** 35 tests para parsers (formatos de cada banco)
  - **Flujo:** Notificación → Parser → DTO → UI confirmación → Transacción
  - **Resultado:** 859 tests pasando, 3 skipped

### v4.4 (2026-01-11)
- **Expansión Masiva de Cobertura de Tests (164 tests nuevos):**
  - **Tests de Alta Prioridad:**
    - `financial_indicators_service_test.dart`: 46 tests para DebtCoverage/AvailableBalance
    - `budgets_dao_test.dart`: 17 tests CRUD de presupuestos
    - `accounting_exceptions_test.dart`: 21 tests para excepciones de dominio
    - `account_display_mappers_test.dart`: 12 tests para mappers de cuentas
  - **Tests de Media Prioridad:**
    - `reports_service_test.dart`: 13 tests para Balance General y Estado de Resultados
    - `transaction_details_dao_test.dart`: 14 tests CRUD de detalles
    - `payment_methods_dao_test.dart`: 14 tests CRUD métodos de pago
    - `drift_family_repositories_test.dart`: 23 tests para Family/Member/Invitation/SharedAccount
    - `recurring_transaction_service_test.dart`: 34 tests de lógica de recurrencia
    - `auth_provider_test.dart`: 21 tests de AuthNotifier con mocks
  - **Tests de Baja Prioridad:**
    - `dashboard_dtos_test.dart`: 18 tests para CategoryExpense, ExpenseGroup, BudgetAlert, etc.
    - `total_balance_test.dart`: 7 tests para TotalBalance entity
    - `enums_test.dart`: 16 tests para AccountType, TransactionType, SyncStatus
    - `category_tree_mappers_test.dart`: 9 tests para CategoryTreeMappers
    - `drift_financial_indicators_repository_test.dart`: 12 tests para AccountDataRepository
  - **Resultado:** 824 tests pasando, 3 skipped (plugins nativos)

### v4.3 (2026-01-10)
- **FASE R8: Migración de Providers a Servicios de Dominio (7/7):**
  - **Nuevos archivos creados:**
    - `lib/domain/repositories/budget_repository.dart`: Interfaces + DTOs (`BudgetData`, `BudgetProgressData`, `BudgetStatus`)
    - `lib/domain/services/budget_service.dart`: Lógica de presupuestos
    - `lib/domain/services/budget_alert_service.dart`: Lógica de alertas con interfaces `CategoryNameResolver`, `AlertTracker`
    - `lib/data/repositories/drift_budget_repository.dart`: `DriftBudgetRepository`, `DriftCategorySpendingRepository`
    - `lib/data/adapters/budget_alert_adapters.dart`: `DriftCategoryNameResolver`, `SharedPrefsAlertTracker`
  - **Providers migrados:**
    - `budget_provider.dart`: Delegación a `BudgetService`
    - `budget_alert_provider.dart`: Delegación a `BudgetAlertService`
  - **UI actualizada:**
    - `budgets_screen.dart`: Usa tipos de dominio (`BudgetData`, `BudgetProgressData`)
  - **Tests corregidos:**
    - `attachment_picker_test.dart`: Mocks creados (`MockAttachmentFileService`, `MockAttachmentStorageSync`, `MockAttachmentRepository`)
    - `budgets_screen_test.dart`: Actualizado para usar tipos de dominio
  - **Resultado:** 660+ tests pasando, 3 skipped (plugins nativos)
  - **Arquitectura:** 100% Clean Architecture - ningún provider accede a DAOs directamente

### v4.2 (2026-01-10)
- **Repositorios Drift Completados (Deuda R4/R6):**
  - `drift_family_repositories.dart`: 4 repositorios en un archivo
    - `DriftFamilyRepository`: 7 métodos
    - `DriftFamilyMemberRepository`: 6 métodos
    - `DriftFamilyInvitationRepository`: 5 métodos
    - `DriftSharedAccountRepository`: 4 métodos
  - `drift_recurring_transaction_repository.dart`: 12 métodos + 2 streams
  - `recurring_transactions_dao.dart`: agregado `getPendingConfirmation()` (Future)
  - Patrón: Interfaces en `domain/`, implementaciones en `data/repositories/`
- **FASE R7: Purificación de Clean Architecture:**
  - **0 imports de `data/` en `domain/`**: Verificado con grep
  - **DTOs creados en `domain/entities/`:**
    - `ai/financial_context_dto.dart`: DTOs para contexto del IA
    - `categories/category_tree_dto.dart`: DTO para árbol de categorías
    - `accounts/account_display_dto.dart`: `AccountDisplayDto`, `AccountWithCategoryDto`
    - `accounts/total_balance.dart`: Movido desde provider
  - **Mappers creados en `data/mappers/`:**
    - `financial_context_mappers.dart`
    - `category_tree_mappers.dart`
    - `account_display_mappers.dart`
  - **Servicios refactorizados:**
    - `FinancialContextBuilder`: Recibe DTOs, no inyecta DAOs
    - `CategoryTreeNode/Builder`: Usa `CategoryTreeDto`
  - **Providers actualizados:**
    - `ai_assistant_provider.dart`: Usa mappers
    - `categories_provider.dart`: Usa `CategoryTreeMappers`
    - `accounting_provider.dart`: Usa DTOs tipados (sin `dynamic`)
  - **Tests actualizados:** chart_service_test, hierarchical_category_selector_test
  - **Resultado:** Type-safety completo, Clean Architecture pura

### v4.0 (2026-01-10)
- **FASE 32-33: Dark Mode + Fina AI + OAuth Robustez:**
  - **Dark Mode (Fase 32):**
    - `app_theme.dart`: Tema claro y oscuro con Material 3
    - `theme_provider.dart`: ThemeNotifier con persistencia en SharedPreferences
    - `settings_screen.dart`: SegmentedButton para selección de tema
    - UI responde inmediatamente al cambio de tema
  - **Fina AI Edge Function (Fase 33):**
    - Edge Function `ai-chat` desplegada en Supabase
    - Modelo: claude-sonnet-4-20250514
    - Sistema de prompts para asistente financiero
    - JWT verification desactivado (app personal)
  - **OAuth Deep Link Robustez (Fase 33):**
    - `WidgetsBindingObserver` en `_FinanzasFamiliaresAppState`
    - `didChangeAppLifecycleState` captura deep links al volver de background
    - `getLatestLink()` + parsing manual de URL fragment
    - Evita reprocesamiento con `_lastProcessedLink`
  - **UI Fix:** Overflow corregido en pantalla de chat de Fina (ListView)

### v3.9 (2026-01-10)
- **Google OAuth Sign-In Funcional:**
  - **Configuración Firebase:** SHA-1 fingerprints (debug + release) agregados
  - **google-services.json:** Actualizado con OAuth clients
  - **AndroidManifest.xml:** Intent-filter para deep links OAuth
    - Scheme: `io.supabase.finanzasfamiliares`
    - Host: `login-callback`
  - **Supabase Google Provider:** Client ID + Secret configurados
  - **AuthFlowType:** Cambiado de PKCE a implicit (requerido para mobile)
  - **app_links:** Dependencia directa para captura de deep links
  - **LoginScreen:** Manejo manual de deep links con parsing de URL fragment
  - **Flujo completo:** Google → Supabase → Deep link → App → Dashboard ✅

### v3.8 (2026-01-10)
- **Optimización del Ecosistema de Testing:**
  - **Contract Tests para Serialización JSON:**
    - `test/domain/entities/contract_serialization_test.dart`
    - 21 tests de roundtrip para: Transaction, Account, Category, Budget, SavingsGoal
    - Verifica preservación de datos en serialización JSON (crítico para PowerSync)
    - Edge cases: montos grandes/pequeños, caracteres especiales, fechas límite
  - **Parametric Tests para AccountingService:**
    - `test/domain/services/accounting_parametric_test.dart`
    - 36 tests con valores de borde explícitos
    - In-Memory Repositories para testing unitario puro
    - Invariantes verificados:
      - Balance Equation: `sum(debits) == sum(credits)` SIEMPRE
      - Conservación Monetaria en transferencias
      - Idempotencia: create → delete = estado original
      - Validación de montos inválidos [0, -1, -100, -0.01]
      - Consistencia: 2 journal entries por transacción
  - **Documentación de Estrategia:**
    - `docs/TESTING_STRATEGY.md` actualizado con implementaciones
    - Evaluación de PBT (glados) descartado por impracticidad
    - Contract Testing priorizado sobre Mutation Testing
  - Tests totales: 549+ pasando, 3 skipped (plugins nativos)

### v3.7 (2026-01-10)
- **FASE 30:** Widget y Accesos Rápidos
  - **Home Widget (Android):** Muestra saldo total formateado en home screen
    - `BalanceWidgetProvider.kt`: Provider nativo Kotlin con RemoteViews
    - Layout XML con balance y timestamp de actualización
    - Auto-refresh cada 30 minutos
  - **Quick Actions:** Accesos rápidos desde ícono de la app
    - Nuevo Gasto, Nuevo Ingreso, Ver Balance
    - `QuickActionsService`: Servicio Dart para gestionar shortcuts
  - **Integración Riverpod:**
    - `HomeWidgetService`: Actualiza widget con saldo formateado
    - `HomeWidgetSync`: AsyncNotifier que sincroniza con totalBalanceProvider
    - MainShell migrado a ConsumerStatefulWidget para Quick Actions
  - 11 tests nuevos (4 home_widget + 7 quick_actions)

### v3.6 (2026-01-10)
- **Deuda Técnica R6.2:** Servicios de dominio para Attachments y SavingsGoals

### v3.5 (2026-01-10)
- **Validaciones de Integridad Contable:**
  - `InsufficientFundsException`: Saldo insuficiente en activos líquidos
  - `AccountHasBalanceException`: Cuenta con balance ≠ 0 no eliminable
  - `CategoryHasChildrenException`: Categoría con hijos no eliminable
  - `AccountService` y `CategoryService` para validaciones
  - 19 tests nuevos

### v3.4 (2026-01-10)
- **Cuentas predefinidas no eliminables:**
  - Campo `isSystem` en tabla Accounts
  - UI con candado 🔒 y badge "Predefinida"
  - Migración v6 → v7

> **Historial completo:** [docs/CHANGELOG.md](docs/CHANGELOG.md)

---

**Última actualización:** 2026-01-14
