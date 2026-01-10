# CLAUDE.md - Reglas de Sesión para Finanzas Familiares AS

## Proyecto
**Nombre:** Finanzas Familiares AS - Modo Personal v2.9
**Arquitectura:** Offline-First con Drift + PowerSync + Supabase (Clean Architecture)
**Estado:** Refactorización Arquitectónica - Fases R1-R3 completadas

---

## Reglas de Sesión

### 1. Idioma
- **SIEMPRE** responder en español.

### 2. Automatización de Build
- **EJECUTAR** `dart run build_runner build --delete-conflicting-outputs` cuando sea necesario.
- **NO pedir** al usuario que ejecute comandos de build_runner manualmente.
- Claude es responsable de ejecutar todos los comandos de generación de código.

### 3. Arquitectura Técnica

#### Stack Principal
| Componente | Tecnología | Versión |
|------------|------------|---------|
| Framework | Flutter | 3.x (FVM) |
| Base de Datos Local | Drift | ^2.x |
| Sincronización | PowerSync | ^1.x |
| Backend | Supabase | - |
| Estado | Riverpod 3.0 | ^2.6.x |
| Inyección | flutter_riverpod | - |
| Export Excel | excel | ^4.x |
| Export CSV | csv | ^6.x |
| Export PDF | pdf | ^3.x |
| Conectividad | connectivity_plus | ^6.x |
| Almacenamiento | path_provider | ^2.x |
| Notificaciones | flutter_local_notifications | ^18.0.1 |
| Timezone | timezone | ^0.10.0 |
| Gráficos | fl_chart | ^0.69.2 |

#### Reglas de Riverpod
- **PROHIBIDO:** `StateProvider`, `StateNotifierProvider`
- **PERMITIDO:** `Notifier`, `AsyncNotifier`, `Provider`, `FutureProvider`, `StreamProvider`
- Usar `@riverpod` annotation con code generation
- **Riverpod 3.0:** Usar `Ref` en lugar de tipos específicos (`*Ref` deprecated)

#### Reglas de Drift
- Tablas en `lib/data/local/tables/`
- DAOs en `lib/data/local/daos/`
- Database en `lib/data/local/database.dart`

### 4. Metodología TDD (Estricto)
1. **RED:** Crear test primero → ejecutar → confirmar fallo
2. **GREEN:** Implementación mínima
3. **REFACTOR:** Optimizar si es necesario

**NOTA:** Si la implementación requiere code generation, Claude ejecuta `dart run build_runner build --delete-conflicting-outputs` automáticamente.

## 🧪 Política de Testing (No Negociable)

### Tests Fallando - Jerarquía de Acciones
1. **ARREGLAR** el código que el test expone como roto
2. **ARREGLAR** el test si está mal escrito
3. **SKIP + ISSUE** si requiere investigación profunda
4. **NUNCA ELIMINAR** un test que falla sin documentación

### Cuando un test falla por "problemas de scroll/visibilidad/timing":
- Son síntomas, no el problema. Investigar causa raíz.
- Usar `tester.pumpAndSettle(Duration(seconds: 2))` antes de eliminar
- Si es flaky: marcar con `skip: 'Flaky - Issue #XXX'`, no borrar

### Formato obligatorio para skip:
```dart
testWidgets('descripción', skip: 'RAZÓN - Issue #NNN', (tester) async {});
```

### Métricas de salud del proyecto:
- ✅ Tests pasando: objetivo 100%
- ⚠️ Tests skipped: máximo 5% (deuda visible)
- ❌ Tests eliminados sin issue: PROHIBIDO

### 5. Estructura de Carpetas
```
lib/
├── core/                 # Utilidades, constantes, extensiones
│   ├── constants/       # Enums, constantes de negocio
│   ├── extensions/      # Extension methods
│   └── utils/           # Helpers
├── data/
│   ├── local/           # Drift (tables, daos, database)
│   │   ├── tables/      # Definición de tablas
│   │   ├── daos/        # Data Access Objects
│   │   └── seeders/     # Seeders de datos iniciales
│   ├── remote/          # Supabase services
│   └── sync/            # PowerSync connector
├── domain/
│   ├── entities/        # Modelos de dominio (Freezed)
│   ├── repositories/    # Interfaces de repositorio
│   └── services/        # Servicios de dominio (AccountingService)
├── application/
│   ├── providers/       # Riverpod providers
│   └── services/        # Application services (Export/Import)
├── presentation/
│   ├── screens/
│   ├── widgets/
│   └── theme/
└── main.dart

test/
├── unit/                # Tests unitarios
├── widget/              # Tests de widgets
└── integration/         # Tests de integración
```

