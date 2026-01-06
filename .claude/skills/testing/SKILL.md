---
name: testing
description: Suite completa de 500+ tests. Incluye unit, widget, integration, E2E, interdependencias, AI Chat, seguridad, performance, PWA/offline, Android y produccion. Usar para crear, ejecutar, o mejorar tests.
---

# Testing

Skill de testing unificado para Finanzas Familiares - **500+ tests** en **11 categorías**.

## 🎯 Quick Start

```bash
# Todos los tests (500+)
flutter test

# Tests rápidos (unit + widget - ~110 tests)
flutter test test/models/ test/widget/

# Tests de interdependencias (NUEVO - ~210 tests)
flutter test test/novedades/

# Con coverage
flutter test --coverage && genhtml coverage/lcov.info -o coverage/html
```

## 📊 Categorías de Tests

| Categoría | Tests | Estado |
|-----------|-------|--------|
| Core (Unit) | 80+ | ✅ Activos |
| Widget | 30+ | ✅ Activos |
| Integration | 40+ | ✅ Activos |
| E2E | 80+ | ✅ Activos |
| **Interdependencias** | **210+** | ⏳ **Pendientes** |
| AI Chat (Fina) | 80+ | ✅ Activos |
| Security | 40+ | ✅ Activos |
| PWA/Offline | 50+ | ✅ Activos |
| Platform (Android) | 30+ | ✅ Activos |
| Performance | 30+ | ✅ Activos |
| Supabase | 40+ | ✅ Activos |
| Production | 40+ | ✅ Activos |
| **TOTAL** | **500+** | **300+ activos** |

## 🆕 Tests Avanzados de Interdependencias

**Nuevos en test/novedades/** - ~210 tests distribuidos en 5 archivos:

### 1. Core Integration (`core_integration_test.dart`)
Tests básicos de integración entre features:
- Transacción → Cuenta
- Transacción → Presupuesto
- Transacción → Meta
- Flujos End-to-End básicos

### 2. Cross-Feature Tests (`cross_feature_test.dart`)
**60+ tests** de interdependencias específicas:
- Cuenta × Transacción × Reporte
- Transacción × Presupuesto × Alerta
- Dependencias bidireccionales
- Cascadas de eliminación

### 3. State Transition Tests (`state_transition_test.dart`)
**40+ tests** de transiciones de estado:
- Meta: nueva → en_progreso → completada
- Presupuesto: normal → cerca_limite → excedido
- Transacción: pendiente → procesada → completada
- Validaciones de transiciones inválidas

### 4. Combinatorial Tests (`combinatorial_test.dart`)
**80+ tests** de combinaciones exhaustivas:
- Presupuesto × Alerta × Notificación (36 combinaciones)
- Usuario × Configuración × Features (27 combinaciones)
- Fechas × Recurrencia × Ejecución (80 combinaciones)

### 5. Complete Month Scenario (`complete_month_scenario_test.dart`)
**1 test épico** - Simula uso completo durante un mes entero:
- Usuario real (María González)
- 4 semanas de actividad
- 50+ transacciones
- Verificación de integridad completa

## 📁 Estructura Completa

Ver [UNIFIED_TESTING_STRATEGY.md](UNIFIED_TESTING_STRATEGY.md) para arquitectura detallada.

## 🚀 Comandos por Categoría

```bash
# Core (Unit tests)
flutter test test/models/ test/services/ test/filters/ test/providers/

# Widgets
flutter test test/widget/ test/router/ test/initialization/

# Integration + E2E
flutter test test/integration/ test/e2e/

# Interdependencias (NUEVO)
flutter test test/novedades/

# AI Chat
flutter test test/ai_chat/

# Security + Supabase
flutter test test/security/ test/supabase/

# PWA + Platform
flutter test test/pwa/ test/android/

# Performance + Production
flutter test test/performance/ test/production/
```

## 📚 Documentación Completa

- **[TEST_SETUP_GUIDE.md](TEST_SETUP_GUIDE.md)** - ⭐ **LEER PRIMERO** - Setup estandarizado
- **[UNIFIED_TESTING_STRATEGY.md](UNIFIED_TESTING_STRATEGY.md)** - Estrategia unificada completa
- [TESTING_STRATEGY.md](TESTING_STRATEGY.md) - Estrategia general
- [PWA_OFFLINE_TESTS.md](PWA_OFFLINE_TESTS.md) - Tests offline-first
- [SUPABASE_AUTH_TESTS.md](SUPABASE_AUTH_TESTS.md) - Tests de autenticación
- [SECURITY_RLS_TESTS.md](SECURITY_RLS_TESTS.md) - Tests de seguridad RLS
- [PRODUCTION_TESTS.md](PRODUCTION_TESTS.md) - Tests agresivos de producción
- [../../test/novedades/README.md](../../test/novedades/README.md) - Guía de interdependencias (521 líneas)

## Ejemplo Rapido: Test Unitario

```dart
test('AccountModel maneja valores extremos', () {
  final account = AccountModel.create(
    userId: 'test',
    name: 'Large',
    type: AccountType.bank,
    currency: 'MXN',
    balance: 999999999999.99,
  );
  expect(account.balance, 999999999999.99);
});
```

## Ejemplo Rapido: Test de Widget

```dart
testWidgets('AccountCard muestra balance', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: AccountCard(account: testAccount),
    ),
  );

  expect(find.text('\$1,000.00'), findsOneWidget);
});
```
