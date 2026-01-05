# Estrategia Unificada de Testing - Finanzas Familiares AS

## Visión General

Suite completa de **500+ tests** distribuidos en **11 categorías**, cubriendo desde tests unitarios hasta escenarios E2E complejos de un mes completo.

## Arquitectura de Testing

```
test/
├── 📦 CORE (Fundamentos)
│   ├── models/                    # 5 archivos - Validación de modelos de datos
│   ├── services/                  # 1 archivo - Servicios core
│   ├── filters/                   # 1 archivo - Filtros de transacciones
│   └── providers/                 # 1 archivo - State management
│
├── 🎨 UI & WIDGETS
│   ├── widget/                    # 1 archivo - Componentes interactivos
│   ├── router/                    # 1 archivo - Navegación con go_router
│   └── initialization/            # 1 archivo - Inicialización de app
│
├── 🔄 INTEGRATION (Flujos)
│   ├── integration/               # 2 archivos - App startup + chat flow
│   ├── e2e/                       # 7 archivos - Flujos completos E2E
│   │   ├── accounts_flow_e2e_test.dart
│   │   ├── forms_validation_e2e_test.dart
│   │   ├── core_ui_e2e_test.dart
│   │   ├── navigation_e2e_test.dart
│   │   ├── providers_state_e2e_test.dart
│   │   ├── error_states_e2e_test.dart
│   │   └── transaction_flow_e2e_test.dart
│   └── novedades/                 # 5 archivos - Tests avanzados de interdependencias
│       ├── core_integration_test.dart       # Integración básica Tx→Cuenta→Presupuesto
│       ├── cross_feature_test.dart          # Interdependencias entre features
│       ├── state_transition_test.dart       # Transiciones de estado
│       ├── combinatorial_test.dart          # Combinaciones exhaustivas
│       └── complete_month_scenario_test.dart # E2E mes completo (María)
│
├── 🤖 AI CHAT (Fina)
│   ├── ai_chat/                   # 2 archivos - Servicio Gemini + widgets
│   ├── integration/chat_flow_test.dart # 20 tests - Flujo conversacional
│   └── performance/chat_performance_test.dart # 18 tests - Rendimiento IA
│
├── 🔒 SECURITY & RELIABILITY
│   ├── security/                  # 1 archivo - API security
│   ├── supabase/                  # 3 archivos - Auth + RLS + Realtime
│   └── production/                # 1 archivo - Tests agresivos (40+)
│
├── 🌐 PWA & PLATFORM
│   ├── pwa/                       # 3 archivos - Offline, service worker, bundle
│   ├── android/                   # 2 archivos - Compatibility + browser
│   └── performance/               # 1 archivo - App performance
│
└── 🛠️ HELPERS
    ├── helpers/test_helpers.dart           # Utilidades compartidas
    ├── fixtures/test_fixtures.dart         # Datos de prueba predefinidos
    └── novedades/README.md                 # Documentación completa (521 líneas)
```

## Categorías de Testing

### 1. Core Tests (Unit Tests)
**Archivos**: 8
**Tests estimados**: 80+

| Archivo | Propósito |
|---------|-----------|
| `models/transaction_model_test.dart` | Validación de modelo de transacciones |
| `models/account_model_test.dart` | Validación de modelo de cuentas |
| `models/budget_model_test.dart` | Validación de modelo de presupuestos |
| `models/chat_message_test.dart` | Validación de mensajes de chat |
| `models/transaction_validation_test.dart` | Validación de reglas de negocio |
| `services/export_service_test.dart` | Exportación de datos |
| `filters/transaction_filters_test.dart` | Filtrado de transacciones |
| `providers/auth_provider_test.dart` | Autenticación |

**Ejecutar**: `flutter test test/models/ test/services/ test/filters/ test/providers/`

### 2. Widget Tests
**Archivos**: 3
**Tests estimados**: 30+

| Archivo | Propósito |
|---------|-----------|
| `widget/interactive_widgets_test.dart` | Componentes interactivos |
| `router/app_router_test.dart` | Navegación con go_router |
| `initialization/app_init_test.dart` | Inicialización de app |

