# Test Suite - Finanzas Familiares AS

[![Tests](https://img.shields.io/badge/tests-580%20passing-brightgreen)]()
[![Coverage](https://img.shields.io/badge/coverage-pending-yellow)]()

## 📊 Estado Actual

| Métrica | Valor |
|---------|-------|
| Tests pasando | 580 |
| Tests saltados | 21 (requieren Supabase real) |
| Tests fallando | 0 |

---

## 📁 Estructura de Carpetas

```
test/
├── ai_chat/          # Tests del asistente de IA (Fina)
├── android/          # Tests específicos de Android
├── e2e/              # Tests End-to-End (flujos completos)
├── filters/          # Tests de filtros de transacciones
├── fixtures/         # Datos de prueba reutilizables
├── helpers/          # Utilidades y setup de tests
├── initialization/   # Tests de inicialización de la app
├── integration/      # Tests de integración con servicios
├── mocks/            # Mock objects y providers
├── models/           # Tests de modelos de dominio
├── novedades/        # Tests de nuevas funcionalidades
├── performance/      # Tests de rendimiento
├── production/       # Tests de readiness para producción
├── providers/        # Tests de Riverpod providers
├── pwa/              # Tests específicos de PWA/Offline
├── router/           # Tests de navegación (go_router)
├── security/         # Tests de seguridad (XSS, SQLi, etc.)
├── services/         # Tests de servicios
├── supabase/         # Tests de integración con Supabase
└── widget/           # Tests de widgets individuales
```

---

## 🧪 Categorías de Tests

### 1. Unit Tests (`test/models/`, `test/services/`)

Tests de lógica de negocio pura sin dependencias de UI.

```bash
flutter test test/models/ test/services/
```

**Cobertura:**
- `AccountModel`: Validación, serialización, tipos de cuenta
- `TransactionModel`: Cálculos, categorías, validaciones
- `BudgetModel`: Límites, porcentajes, alertas
- `GoalModel`: Progreso, fechas objetivo, contribuciones

### 2. Widget Tests (`test/widget/`)

Tests de componentes UI individuales.

```bash
flutter test test/widget/
```

**Cobertura:**
- Formularios (AddAccountSheet, AddTransactionSheet)
- Cards y listas
- Gráficos (fl_chart)
- Navegación y AppBar

### 3. Integration Tests (`test/integration/`)

Tests de flujos que involucran múltiples componentes.

```bash
flutter test test/integration/
```

**Cobertura:**
- Flujo de autenticación
- CRUD completo de entidades
- Sincronización local-remota

### 4. E2E Tests (`test/e2e/`)

Tests End-to-End que simulan interacciones de usuario reales.

```bash
flutter test test/e2e/
```

**Archivos principales:**
| Archivo | Descripción |
|---------|-------------|
| `accounts_flow_e2e_test.dart` | Flujo completo de cuentas |
| `transaction_flow_e2e_test.dart` | Flujo completo de transacciones |
| `providers_state_e2e_test.dart` | Estado de providers entre pantallas |
| `error_states_e2e_test.dart` | Manejo de errores y edge cases |

### 5. PWA/Offline Tests (`test/pwa/`)

Tests específicos para comportamiento offline-first.

```bash
flutter test test/pwa/
```

**Cobertura:**
- Operaciones CRUD sin conexión
- Flag `isSynced` correctamente manejado
- Datos persisten entre sesiones
- Sync no falla cuando está offline

### 6. Supabase Tests (`test/supabase/`)

Tests de integración con Supabase.

```bash
flutter test test/supabase/
```

**Archivos:**
| Archivo | Descripción |
|---------|-------------|
| `auth_test.dart` | Autenticación y validaciones |
| `security_rls_test.dart` | Row Level Security |
| `realtime_test.dart` | Suscripciones en tiempo real |

### 7. Security Tests (`test/security/`)

Tests de seguridad contra vulnerabilidades comunes.

```bash
flutter test test/security/
```

**Cobertura:**
- SQL Injection prevention
- XSS (Cross-Site Scripting)
- Path Traversal
- Command Injection
- API Key protection
- Input validation

### 8. Performance Tests (`test/performance/`)

Tests de rendimiento y memoria.

```bash
flutter test test/performance/
```

**Métricas verificadas:**
- Crear cuenta < 100ms
- Leer por ID < 50ms
- Query transacciones < 200ms
- 100 inserts < 2s
- Sin memory leaks en 1000 operaciones

### 9. Production Tests (`test/production/`)

Tests agresivos de robustez para producción.

```bash
flutter test test/production/
```

**Cobertura:**
- Balances astronómicos (trillones) sin overflow
- Strings de 10,000+ caracteres
- Fechas edge case (1900, 2099, Feb 29)
- Stress test: 10,000 transacciones
- División por cero
- Null safety

### 10. Android Tests (`test/android/`)

Tests de compatibilidad con dispositivos Android.

```bash
flutter test test/android/
```

**Cobertura:**
- Pantallas: HD, FHD, Tablet
- Orientaciones: Portrait, Landscape
- Font scaling: 0.85x a 1.3x
- Temas: Light y Dark

---

## 🚀 Comandos Rápidos

### Ejecutar todos los tests
```bash
flutter test
```

### Tests rápidos (unit + widget)
```bash
flutter test test/models/ test/widget/ test/services/
```

### Tests por categoría
```bash
# E2E
flutter test test/e2e/

# Seguridad
flutter test test/security/

# PWA/Offline
flutter test test/pwa/

# Supabase
flutter test test/supabase/

# Performance
flutter test test/performance/
```

### Tests con coverage
```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

### Tests en modo verbose
```bash
flutter test --reporter expanded
```

---

## 🔧 Setup de Tests

### Configuración inicial

Todos los tests usan el helper centralizado:

```dart
import '../helpers/test_helpers.dart';
import '../mocks/mock_providers.dart';

void main() {
  setUpAll(() => setupTestEnvironment());
  tearDownAll(() => tearDownTestEnvironment());

  // Tests aquí...
}
```

### Mock Providers

```dart
// Para tests con datos mock
ProviderScope(
  overrides: testProviderOverrides,
  child: MaterialApp(...),
)

// Para tests de estado vacío
ProviderScope(
  overrides: emptyStateProviderOverrides,
  child: MaterialApp(...),
)
```

### Test Mode de Supabase

```dart
setUpAll(() {
  SupabaseClientProvider.enableTestMode();
});

tearDownAll(() {
  SupabaseClientProvider.reset();
});
```

---

## 📋 Convenciones

### Nomenclatura de archivos
- `*_test.dart` - Archivo de test estándar
- `*_e2e_test.dart` - Test End-to-End
- `mock_*.dart` - Mock objects

### Estructura de tests

```dart
group('Categoría: Subcategoría', () {
  // =========================================================================
  // TEST N: Descripción clara del test
  // =========================================================================
  test('Descripción en español', () {
    // Arrange
    // Act
    // Assert
  });
});
```

### Nombres de tests
- En español para consistencia con el proyecto
- Descriptivos y específicos
- Formato: `Acción debe resultado esperado`

---

## ⚠️ Tests Saltados (Skipped)

21 tests están marcados como `skip` porque requieren:
- Conexión real a Supabase
- Credenciales de producción
- Sesión de usuario activa

Estos tests se ejecutan manualmente en entornos de staging/producción.

---

## 🐛 Debugging de Tests

### Ver output detallado
```bash
flutter test --reporter expanded test/path/to/test.dart
```

### Ejecutar un solo test
```bash
flutter test --name "nombre del test" test/path/to/test.dart
```

### Filtrar por grupo
```bash
flutter test --name "E2E:" test/e2e/
```

### Debug con prints
Los warnings de Supabase en test mode son esperados:
```
Error accessing Supabase auth: Exception: Test mode: Use mock providers...
```

---

## 📈 Historial de Métricas

| Fecha | Pasando | Saltados | Fallando |
|-------|---------|----------|----------|
| 2026-01-05 | 580 | 21 | 0 |
| 2026-01-04 | 573 | 21 | 7 |
| 2026-01-03 | 500+ | 21 | 0 |

---

## 🔗 Referencias

- [Flutter Testing](https://docs.flutter.dev/testing)
- [Riverpod Testing](https://riverpod.dev/docs/essentials/testing)
- [Widget Testing](https://docs.flutter.dev/cookbook/testing/widget/introduction)
- [CLAUDE.md](../CLAUDE.md) - Documentación principal del proyecto
- [Testing Strategy](../.claude/skills/testing/TESTING_STRATEGY.md) - Estrategia detallada