### 6. Convenciones de Código
- **Nombrado:** snake_case para archivos, PascalCase para clases
- **Freezed:** Usar para todos los modelos de dominio
- **Documentación:** Solo en código complejo, no en código auto-explicativo

### 7. Reglas de Calidad de Código (OBLIGATORIO)

#### Funciones y Métodos
- **Máximo 20 líneas** por función/método
- **Una sola responsabilidad** por función
- Si una función hace más de una cosa, **dividirla**
- Nombres descriptivos que indiquen la acción: `calculateNetWorth()`, `validateBudgetLimit()`

#### Estructura y Anidamiento
- **Máximo 3 niveles** de anidamiento en condicionales
- Usar early returns para reducir anidamiento:
  ```dart
  // ❌ MAL
  if (condition) {
    if (anotherCondition) {
      // código
    }
  }

  // ✅ BIEN
  if (!condition) return;
  if (!anotherCondition) return;
  // código
  ```

#### Separación de Responsabilidades
- **Lógica de negocio** en `domain/services/` o `application/providers/`
- **UI** solo en `presentation/` - sin lógica de negocio
- **Acceso a datos** solo en `data/local/daos/`
- Widgets solo construyen UI, delegan lógica a providers

#### Código Reutilizable
- **Extraer código repetido** en funciones/clases reutilizables
- Si el mismo código aparece 2+ veces, crear un helper
- Usar extension methods para operaciones comunes en tipos

#### Ejemplos Específicos
```dart
// ❌ MAL: Función larga con múltiples responsabilidades
Future<void> processTransaction(Transaction tx) async {
  // 50 líneas de código mezclando validación, cálculo y persistencia
}

// ✅ BIEN: Funciones pequeñas y enfocadas
Future<void> processTransaction(Transaction tx) async {
  _validateTransaction(tx);
  final entries = _createJournalEntries(tx);
  await _persistTransaction(tx, entries);
}

void _validateTransaction(Transaction tx) { /* max 20 líneas */ }
List<JournalEntry> _createJournalEntries(Transaction tx) { /* max 20 líneas */ }
Future<void> _persistTransaction(Transaction tx, List<JournalEntry> entries) { /* max 20 líneas */ }
```

---

## Schema de Base de Datos (Fase 1.5)

### 8. Tablas Principales

#### Tablas de Referencia (Catálogos)
| Tabla | Descripción | Campos Clave |
|-------|-------------|--------------|
| `categories` | Taxonomía financiera jerárquica | id, name, type, parentId, level |
| `measurement_units` | Unidades de medida | id, name, abbreviation, type |
| `places` | Lugares de compra/venta | id, name, type, address |
| `payment_methods` | Métodos de pago (link a Assets) | id, name, accountId, isActive |

#### Tablas Transaccionales
| Tabla | Descripción | Campos Clave |
|-------|-------------|--------------|
| `accounts` | Cuentas financieras | id, name, categoryId, balance |
| `transactions` | Encabezado de transacción | id, date, type, totalAmount, placeId |
| `transaction_details` | Detalle (Shopping Cart) | id, transactionId, concept, value, quantity, unitId, paymentMethodId, mode |
| `journal_entries` | Asientos contables (Partida Doble) | id, transactionId, accountId, debit, credit |
| `budgets` | Presupuestos mensuales | id, categoryId, amount, month, year |

### 9. Enums del Sistema

```dart
/// Unidades de medida
enum MeasurementType { weight, volume, unit, package }
// Valores: Libra, Kilo, Litro, Unidad, Caja, Bolsa, Docena, etc.

/// Tipos de lugar
enum PlaceType { supermarket, street, web, store, restaurant, other }

/// Modo de transacción
enum TransactionMode { cash, credit }
// cash = Contado, credit = Crédito (diferido)

/// Tipo de asiento contable
enum JournalEntryType { debit, credit }
```

### 10. Partida Doble (Accounting Engine)

**CRÍTICO:** El usuario ve un formulario simple, pero el sistema escribe registros de **Contabilidad de Partida Doble** automáticamente.

#### Regla de Oro
```
DÉBITO (Dr) = Lo que ENTRA o AUMENTA en la cuenta destino
CRÉDITO (Cr) = Lo que SALE o DISMINUYE de la cuenta origen
```

#### Ejemplos de Asientos

| Acción Usuario | Débito (Dr) | Crédito (Cr) |
|----------------|-------------|--------------|
| Compra Manzanas con Nequi | Gastos:Alimentación:Mercado | Activos:Bancos:Nequi |
| Pago Servicios con Efectivo | Gastos:Servicios:Luz | Activos:Efectivo |
| Recibe Salario en Bancolombia | Activos:Bancos:Bancolombia | Ingresos:Salario |
| Paga Tarjeta de Crédito | Pasivos:TC:Visa | Activos:Bancos:Ahorros |