**Ejecutar**: `flutter test test/widget/ test/router/ test/initialization/`

### 3. Integration Tests
**Archivos**: 2
**Tests estimados**: 40+

| Archivo | Propósito |
|---------|-----------|
| `integration/app_startup_test.dart` | Startup de aplicación |
| `integration/chat_flow_test.dart` | Flujo conversacional con IA |

**Ejecutar**: `flutter test test/integration/`

### 4. E2E Tests (End-to-End)
**Archivos**: 7
**Tests estimados**: 80+

| Archivo | Propósito |
|---------|-----------|
| `e2e/accounts_flow_e2e_test.dart` | Flujo completo de cuentas |
| `e2e/forms_validation_e2e_test.dart` | Validación de formularios |
| `e2e/core_ui_e2e_test.dart` | UI core |
| `e2e/navigation_e2e_test.dart` | Navegación completa |
| `e2e/providers_state_e2e_test.dart` | Estado de providers |
| `e2e/error_states_e2e_test.dart` | Manejo de errores |
| `e2e/transaction_flow_e2e_test.dart` | Flujo de transacciones |

**Ejecutar**: `flutter test test/e2e/`

### 5. **NUEVO** - Tests Avanzados de Interdependencias
**Archivos**: 5
**Tests estimados**: 150+

#### 5.1 Core Integration (`novedades/core_integration_test.dart`)
Tests de integración básica entre features principales:
- ✅ Transacción → Cuenta
- ✅ Transacción → Presupuesto
- ✅ Transacción → Meta
- ✅ Cuenta → Transacción → Reporte
- ✅ Flujos End-to-End básicos

#### 5.2 Cross-Feature Tests (`novedades/cross_feature_test.dart`)
**60+ tests** de interdependencias específicas:
- Cuenta × Transacción × Reporte
- Transacción × Presupuesto × Alerta
- Cuenta × Meta × Notificación
- Presupuesto × Categoría × Reporte
- Usuario × Configuración × Alertas
- Transacción × Recurrencia × Calendario
- Múltiples features simultáneas
- Dependencias bidireccionales
- Cascadas de eliminación
- Consistencia de datos

#### 5.3 State Transition Tests (`novedades/state_transition_test.dart`)
**40+ tests** de transiciones de estado:
- Estados de Meta: nueva → en_progreso → completada
- Estados de Presupuesto: normal → cerca_limite → excedido
- Estados de Transacción: pendiente → procesada → completada
- Estados de Cuenta: activa → inactiva → archivada
- Estados de Alerta: nueva → leida → resuelta → archivada
- Estados de Notificación: pendiente → enviada → leida
- Validaciones de transiciones inválidas
- Diagrama de estados documentado

#### 5.4 Combinatorial Tests (`novedades/combinatorial_test.dart`)
**80+ tests** de combinaciones exhaustivas:
- Presupuesto × Alerta × Notificación (36 combinaciones)
- Tipo Transacción × Categoría × Cuenta
- Usuario × Configuración × Features (27 combinaciones)
- Fechas × Recurrencia × Ejecución (80 combinaciones)
- Matriz de compatibilidad entre features

#### 5.5 Complete Month Scenario (`novedades/complete_month_scenario_test.dart`)
**1 test épico** - Simula uso completo durante un mes:
- Usuario: María González
- 4 semanas de actividad
- 50+ transacciones
- 4 cuentas, 4 presupuestos, 2 metas
- Alertas, notificaciones, reportes
- Verificación de integridad completa
- Análisis financiero detallado

**Ejecutar**: `flutter test test/novedades/`

### 6. AI Chat Tests (Fina)
**Archivos**: 4
**Tests estimados**: 80+

| Archivo | Propósito |
|---------|-----------|
| `ai_chat/ai_chat_service_test.dart` | Servicio Gemini 2.0 Flash |
| `ai_chat/chat_widget_test.dart` | Widgets de chat |
| `integration/chat_flow_test.dart` | Flujo conversacional |
| `performance/chat_performance_test.dart` | Rendimiento IA |

