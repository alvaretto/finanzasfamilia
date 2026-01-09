# CLAUDE.md - Reglas de Sesión para Finanzas Familiares AS

## Proyecto
**Nombre:** Finanzas Familiares AS - Modo Personal v2.4
**Arquitectura:** Offline-First con Drift + PowerSync + Supabase
**Estado:** En desarrollo - Fase 26 completada

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

**Roadmap completo:** Ver [docs/MASTER_PLAN.md](docs/MASTER_PLAN.md)

---

## Changelog Reciente

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
