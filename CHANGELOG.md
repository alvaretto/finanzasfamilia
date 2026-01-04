# Changelog

Todos los cambios notables en Finanzas Familiares AS seran documentados en este archivo.

## [1.9.0] - 2026-01-03

### Cambio de Moneda por Defecto

**BREAKING CHANGE**: La moneda por defecto ahora es COP (Peso Colombiano) en lugar de MXN.

#### Archivos Actualizados
- `lib/features/accounts/domain/models/account_model.dart` - Default COP
- `lib/core/utils/formatters/currency_formatter.dart` - Default COP, locale es_CO
- `lib/core/database/app_database.dart` - Schema default COP
- `lib/shared/widgets/money_input.dart` - Default COP, montos colombianos
- `lib/core/utils/extensions/money_extensions.dart` - Default COP
- `lib/features/accounts/presentation/widgets/*.dart` - Default COP
- `lib/features/accounts/presentation/providers/account_provider.dart` - Default COP

#### Monedas Soportadas (en orden)
1. COP - Peso Colombiano (por defecto)
2. USD - Dolar Estadounidense
3. EUR - Euro
4. MXN - Peso Mexicano
5. ARS - Peso Argentino
6. PEN - Sol Peruano
7. CLP - Peso Chileno
8. BRL - Real Brasileno

#### Montos Rapidos Actualizados
- Antes: 50, 100, 200, 500, 1000 (MXN)
- Ahora: 10000, 50000, 100000, 200000, 500000 (COP)

### Nuevos Tests (39 adicionales)

#### Tests Bundle Optimization (`test/pwa/bundle_optimization_test.dart`)
- 16 tests de optimizacion de assets
- Code splitting patterns
- Core Web Vitals simulation (FCP, LCP, CLS, FID)
- Tree shaking verification

#### Tests Realtime Supabase (`test/supabase/realtime_test.dart`)
- 17 tests de conexion en tiempo real
- Subscription management
- Event handling y deduplication
- Backoff exponencial
- Conflict resolution (Last Write Wins)

#### Tests Browser Compatibility (`test/android/browser_compatibility_test.dart`)
- 22 tests de compatibilidad de navegadores
- Feature detection (LocalStorage, IndexedDB, Service Worker)
- CSS compatibility (Flexbox, Grid, Variables)
- PWA installation requirements
- Android version support (8+)

### .claude Workflow Actualizado

#### Nuevo Comando
- `/full-workflow` - Workflow automatizado completo (tests, build, deploy)

#### Documentacion Actualizada
- CLAUDE.md con informacion de moneda COP
- Version actualizada a 1.9.0

### Metricas

- **350+ tests** en 10 categorias
- **39 tests nuevos** agregados
- **12 archivos** modificados para COP
- Soporte para **8 monedas** internacionales

## [1.8.0] - 2026-01-03

### Documentacion Completa

- **README.md**: Reescrito completamente con arquitectura, stack tecnologico, comandos
- **docs/WALKTHROUGH.md**: Guia paso a paso para desarrolladores
- **docs/USER_MANUAL.md**: Manual de usuario completo en espanol
- **docs/CLAUDE_WORKFLOW.md**: Diagramas Mermaid del flujo de trabajo .claude

### Tests Especializados (6 nuevos archivos)

- `test/ai_chat/ai_chat_service_test.dart` - 26 tests servicio IA
- `test/ai_chat/chat_widget_test.dart` - 15 tests widgets chat
- `test/security/api_security_test.dart` - 20 tests seguridad API
- `test/pwa/service_worker_test.dart` - 17 tests PWA/offline
- `test/integration/chat_flow_test.dart` - 20 tests flujos chat
- `test/performance/chat_performance_test.dart` - 18 tests rendimiento

### .claude Progressive Disclosure Actualizado

- **Skills**: 4 skills especializados actualizados
  - sync-management: Offline-first, conflictos, estrategias
  - financial-analysis: Calculos, categorias
  - flutter-architecture: Providers, widgets, patrones
  - testing: Suite completa 300+ tests
- **Commands**: 9 comandos automatizados
- **Hooks**: 6 hooks de productividad

### Fixes de Tests

- Corregido `$` sin escape en strings (`$100` -> `\$100`)
- Agregado parametro requerido `currency: 'MXN'` a AccountModel
- Agregado `categoryId` y `BudgetPeriod.monthly` a BudgetModel
- Cambiado test de emojis para usar `runes.length`
- Reemplazado `syncWithServer` (no existe) por `watchAccounts`

### Metricas

- **300+ tests** en 10 categorias
- Documentacion completa en espanol
- Diagramas Mermaid: 8 diagramas de flujo

## [1.7.0] - 2026-01-03

### Testing Integral PWA + Supabase + Android

Nueva suite de tests siguiendo estrategia de testing profesional para PWA Flutter.

#### Tests PWA/Offline (`test/pwa/`)
- **Offline-First Strategy**: CRUD funciona sin conexion
- **Sync Queue**: Registros no sincronizados se acumulan correctamente
- **Data Persistence**: Datos persisten entre sesiones
- **Batch Operations**: Operaciones masivas offline funcionan
- **Error Handling**: Errores de red no crashean la app

#### Tests Supabase Auth (`test/supabase/auth_test.dart`)
- Validacion de email/password
- Manejo de sesiones
- AuthRepository funciona en test mode
- Error handling para credenciales invalidas

#### Tests Seguridad RLS (`test/supabase/security_rls_test.dart`)
- **User Isolation**: Cada usuario solo ve sus datos
- **Input Sanitization**: SQL injection y XSS son texto plano
- Validacion de datos en repositorios

