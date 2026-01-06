# Test Setup Guide

Guia estandarizada para configurar tests en Finanzas Familiares.

## Arquitectura de Test Setup

```
test/
├── flutter_test_config.dart  # Configuracion GLOBAL (auto-ejecutada)
├── helpers/
│   └── test_helpers.dart     # Setup functions idempotentes
├── mocks/
│   └── mock_providers.dart   # Provider overrides para Riverpod
└── [categorias]/             # Tests por categoria
```

## 1. Configuracion Global (`flutter_test_config.dart`)

Este archivo es **auto-ejecutado por Flutter** antes de CUALQUIER test.

```dart
/// Configuración global de tests para Finanzas Familiares
library;

import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:finanzas_familiares/core/network/supabase_client.dart';
import 'package:finanzas_familiares/core/database/app_database.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  // 1. Inicializar binding de tests
  TestWidgetsFlutterBinding.ensureInitialized();

  // 2. Inicializar locale para DateFormat
  await initializeDateFormatting('es', null);

  // 3. Habilitar modo test de Supabase (CRITICO)
  SupabaseClientProvider.enableTestMode();

  // 4. Reset singleton de database
  AppDatabase.resetInstance();

  // 5. Ejecutar tests
  await testMain();

  // 6. Cleanup
  SupabaseClientProvider.reset();
}
```

**Importante**: Este archivo GARANTIZA que `SupabaseClientProvider.enableTestMode()` se ejecuta antes de cualquier test.

## 2. Setup Functions Idempotentes (`test_helpers.dart`)

Las funciones de setup son **idempotentes** - se pueden llamar multiples veces sin efectos adversos.

```dart
/// Flag global para saber si el ambiente ya fue configurado
bool _isTestEnvironmentReady = false;

/// Setup para tests que necesitan providers mockeados
Future<void> setupTestEnvironment() async {
  if (_isTestEnvironmentReady) return; // Idempotente

  TestWidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es', null);
  SupabaseClientProvider.enableTestMode();

  // Configurar usuario mock
  mockSupabase.auth.setMockUser(MockSupabaseUser(
    id: 'test-user-123',
    email: 'test@finanzasfamiliares.com',
  ));

  _isTestEnvironmentReady = true;
}

/// Setup para tests con database (E2E, Integration, Performance)
Future<void> setupFullTestEnvironment() async {
  await setupTestEnvironment();
  AppDatabase.resetInstance();
}

/// Teardown (reset mocks pero mantiene test mode activo)
Future<void> tearDownTestEnvironment() async {
  mockSupabase.reset();
  mockSupabase.auth.setMockUser(MockSupabaseUser(
    id: 'test-user-123',
    email: 'test@finanzasfamiliares.com',
  ));
}
```

## 3. Patron Correcto para Tests

### Tests E2E/Widget con Providers

```dart
void main() {
  // CORRECTO: async + await
  setUpAll(() async {
    await setupTestEnvironment();
  });

  tearDownAll(() async {
    await tearDownTestEnvironment();
  });

  testWidgets('Mi test', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: testProviderOverrides, // De mock_providers.dart
        child: MaterialApp(home: MyWidget()),
      ),
    );
    // ...
  });
}
```

### Tests de Performance con Database In-Memory

```dart
void main() {
  late AppDatabase testDb;
  late AccountRepository accountRepo;

  setUpAll(() async {
    await setupFullTestEnvironment();
  });

  setUp(() {
    // Nueva DB in-memory para CADA test (aislamiento)
    testDb = createTestDatabase();
    accountRepo = AccountRepository(database: testDb);
  });

  tearDown(() async {
    await testDb.close();
  });

  test('Performance test', () async {
    // Usar testDb, accountRepo...
  });
}
```

### Tests Unitarios Simples

```dart
void main() {
  // Para tests unitarios puros, no se necesita setup especial
  test('AccountModel calcula balance', () {
    final account = AccountModel(...);
    expect(account.balance, 100.0);
  });
}
```

## 4. Errores Comunes y Soluciones

### Error: "Test mode: Use mock providers..."

**Causa**: Supabase no esta en modo test cuando se ejecuta el test.

**Solucion**:
1. Verificar que `test/flutter_test_config.dart` existe
2. Verificar que `setUpAll` usa `async/await`:

```dart
// INCORRECTO - NO espera el Future
setUpAll(() => setupTestEnvironment());

// CORRECTO - Espera el Future
setUpAll(() async {
  await setupTestEnvironment();
});
```

### Error: "Requiere base de datos configurada"

**Causa**: Test marcado con `skip` innecesariamente.

**Solucion**: Usar database in-memory:

```dart
setUp(() {
  testDb = createTestDatabase(); // In-memory, no requiere Supabase
});
```

### Error: "LocaleDataException"

**Causa**: `DateFormat` usado antes de inicializar locale.

**Solucion**: `flutter_test_config.dart` ya maneja esto globalmente con:
```dart
await initializeDateFormatting('es', null);
```