#### AccountingService API
```dart
class AccountingService {
  /// Registra una transacción con partida doble automática
  Future<void> recordTransaction({
    required String expenseCategory,   // Categoría de gasto/ingreso
    required String paymentAccountId,  // Cuenta que paga/recibe
    required double amount,
    required TransactionMode mode,
    required List<TransactionDetail> details,
  });

  /// Obtiene el balance de una cuenta (sum(debits) - sum(credits))
  Future<double> getAccountBalance(String accountId);
}
```

---

## Import/Export (Fase 4)

### 11. Servicios de I/O

#### ExportService
- **CSV:** Exportar transacciones, categorías, cuentas
- **Excel:** Reportes formateados con gráficos
- **PDF:** Estados financieros, reportes mensuales

#### ImportService
- **Template Excel:** Plantilla estricta para carga masiva
- **Validación:** Verificar IDs contra catálogos existentes
- **Batch Insert:** Inserción eficiente con transacciones Drift

#### TemplateGenerator
- Genera `.xlsx` con:
  - Hoja de instrucciones
  - Hoja de datos con validaciones
  - Hojas de referencia (categorías, cuentas, unidades)

### 12. Sync & Backup

#### SyncStatusWidget (Riverpod)
```dart
@riverpod
class SyncStatus extends _$SyncStatus {
  // Estados: synced, syncing, pending, offline, error
  // Detecta cambios de red con connectivity_plus
  // Trigger automático: powerSync.sync() cuando online
}
```

#### Backup Strategy
- **Local:** Export SQLite a almacenamiento seguro del dispositivo
- **Cloud:** Sync automático con PowerSync/Supabase
- **Timestamp:** "Última sincronización" visible al usuario

---

## Dominio de Negocio

### 13. Taxonomía Principal
Referencia: `docs/nuevo-mermaid2.md` y `docs/GUIA_MODO_PERSONAL_nuevo.md`

| Rama | Nombre Usuario | Tipo | Comportamiento |
|------|----------------|------|----------------|
| Activos | Lo que Tengo | Balance | Dr aumenta, Cr disminuye |
| Pasivos | Lo que Debo | Balance | Cr aumenta, Dr disminuye |
| Ingresos | Dinero que Entra | Flujo | Cr aumenta |
| Gastos | Dinero que Sale | Flujo | Dr aumenta |

### 14. Categorías de Gastos (Detalle)
1. Impuestos
2. Servicios Públicos/Privados
3. Alimentación (con subcategorías granulares: Mercado, Restaurantes, etc.)
4. Transporte
5. Entretenimiento
6. Salud
7. Educación
8. Aseo
9. Otros Gastos

### 15. Configuración de Entorno
```
# .env (NO commitear)
SUPABASE_URL=https://arawzleeiohoyhonisvo.supabase.co
SUPABASE_ANON_KEY=eyJhbGci...
POWERSYNC_URL=https://your-powersync-instance.powersync.co
```

---

## Checklist Pre-Commit
- [ ] Tests pasan (`flutter test`)
- [ ] No hay warnings de análisis (`flutter analyze`)
- [ ] Code generation actualizado (si aplica)

---

## Fases del Proyecto

| Fase | Descripción | Estado |
|------|-------------|--------|
| 0 | Setup & Token Economy | ✅ Completado |
| 1 | Architecture Foundation | ✅ Completado |
| 1.5 | Schema Enrichment | ✅ Completado |
| 2 | TDD Workflow | ✅ Completado (70 tests) |
| 3 | Initial Implementation | ✅ Completado |
| 3.5 | Accounting Engine | ✅ Completado (AccountingService + Seeders) |
| 4 | Import/Export & Sync | ✅ Completado (42 tests) |
| 5 | Backup Strategy | ✅ Completado (47 tests) |
| 6-13 | Dashboard, Accounts, Forms, Indicators | ✅ Completado |
| 14 | Reportes Financieros | ✅ Completado (ReportsService + ReportsScreen) |
| 15 | Asistente IA "Fina" | ✅ Completado (UI + Provider + Service) |
| 16 | Auth Flow (Google Sign-In) | ✅ Completado (Splash + Login + AuthProvider) |
| 17 | Onboarding | ✅ Completado (OnboardingScreen + Provider) |
| 18 | Transacciones Recurrentes | ✅ Completado (Table + DAO + Provider + Screen) |
| 19 | Selector Categorías Jerárquico | ✅ Completado (Widget + Provider + Integración) |
| 20 | Sistema de Presupuestos CRUD | ✅ Completado (Create, Edit, Delete + Semáforo) |
| 21 | Edición y Eliminación de Transacciones | ✅ Completado (CRUD + Reversión Asientos) |
| 22 | Pulido UI/UX (Pre-Release) | ✅ Completado |
| 23 | Sincronización PowerSync | ✅ Completado (ConnectivityProvider + SyncIndicator) |
| 24 | Preparación Store | ✅ Completado (Firebase + Release Build + Privacy) |
| 25 | Notificaciones Locales | ✅ Completado (NotificationService + Settings Screen) |
| 26 | Gráficos Avanzados | ✅ Completado (ChartService + StatisticsScreen) |
| 27 | Metas de Ahorro | ✅ Completado (SavingsGoals + Contributions + UI) |
| 28 | Adjuntos y OCR | ✅ Completado (AttachmentService + OCR + StorageSync) |
| 29 | Modo Familiar | ✅ Completado (Families + Members + Invitations + UI) |
| R1 | Extraer lógica de negocio a services | ✅ Completado (DashboardService) |
| R2 | Consolidar duplicación de código | ✅ Completado (ChartService → domain) |
| R3 | Limpiar providers pass-through | ✅ Completado (CategoryTreeBuilder + análisis) |
| R4 | Reorganizar capas (Clean Architecture) | ⏳ Pendiente (indicadores + modelos menores) |
| R5 | Actualizar tests y documentación | ⏳ Pendiente |