**Ejecutar**: `flutter test test/ai_chat/ test/integration/chat_flow_test.dart test/performance/chat_performance_test.dart`

### 7. Security Tests
**Archivos**: 2
**Tests estimados**: 40+

| Archivo | Propósito |
|---------|-----------|
| `security/api_security_test.dart` | Seguridad de API |
| `supabase/security_rls_test.dart` | Row Level Security |

**Ejecutar**: `flutter test test/security/ test/supabase/security_rls_test.dart`

### 8. PWA & Offline Tests
**Archivos**: 3
**Tests estimados**: 50+

| Archivo | Propósito |
|---------|-----------|
| `pwa/offline_sync_test.dart` | Sync offline-first |
| `pwa/service_worker_test.dart` | Service worker |
| `pwa/bundle_optimization_test.dart` | Optimización de bundle |

**Ejecutar**: `flutter test test/pwa/`

### 9. Platform Tests
**Archivos**: 2
**Tests estimados**: 30+

| Archivo | Propósito |
|---------|-----------|
| `android/compatibility_test.dart` | Compatibilidad Android |
| `android/browser_compatibility_test.dart` | Compatibilidad de navegadores |

**Ejecutar**: `flutter test test/android/`

### 10. Performance Tests
**Archivos**: 2
**Tests estimados**: 30+

| Archivo | Propósito |
|---------|-----------|
| `performance/app_performance_test.dart` | Rendimiento general |
| `performance/chat_performance_test.dart` | Rendimiento IA |

**Ejecutar**: `flutter test test/performance/`

### 11. Supabase Tests
**Archivos**: 3
**Tests estimados**: 40+

| Archivo | Propósito |
|---------|-----------|
| `supabase/auth_test.dart` | Autenticación |
| `supabase/security_rls_test.dart` | Row Level Security |
| `supabase/realtime_test.dart` | Realtime subscriptions |

**Ejecutar**: `flutter test test/supabase/`

### 12. Production Tests
**Archivos**: 1
**Tests estimados**: 40+

| Archivo | Propósito |
|---------|-----------|
| `production/production_readiness_test.dart` | Tests agresivos de producción |

**Ejecutar**: `flutter test test/production/`

## Comandos de Testing

### Ejecutar por Categoría

```bash
# Core (Unit tests)
flutter test test/models/ test/services/ test/filters/ test/providers/

# Widgets
flutter test test/widget/ test/router/ test/initialization/

# Integration
flutter test test/integration/

# E2E
flutter test test/e2e/

# Interdependencias (NUEVO)
flutter test test/novedades/

# AI Chat
flutter test test/ai_chat/ test/integration/chat_flow_test.dart test/performance/chat_performance_test.dart

# Security
flutter test test/security/ test/supabase/security_rls_test.dart

# PWA
flutter test test/pwa/

# Platform
flutter test test/android/

# Performance
flutter test test/performance/

# Supabase
flutter test test/supabase/

# Production
flutter test test/production/

# TODO (40 tests rápidos)
flutter test test/models/ test/widget/

# Todos los tests
flutter test
```

### Ejecutar con Coverage

```bash
# Generar coverage
flutter test --coverage

# Ver reporte HTML
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html  # macOS
xdg-open coverage/html/index.html  # Linux
```

## Helpers y Fixtures

### Test Helpers (`test/helpers/test_helpers.dart`)
- `createTestDatabase()` - BD en memoria
- `setupFullTestEnvironment()` - Entorno completo
- `TestMainScaffold` - Scaffold simplificado

### Test Fixtures (`test/novedades/fixtures/test_fixtures.dart`)
- `usuarioBasico()` - Usuario de prueba
- `cuentasBasicas()` - Cuentas predefinidas
- `categoriasGastos()` - Categorías de gasto
- `escenarioConfiguracionBasica()` - Escenario completo

## Mejores Prácticas

### 1. Nomenclatura Clara
```dart
// ✅ BIEN
test('Gasto mayor al saldo lanza SaldoInsuficienteException', () {});

// ❌ MAL
test('test1', () {});
```