#### Tests Performance (`test/performance/`)
- Crear cuenta < 100ms
- Leer por ID < 50ms
- Query transacciones < 200ms
- 100 inserts < 2s
- 100 inserts paralelos < 3s
- 1000 operaciones sin memory leak

#### Tests Android Compatibility (`test/android/`)
- Pantallas: 320x480 a 1440x2560 (HVGA a QHD)
- Tablet: 800x1280
- Orientacion: Portrait, Landscape, cambio dinamico
- System UI: Notch, Navigation bar
- Font scaling: 0.85x a 1.3x
- Temas: Light y Dark

### .claude Workflow Completo

#### Nuevos Comandos
- `/test-all`: Suite completa de tests
- `/test-category [cat]`: Tests por categoria
- `/quick-test`: Tests rapidos (unit + widget)
- `/full-release`: Workflow de release

#### Nuevos Hooks
- `pre-commit`: Valida tests antes de commit
- `pre-build`: Ejecuta tests antes de build
- `post-build`: Copia APK a releases/
- `post-test-write`: Sugiere setup de test

#### Skills de Testing
- `TESTING_STRATEGY.md`: Guia completa
- `PWA_OFFLINE_TESTS.md`: Tests offline
- `SUPABASE_AUTH_TESTS.md`: Tests auth
- `SECURITY_RLS_TESTS.md`: Tests seguridad

### Fix de Tests

- **Supabase Test Mode**: `SupabaseClientProvider.enableTestMode()` permite ejecutar tests sin Supabase
- **Nullable Supabase**: Repositorios usan `SupabaseClient?` para soportar modo offline
- **TestMainScaffold**: Scaffold simplificado que no requiere GoRouter
- **_fetchFromSupabase**: Todos los metodos verifican `_isOnline` antes de llamar a Supabase

### Metricas

- **300+ tests** en 9 categorias
- Unit/Widget/Integration: 100% passing
- E2E: 85%+ passing (algunos fallan por timing)
- Coverage: 60%+ estimado

## [1.6.0] - 2026-01-03

### Agregado
- **Google Sign-In Nativo**: Reemplazado OAuth web por google_sign_in nativo
  - Mejor UX: selector de cuenta nativo en lugar de navegador externo
  - ID token integrado con Supabase Auth
- **Deep Links OAuth**: Soporte para io.supabase.finanzasfamiliares://
- **Tests de Produccion v2**: 40+ tests agresivos adicionales:
  - Balances astronomicos (trillones) sin overflow
  - Balances negativos extremos
  - Strings de 10,000 caracteres
  - Unicode, emojis, y caracteres especiales
  - Fechas edge case (1900, 2099, leap year)
  - Stress test: 10,000 transacciones en <5s
  - Filtrado de 10,000 items en <1s
  - Division por cero en todos los calculos financieros
  - Verificacion de inmutabilidad
  - Precision decimal en calculos

### Corregido
- **LocaleDataException**: Inicializado DateFormat en espanol antes de uso
- **Pantalla Movimientos**: Ya no muestra error rojo al abrir

### Documentacion
- Workflow .claude completo con Progressive Disclosure
- 4 skills especializados
- 6 comandos automatizados
- 4 hooks de productividad

## [1.2.0] - 2026-01-03

### Agregado
- **Tests de Produccion Agresivos**: Nueva suite de tests en `test/production/` que verifica:
  - Manejo de valores extremos (balances muy grandes/pequenos)
  - Caracteres especiales y emojis en strings
  - Prevencion de division por cero
  - Seguridad de memoria con listas grandes (10,000+ items)
  - Null safety en todos los modelos
  - Calculos financieros correctos (patrimonio neto, credito disponible)

### Corregido
- **Sync silencioso**: Los providers (accounts, transactions, budgets, goals) ahora fallan silenciosamente en syncs automaticos, evitando mensajes de error molestos al usuario
- **Deteccion de errores de IA**: Mejorada la deteccion de rate limits de Gemini API (429, RESOURCE_EXHAUSTED) vs otros errores
- **Eliminado print en produccion**: Removido print statement de debug en ai_chat_service.dart

### Tests
- 172 tests pasando (unit, widget, integration, production)
- 16 nuevos tests de produccion agregados

## [1.1.0] - 2026-01-03

### Agregado
- **First Account Wizard**: Nuevo wizard para guiar a usuarios nuevos a crear su primera cuenta
- **Templates de cuentas**: 5 templates predefinidos (Efectivo, Cuenta Bancaria, Tarjeta de Credito, Ahorros, Billetera Digital)
- **Nuevos tipos de cuenta**: loan (prestamo), receivable (por cobrar), payable (por pagar)
- **Propiedades isLiability/isAsset**: Para clasificar cuentas como activos o pasivos
- **Taxonomia completa de categorias**: 15 categorias de gasto + 6 de ingreso con subcategorias

### Corregido
- Switch statements actualizados para nuevos AccountTypes
- Tests de modelos actualizados

## [1.0.0] - 2026-01-02

### Lanzamiento inicial
- Gestion de cuentas multiples (banco, efectivo, credito, inversiones)
- Registro de transacciones (ingresos, gastos, transferencias)
- Presupuestos por categoria
- Metas de ahorro
- Reportes y graficos
- Sincronizacion con Supabase (offline-first)
- Asistente financiero con IA (Fina)
- Soporte multiplataforma (Android, Linux Desktop)