### Error: Tests interfiriendo entre si

**Causa**: Estado compartido entre tests.

**Solucion**:
1. Crear nueva database en `setUp()` (no `setUpAll`)
2. Cerrar database en `tearDown()`
3. Usar `late` para variables que se reinician

## 5. Provider Overrides (`mock_providers.dart`)

### Providers Disponibles para Mock

```dart
/// Overrides completos para tests E2E y Widget
final testProviderOverrides = [
  // Cuentas
  activeAccountsProvider.overrideWith((ref) => mockAccounts),

  // Categorías (derivados de transactionsProvider)
  categoriesProvider.overrideWith((ref) => mockAllCategories),
  expenseCategoriesProvider.overrideWith((ref) => mockExpenseCategories),
  incomeCategoriesProvider.overrideWith((ref) => mockIncomeCategories),

  // Establecimientos y Unidades (evitan acceso a DB)
  establishmentsProvider.overrideWith(() => MockEstablishments()),
  unitsProvider.overrideWith(() => MockUnits()),
  unitsGroupedProvider.overrideWith((ref) => mockUnitsGrouped),
  unitsListProvider.overrideWith((ref) => mockUnitsWithData),
];

/// Overrides para estado vacio (testing empty states)
final emptyStateProviderOverrides = [
  activeAccountsProvider.overrideWith((ref) => <AccountModel>[]),
  // Categorías se mantienen para que funcione UI
  categoriesProvider.overrideWith((ref) => mockAllCategories),
  // ... similar pero con listas vacías
];
```

### Limitaciones Conocidas

**StateNotifierProvider (como `transactionsProvider`)**:
- No se puede mockear directamente sin crear repositorios mock
- Solución: Override solo los providers derivados (categorías)
- Los tests que necesitan manipular transacciones deben usar database in-memory

```dart
// INCORRECTO - Requiere que MockTransactionsNotifier extienda TransactionsNotifier
transactionsProvider.overrideWith((ref) => MockTransactionsNotifier()), // Error

// CORRECTO - Override de providers derivados
categoriesProvider.overrideWith((ref) => mockAllCategories),
expenseCategoriesProvider.overrideWith((ref) => mockExpenseCategories),
```

## 6. Checklist para Nuevos Tests

- [ ] Usar `setUpAll(() async { await setupTestEnvironment(); })`
- [ ] Usar `testProviderOverrides` para widget tests
- [ ] Crear DB in-memory en `setUp()` para tests de data
- [ ] Cerrar DB en `tearDown()`
- [ ] NO usar `skip:` para tests que pueden usar in-memory DB
- [ ] NO acceder a Supabase real - usar mocks

## 7. Estructura de Archivos Clave

| Archivo | Proposito |
|---------|-----------|
| `test/flutter_test_config.dart` | Config global auto-ejecutada |
| `test/helpers/test_helpers.dart` | Funciones de setup idempotentes |
| `test/mocks/mock_providers.dart` | Provider overrides para Riverpod |
| `test/mocks/mock_supabase.dart` | Mock de cliente Supabase |

## 8. Mensajes Esperados (No Son Errores)

Durante la ejecucion de tests, estos mensajes son **normales**:

```
Test mode: Use mock providers for widget tests
Supabase test mode enabled - using mocks
```

Esto indica que el sistema de mocks esta funcionando correctamente.

## 9. Supresión de Warnings en Modo Test

Para evitar ruido en la salida de tests, los repositorios suprimen warnings cuando
están en modo test.

### Implementación en Repositorios

```dart
// En auth_repository.dart y otros repositorios
User? get currentUser {
  try {
    return _auth.currentUser;
  } catch (e) {
    // Solo imprimir en modo no-test
    if (!SupabaseClientProvider.isTestMode) {
      debugPrint('Warning: Could not get current user: $e');
    }
    return null;
  }
}
```

### Verificar Modo Test

```dart
// SupabaseClientProvider expone el estado de test
static bool get isTestMode => _isTestMode;

// Usar en repositorios para suprimir logs innecesarios
if (!SupabaseClientProvider.isTestMode) {
  debugPrint('Este mensaje solo aparece en producción');
}
```

## 10. Tests Skipped (Requieren Refactorización)

Algunos tests están marcados como `skip` porque requieren refactorización mayor:

| Test | Razón | Solución |
|------|-------|----------|
| `AiChatService` tests | Requiere `Ref` de Riverpod | Usar `ProviderContainer` |
| API integration tests | Requieren Supabase real | Marcar como integration-only |

Para refactorizar tests que necesitan `Ref`:

```dart
// ANTES (no funciona en tests)
final service = AiChatService(ref);

// DESPUÉS (funciona en tests)
final container = ProviderContainer(
  overrides: testProviderOverrides,
);
addTearDown(container.dispose);
final ref = container; // ProviderContainer implementa Ref
final service = AiChatService(ref);
```