### 2. Arrange-Act-Assert
```dart
test('descripción', () async {
  // Arrange: Preparar datos
  final cuenta = await crearCuenta();

  // Act: Ejecutar acción
  await registrarGasto(cuenta.id, 100000);

  // Assert: Verificar resultado
  expect(cuenta.saldo, lessThan(saldoInicial));
});
```

### 3. Tests Independientes
Cada test debe poder ejecutarse solo, sin depender de otros.

### 4. Limpiar Después
```dart
tearDown(() async {
  await db.limpiar();
  await cacheService.limpiar();
});
```

### 5. Usar Fixtures
```dart
final usuario = TestFixtures.usuarioBasico();
final cuentas = TestFixtures.cuentasBasicas();
```

## Métricas de Calidad

### Objetivo de Cobertura por Módulo

| Módulo | Objetivo | Prioridad |
|--------|----------|-----------|
| Transacciones | 95% | 🔴 Alta |
| Cuentas | 95% | 🔴 Alta |
| Presupuestos | 90% | 🔴 Alta |
| Metas | 90% | 🟡 Media |
| Reportes | 85% | 🟡 Media |
| AI Chat (Fina) | 85% | 🟡 Media |
| Notificaciones | 80% | 🟢 Baja |
| UI | 70% | 🟢 Baja |

### Checklist de Cobertura

- [ ] Todas las funciones públicas tienen test
- [ ] Todos los casos edge tienen test
- [ ] Todos los flujos críticos tienen E2E test
- [ ] Todas las interdependencias tienen cross-feature test
- [ ] Todas las transiciones de estado están cubiertas
- [ ] Todas las combinaciones críticas están probadas
- [ ] Tests de test/novedades activados (actualmente con TODOs)

## Estado Actual

### Tests Activos
- ✅ Core: 80+ tests pasando
- ✅ Widget: 30+ tests pasando
- ✅ Integration: 40+ tests pasando
- ✅ E2E: 80+ tests (algunos fallan por timing)
- ✅ AI Chat: 80+ tests pasando
- ✅ Security: 40+ tests pasando
- ✅ PWA: 50+ tests pasando
- ✅ Platform: 30+ tests pasando
- ✅ Performance: 30+ tests pasando
- ✅ Supabase: 40+ tests pasando
- ✅ Production: 40+ tests pasando

### Tests Pendientes de Activación (test/novedades/)
- ⏳ Core Integration: 30+ tests (con TODOs)
- ⏳ Cross-Feature: 60+ tests (con TODOs)
- ⏳ State Transition: 40+ tests (con TODOs)
- ⏳ Combinatorial: 80+ tests (con TODOs)
- ⏳ Complete Month: 1 test épico (con TODOs)

**Total Actual**: ~500+ tests (300+ activos, 200+ pendientes)

## Próximos Pasos

1. **Activar tests de test/novedades/** - Reemplazar TODOs con implementación real
2. **Alcanzar 90% de cobertura** en módulos críticos
3. **Integrar en CI/CD** para ejecución automática
4. **Optimizar tiempos de ejecución** para tests E2E
5. **Agregar tests de accesibilidad** (a11y)
6. **Tests de internacionalización** (i18n)

## Recursos

- [Flutter Testing Guide](https://docs.flutter.dev/testing)
- [Mockito Documentation](https://pub.dev/packages/mockito)
- [Test-Driven Development](https://www.amazon.com/Test-Driven-Development-Kent-Beck/dp/0321146530)
- [test/novedades/README.md](../../test/novedades/README.md) - Documentación completa (521 líneas)
- `.claude/skills/testing/TESTING_STRATEGY.md` - Estrategia general
- `.claude/skills/testing/PWA_OFFLINE_TESTS.md` - Tests PWA
- `.claude/skills/testing/SUPABASE_AUTH_TESTS.md` - Tests auth
- `.claude/skills/testing/SECURITY_RLS_TESTS.md` - Tests seguridad

---

**Última actualización**: 2026-01-04
**Versión**: 2.0.0
**Mantenedor**: Equipo Finanzas Familiares AS