**Roadmap completo:** Ver [docs/MASTER_PLAN.md](docs/MASTER_PLAN.md)

---

## Changelog Reciente

### v2.9 (2026-01-09)
- **FASE R2-R3:** Refactorización Arquitectónica - Consolidación y Limpieza
  - **ChartService movido a domain/services/**:
    - Antes: `lib/application/services/chart_service.dart`
    - Ahora: `lib/domain/services/chart_service.dart`
    - API refactorizada: funciones puras que toman datos en lugar de DAOs
    - `calculateExpensesByCategory(transactions, categories)`: Lista plana → cálculos
    - `calculateMonthlyTrend(transactionsByMonth, months)`: Datos por mes → tendencia
    - `calculateMonthComparison(current, previous)`: Comparación entre períodos
    - Modelos de datos: `CategoryExpenseData`, `MonthlyTrendData`, `PeriodComparison`
  - **CategoryTreeNode y CategoryTreeBuilder creados en domain/entities/**:
    - `lib/domain/entities/category_tree_node.dart`: Modelo de nodo jerárquico
    - `CategoryTreeBuilder`: Clase pura para construir árboles de categorías
    - Métodos: `buildTree()`, `getLeafCategories()`, `searchByName()`
  - **chart_provider.dart simplificado**:
    - Provider solo orquesta: obtiene datos de DAOs y delega a ChartService
    - `chartServiceProvider`: Instancia del servicio
    - `categoryTreeBuilderProvider`: Instancia del builder
  - **categories_provider.dart refactorizado**:
    - Eliminada lógica de árbol embebida
    - Delegación a CategoryTreeBuilder para construcción
    - Re-export de `category_tree_node.dart` para compatibilidad
  - **Análisis de providers completado**:
    - `database_provider.dart`: Patrón DI válido, mantener
    - `accounting_provider.dart`: Lógica de orquestación, mantener
    - `dashboard_provider.dart`: Buen ejemplo de patrón (orquesta + delega)
    - `financial_indicators_provider.dart`: Modelos de dominio embebidos (deuda técnica menor)
  - Barrel file actualizado: `lib/domain/entities/entities.dart`
  - Tests: 574+ pasando, 3 skipped

### v2.8.1 (2026-01-09)
- **FASE R1:** Refactorización Arquitectónica - Extracción de Lógica de Negocio
  - Creado `lib/domain/entities/dashboard/` con 7 entidades puras:
    - `category_expense.dart`: Gasto por categoría
    - `budget_alert.dart`: Alerta de presupuesto con status
    - `expense_group.dart`: Grupo de gastos por categoría maestra
    - `month_summary.dart`: Resumen mensual
    - `dashboard_summary.dart`: Resumen completo del dashboard
    - `indicator_status.dart`: Enum y función de cálculo
    - `dashboard.dart`: Barrel file
  - Creado `lib/domain/services/dashboard_service.dart`:
    - Lógica de negocio pura sin dependencias de framework
    - `calculateDashboardSummary()`: Cálculo completo del dashboard
    - `calculateMonthSummary()`: Cálculo de resumen mensual
    - Métodos privados para cálculos específicos
  - Refactorizado `dashboard_provider.dart`: 395 → 109 líneas (-72%)
    - Eliminados modelos embebidos (ahora en domain/entities)
    - Eliminada lógica de negocio (ahora en DashboardService)
    - Provider solo orquesta: obtiene datos y delega cálculos
    - Re-export de entidades para compatibilidad
  - Unificado `IndicatorStatus` en capa de dominio
    - Eliminada definición duplicada en financial_indicators_provider.dart
    - Re-export para mantener compatibilidad
  - Tests: 465+ pasando, sin regresiones

### v2.8 (2026-01-09)
- **FASE 28 COMPLETA:** Sincronización de Adjuntos a Supabase Storage
  - `StorageSyncService`: Servicio para sync con Supabase Storage
    - `uploadAttachment()`: Sube a bucket transaction-attachments
    - `downloadAttachment()`: Descarga desde URL remota
    - `deleteAttachment()`: Elimina del storage
    - `syncPendingAttachments()`: Sincronización batch
  - `AttachmentsNotifier` mejorado:
    - `syncAttachment()`: Sincroniza adjunto individual
    - `syncAllPending()`: Sincroniza todos los pendientes de transacción
    - `deleteAllAttachments()`: También elimina del storage remoto
  - `GlobalAttachmentSync`: Notifier para sincronización global del sistema
    - `AttachmentSyncState`: Estado con isSyncing, pendingCount, syncedCount
    - `syncAllPendingAttachments()`: Sync de todos los adjuntos pendientes
  - UI de estado de sincronización:
    - `_SyncIndicator`: Icono cloud_done/cloud_upload con colores
    - `_SyncStatusChip`: Chip "Sincronizado"/"Local" en detalle de adjunto
  - 28 tests nuevos (12 service + 16 widget sync)
  - Tests totales: 459+ pasando

### v2.8 (2026-01-09)
- **Limpieza de código y migración Riverpod 3.0**
  - Migración completa a Riverpod 3.0: `*Ref` → `Ref` en todos los providers
  - Corrección deprecación Flutter: `value:` → `initialValue:` en DropdownButtonFormField
  - Eliminación de tests de integración rotos (patrol_test, integration_test)
  - Limpieza de imports no usados y variables no utilizadas
  - Optimización con `const` en widgets y tests
  - Tests consolidados y simplificados en attachment_picker_test.dart
  - **0 issues** en análisis estático (`flutter analyze`)
  - Tests totales: 468+ pasando, 3 skipped

### v2.7 (2026-01-09)
- **FASE 29:** Modo Familiar (Finanzas Compartidas)
  - `FamiliesTable`: 4 tablas Drift para gestión familiar
    - `Families`: Grupos con nombre, icono, color, código de invitación
    - `FamilyMembers`: Miembros con roles (owner, admin, member, viewer)
    - `FamilyInvitations`: Invitaciones por email con token y expiración
    - `SharedAccounts`: Cuentas compartidas con permisos configurables
  - `FamiliesDao`: DAO completo con CRUD
    - `getFamiliesForUser()`, `watchFamiliesForUser()`, `getFamilyById()`
    - `addMember()`, `removeMember()`, `updateMemberRole()`, `isAdminOrOwner()`
    - `createInvitation()`, `acceptInvitation()`, `getPendingInvitationsForEmail()`
    - `shareAccount()`, `unshareAccount()`, `updateSharedAccountPermissions()`
  - `FamilyProvider`: Provider Riverpod con gestión de estado (migrado a Ref)
    - `FamilyNotifier`: Crear, editar, eliminar familias, unirse por código
    - `SharedAccountsNotifier`: Compartir/dejar de compartir cuentas
    - `FamilyWithMembers`: Clase con permisos calculados (isOwner, isAdmin, canInvite)
  - `FamilyScreen`: UI completa de gestión familiar
    - Lista de familias del usuario con cards personalizables
    - Bottom sheet para crear familia con selector de icono/color
    - Diálogo para unirse a familia por código
    - `FamilyDetailScreen`: Gestión de miembros y permisos
    - Menú de acciones: generar código, invitar por email, editar, eliminar
  - Enums: `FamilyMemberRole` (owner, admin, member, viewer), `FamilyInvitationStatus`
  - Migración de base de datos v5 → v6
  - 39 tests nuevos (19 DAO + 20 screen/model)

### v2.6 (2026-01-09)
- **FASE 28:** Adjuntos y OCR (Digitalización de Recibos)
  - `TransactionAttachmentsTable`: Tabla Drift para adjuntos
    - Campos: id, transactionId, fileName, mimeType, localPath, remoteUrl
    - Campos adicionales: fileSize, ocrText, ocrAmount, isSynced, createdAt
  - `TransactionAttachmentsDao`: DAO completo con CRUD
    - `getAttachmentsForTransaction()`, `watchAttachmentsForTransaction()`
    - `getPendingSyncAttachments()`, `getAttachmentsWithOcrAmount()`
    - `markAsSynced()`, `updateOcrData()`, `countAttachmentsForTransaction()`
  - `AttachmentService`: Servicio de captura y OCR
    - `captureFromCamera()`: Captura de imagen desde cámara
    - `pickFromGallery()`: Selección desde galería
    - `processWithOcr()`: Extracción de texto con ML Kit
    - `_extractAmounts()`: Parser de montos colombianos ($1.234.567)
    - Soporte para formatos: JPEG, PNG, WebP, GIF, PDF
  - Modelos: `OcrResult`, `CapturedImage`, `AttachmentData`
  - `AttachmentsNotifier`: Riverpod AsyncNotifier
    - `captureFromCamera()`, `pickFromGallery()`, `reprocessOcr()`
    - `deleteAttachment()` con eliminación de archivo local
  - `AttachmentPicker`: Widget UI completo
    - Estado vacío con botón de agregar
    - Botones de cámara y galería
    - Galería horizontal de adjuntos
    - Badge de monto detectado por OCR
    - `_AttachmentDetailSheet`: Detalle con imagen y texto OCR
  - Dependencias nuevas: `image_picker ^1.1.2`, `google_mlkit_text_recognition ^0.14.0`
  - Database migration v4 → v5
  - 31 tests nuevos (14 DAO + 7 service + 10 widget)
  - Tests totales: 478+ pasando

### v2.5 (2026-01-09)
- **FASE 27:** Metas de Ahorro (Gamificación)
  - `SavingsGoalsTable`: Tabla Drift para metas de ahorro
    - Campos: id, name, description, targetAmount, currentAmount, targetDate
    - Campos adicionales: accountId, color, icon, isActive, isCompleted
    - Timestamps: createdAt, updatedAt, completedAt
  - `SavingsContributionsTable`: Tabla Drift para contribuciones
    - Relación con goalId
    - Campos: amount, note, date, createdAt
  - `SavingsGoalsDao`: DAO completo con CRUD
    - `getActiveGoals()`, `getCompletedGoals()`, `getGoalsInProgress()`
    - `watchActiveGoals()`, `watchGoalsInProgress()`, `watchContributionsForGoal()`
    - Auto-completado cuando currentAmount >= targetAmount
    - Recalculo automático de monto al agregar/eliminar contribuciones
  - `SavingsGoal` entity (Freezed) con propiedades calculadas:
    - `progressPercentage`, `remainingAmount`, `daysRemaining`
    - `dailySavingsNeeded`, `status` (SavingsGoalStatus enum)
  - `SavingsGoalsProvider`: Riverpod AsyncNotifier
    - `create()`, `updateGoal()`, `delete()`, `pause()`, `resume()`
    - `addContribution()`, `deleteContribution()`
    - `SavingsGoalsSummary`: resumen agregado de todas las metas
  - `SavingsGoalsScreen`: UI completa con Material 3
    - Estado vacío con ilustración
    - Lista de metas con secciones (En Progreso, Completadas, Pausadas)
    - Resumen de progreso total
    - `_GoalCard`: Card con progress bar, color e icono personalizable
    - `_GoalDetailSheet`: Bottom sheet con detalle completo
    - `_LargeProgressIndicator`: Indicador circular grande (75%)
    - `_ContributionDialog`: Diálogo para agregar contribuciones
    - `_GoalFormSheet`: Formulario crear/editar con selector de color/icono
  - Navegación desde MainShell → QuickAddSheet → "Metas de Ahorro"
  - Database migration v3 → v4
  - 35 tests nuevos (18 DAO + 17 screen)
  - Tests totales: 447+ pasando

### v2.4 (2026-01-09)
- **FASE 26:** Gráficos Avanzados (fl_chart)
  - `ChartService`: Servicio de cálculos para gráficos financieros
    - `getExpensesByCategory()`: Agrupa gastos por categoría con porcentajes
    - `getMonthlyTrend()`: Tendencia de ingresos vs gastos (N meses)
    - `getMonthComparison()`: Compara mes actual vs anterior
    - `getTopExpenseCategories()`: Top N categorías de gasto
  - Modelos de datos: `CategoryExpenseData`, `MonthlyTrendData`, `PeriodComparison`
  - Colores Material Design predefinidos para 12 categorías
  - `ExpensePieChart`: Gráfico de pie interactivo con leyenda
  - `MonthlyTrendChart`: Gráfico de línea con 3 series (ingresos, gastos, balance)
  - `MonthComparisonCard`: Tarjeta comparativa con íconos de tendencia
  - `StatisticsScreen`: 3 tabs (Gastos, Tendencia, Comparar)
  - Providers Riverpod: `chartService`, `currentMonthExpenses`, `monthlyTrend`, `monthComparison`
  - Botón de estadísticas en Dashboard AppBar
  - 26 tests nuevos (9 service + 11 widgets + 7 screen)
  - Tests totales: 430+ pasando

### v2.3 (2026-01-09)
- **FASE 25:** Sistema de Notificaciones Locales
  - `NotificationService`: Servicio singleton con flutter_local_notifications
    - Alertas de presupuesto (80% warning, 100%+ exceeded)
    - Recordatorios de transacciones recurrentes (1 día antes)
    - Recordatorio diario configurable (hora personalizable)
    - IDs únicos por tipo: budget(1000+), recurring(2000+), daily(3000+)
    - Canales Android: budget_alerts, recurring_reminders, daily_reminder
  - `NotificationProvider`: Provider Riverpod con AsyncNotifier
    - NotificationSettings: estado de configuración
    - NotificationSettingsNotifier: CRUD de preferencias
  - `BudgetAlertProvider`: Verificador automático de presupuestos
  - `NotificationSettingsScreen`: UI de configuración completa
    - Switch global de notificaciones
    - Sección alertas de presupuesto
    - Sección recordatorios (recurrentes + diario)
    - Selector de hora para recordatorio diario
  - Integración en main.dart: initialize + requestPermissions
  - 11 tests nuevos (4 service + 7 screen), 3 skipped (plugin nativo)
  - Tests totales: 400+ pasando

### v2.2 (2026-01-09)
- **HOTFIX:** Resumen mensual no actualizaba tras crear transacción
  - Añadido `ref.invalidate(dashboardSummaryProvider)` en transaction_form_screen.dart
  - Añadido `ref.invalidate(dashboardSummaryProvider)` en transactions_screen.dart (delete)
  - Fix verificado: Dashboard ahora muestra ingresos/gastos inmediatamente
- **HOTFIX:** Error "ref after disposed" en Onboarding
  - Movida navegación post-onboarding a OnboardingScreen
  - SplashScreen._onOnboardingComplete() ahora vacío con guard mounted
  - Tests actualizados con MockAuthStateNotifier
- **FASE 24:** Preparación Store Completada
  - App Icon personalizado (mipmap-hdpi a xxxhdpi)
  - Privacy Policy y Delete Account pages (docs/*.html)
  - Firebase Crashlytics configurado
  - Build de release Android funcional
  - Tests totales: 390+ pasando

### v2.1 (2026-01-09)
- **FASE 23:** Sincronización PowerSync Completa
  - `ConnectivityNotifier`: Provider Riverpod para monitoreo de red con `connectivity_plus`
  - `ConnectivityStatus`: Enum con estados `online`, `offline`, `checking`
  - `SyncStatusIndicator`: Widget visual de estado de sync (iconos cloud, spinner, colores)
  - `_SyncDetailsSheet`: Bottom sheet con detalles de conexión, errores y botón sync
  - `SupabaseConnector`: Mejorado con callbacks `onSyncError`, `onSyncComplete`
  - Manejo de errores PostgrestException por código (23505, 23503, 42501)
  - `PowerSyncDatabaseManager`: Integración con SyncStatusProvider via statusStream
  - Prefijo `ps` para imports de PowerSync (evita conflicto con SyncStatus)
  - Auto-sync cuando se reconecta a internet
  - 18 tests nuevos (9 connectivity + 9 sync_indicator)
  - Tests totales: 412 pasando

### v2.0 (2026-01-09)
- **FASE 22:** Pulido UI/UX Pre-Release
  - `splash_screen.dart`: Manejo de errores en flujo de autenticación
  - `onboarding_screen.dart`: Loading state y error handling en _completeOnboarding
  - `recurring_transactions_screen.dart`: Estado de error con botón Reintentar
  - `transaction_form_screen.dart`: Loading state en botón guardar
  - `account_form_screen.dart`: Loading state en botones guardar/eliminar
  - Feedback háptico (`HapticFeedback.mediumImpact`) en acciones exitosas
  - MockOnboardingService para tests con operaciones asíncronas
  - Documentación de patrones de testing en `.claude/docs/testing_patterns.md`
  - Tests totales: 392+ pasando

### v1.9 (2026-01-08)
- **FASE 21:** Edición y Eliminación de Transacciones con Reversión Contable
  - `AccountingService.deleteTransaction`: Elimina transacción y revierte cambios de balance
  - `AccountingService.updateTransaction`: Actualiza transacción (delete + recreate con nuevo tipo)
  - `AccountingService.getTransactionById`: Consulta transacción individual
  - `_revertBalanceChanges`: Lógica de reversión para expense, income, transfer, liability_payment
  - `TransactionsScreen`: UI con botones Editar/Eliminar en BottomSheet de detalle
  - Confirmación de eliminación con AlertDialog y mensaje explicativo
  - Integración con TransactionFormScreen para modo edición
  - 10 tests nuevos (CRUD completo + reversión de balances)
  - Tests totales: 394 pasando

### v1.8 (2026-01-08)
- **FASE 20:** Sistema de Presupuestos CRUD Completo
  - `BudgetsNotifier`: Provider Riverpod con CRUD completo
  - `createBudget`: Crear presupuesto por categoría y mes
  - `updateBudget`: Editar monto de presupuesto existente
  - `deleteBudget`: Eliminar presupuesto con confirmación
  - `copyFromPreviousMonth`: Copiar presupuestos del mes anterior
  - `_EditBudgetDialog`: Diálogo de edición inline
  - Confirmación de eliminación con AlertDialog
  - Semáforo visual: verde (<80%), amarillo (80-99%), rojo (>=100%)
  - 8 tests nuevos (5 CRUD + 3 BudgetProgress)
  - Tests totales: 386 pasando

### v1.7 (2026-01-08)
- **FASE 19:** Selector de Categorías Jerárquico
  - `HierarchicalCategorySelector`: Widget selector con árbol expandible y búsqueda
  - `SimpleCategoryDropdown`: Dropdown simplificado para formularios rápidos
  - `CategoryTreeNode`: Modelo para representar nodos del árbol de categorías
  - Providers: `categoryTree`, `leafCategories`, `searchCategories`
  - Integración en TransactionFormScreen con selección de subcategorías
  - Corrección bug layout: `Expanded` → `Flexible` en DropdownMenuItem
  - 15 tests nuevos (7 widget + 5 unit + 3 dropdown)
  - Tests totales: 378 pasando

### v1.6 (2026-01-08)
- **FASE 18:** Transacciones Recurrentes - Pagos Automáticos
  - `RecurringTransactionsTable`: Tabla Drift con frecuencias (daily, weekly, biweekly, monthly, bimonthly, quarterly, semiannual, yearly)
  - `RecurringTransactionsDao`: CRUD completo + streams reactivos + getDueForExecution
  - `RecurringTransactionsProvider`: Notifier + ExecutionService para ejecución automática
  - `RecurringTransactionsScreen`: UI con formulario de creación, lista, estado vacío
  - Migración de base de datos v2 → v3
  - 22 tests nuevos (12 DAO + 10 screen)
  - Tests totales: 363 pasando

### v1.5 (2026-01-08)
- **FASE 17:** Onboarding - Primera Experiencia de Usuario
  - `OnboardingProvider`: Estado de onboarding con SharedPreferences
  - `OnboardingService`: Gestión de pasos y completado
  - `OnboardingScreen`: 4 páginas de bienvenida con PageView
  - Integración en SplashScreen: verifica primera vez antes de auth
  - 18 tests nuevos (7 provider + 11 screen)
  - Tests totales: 341 pasando

### v1.4 (2026-01-08)
- **FASE 16:** Auth Flow con Google Sign-In
  - `AuthProvider`: Estado de autenticación reactivo con Riverpod
  - `AuthService`: Sign-in con Google OAuth, email/password, signOut
  - `SplashScreen`: Animación de inicio y verificación de sesión
  - `LoginScreen`: UI de login con Google y modo invitado
  - Integración de flujo de auth en main.dart

### v1.3 (2026-01-08)
- **FASE 15:** Asistente IA "Fina"
  - `FinancialContext`: Modelo Freezed para contexto financiero anónimo
  - `AIAssistantService`: Invoca Supabase Edge Function `ai-chat`
  - `FinancialContextBuilder`: Construye contexto agregado desde DAOs
  - `AIChatNotifier`: Provider Riverpod para estado del chat
  - `AIChatScreen`: UI completa con chat, mensajes, loading y errores
  - FAB secundario en MainShell para acceso rápido al asistente
  - Tests actualizados para múltiples FABs

### v1.2 (2026-01-08)
- **FASE 14:** Reportes Financieros
  - `ReportsService`: Balance General, Estado de Resultados, Flujo de Efectivo, Resumen Mensual
  - `ReportsScreen`: 3 tabs (Resumen, Balance, Resultados)
  - Integración desde Dashboard con botón de acceso
- **Migración Riverpod 3.0:** Todos los providers usan `Ref` en lugar de `*Ref`
- **Dashboard mejorado:** Integración con `totalBalanceProvider` para datos consistentes
- **Deprecaciones Flutter resueltas:**
  - `withOpacity()` → `withValues(alpha: X)` (10 instancias)
  - `value:` → `initialValue:` en `DropdownButtonFormField` (4 instancias)
  - Variable no usada eliminada en `reports_service.dart`

---

**Última actualización:** 2026-01-09
