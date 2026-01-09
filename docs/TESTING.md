# Testing Strategy

## Resumen

| Métrica | Valor |
|---------|-------|
| Total de Tests | 363+ |
| Archivos de Test | 32 |
| Cobertura Objetivo | 80%+ |
| Framework | flutter_test + mocktail |

## Categorías de Tests

### 1. Tests Unitarios (`test/unit/`)

Tests de lógica de negocio pura, sin dependencias de Flutter.

| Archivo | Tests | Descripción |
|---------|-------|-------------|
| `entities_test.dart` | 30 | Modelos de dominio (Category, Account, Transaction, Budget, NetWorthSummary, etc.) |
| `accounting_service_test.dart` | 12 | Motor de partida doble (débitos, créditos, balance) |
| `financial_indicators_test.dart` | 10 | Indicadores financieros (cobertura deuda, liquidez, etc.) |
| `sync_status_provider_test.dart` | 16 | Estado de sincronización (online/offline/syncing) |

### 2. Tests de Datos (`test/data/`)

Tests de DAOs y acceso a base de datos.

| Archivo | Tests | Descripción |
|---------|-------|-------------|
| `recurring_transactions_dao_test.dart` | 12 | CRUD de transacciones recurrentes |
| `accounting_integration_test.dart` | 8 | Integración contable end-to-end |
| `accounting_integrity_test.dart` | 6 | Integridad de partida doble |

### 3. Tests de Servicios (`test/unit/`)

Tests de servicios de aplicación.

| Archivo | Tests | Descripción |
|---------|-------|-------------|
| `export_service_test.dart` | 15 | Exportación CSV/Excel/PDF |
| `import_service_test.dart` | 12 | Importación desde templates |
| `template_generator_test.dart` | 8 | Generación de plantillas Excel |
| `backup_service_test.dart` | 10 | Backup local SQLite |
| `restore_service_test.dart` | 8 | Restauración de backups |
| `auto_backup_service_test.dart` | 12 | Backup automático programado |
| `full_backup_flow_test.dart` | 5 | Flujo completo backup-restore |

### 4. Tests de Providers (`test/unit/`)

Tests de providers Riverpod.

| Archivo | Tests | Descripción |
|---------|-------|-------------|
| `dashboard_provider_test.dart` | 8 | Provider de dashboard (totales, indicadores) |
| `backup_provider_test.dart` | 10 | Provider de backup/restore |
| `onboarding_provider_test.dart` | 7 | Estado de onboarding |

### 5. Tests de Seeders (`test/unit/`)

Tests de datos iniciales.

| Archivo | Tests | Descripción |
|---------|-------|-------------|
| `category_seeder_test.dart` | 8 | Taxonomía de categorías |
| `measurement_units_seeder_test.dart` | 5 | Unidades de medida |
| `places_seeder_test.dart` | 5 | Lugares predefinidos |

### 6. Tests de Widgets (`test/presentation/`)

Tests de UI con WidgetTester.

| Archivo | Tests | Descripción |
|---------|-------|-------------|
| `dashboard_screen_test.dart` | 15 | Pantalla principal, indicadores |
| `accounts_screen_test.dart` | 12 | Lista y gestión de cuentas |
| `transactions_screen_test.dart` | 10 | Lista y filtros de transacciones |
| `budgets_screen_test.dart` | 8 | Presupuestos y semáforos |
| `categories_screen_test.dart` | 6 | Gestión de categorías |
| `recurring_transactions_screen_test.dart` | 10 | Pagos recurrentes |
| `onboarding_screen_test.dart` | 11 | Pantallas de bienvenida |
| `main_shell_test.dart` | 12 | Navegación principal |

### 7. Tests de Formularios (`test/presentation/`)

| Archivo | Tests | Descripción |
|---------|-------|-------------|
| `account_form_screen_test.dart` | 25 | Formulario de cuentas (validaciones, iconos, colores) |
| `transaction_form_screen_test.dart` | 12 | Formulario de transacciones |
| `category_form_screen_test.dart` | 10 | Formulario de categorías |

### 8. Tests de Widgets Comunes

| Archivo | Tests | Descripción |
|---------|-------|-------------|
| `traffic_light_widget_test.dart` | 6 | Indicador semáforo de presupuesto |

## Patrones de Testing

### Setup con Base de Datos en Memoria

```dart
late AppDatabase db;
late SomeDao dao;

setUp(() {
  db = AppDatabase.forTesting(NativeDatabase.memory());
  dao = SomeDao(db);
});

tearDown(() async {
  await db.close();
});
```

### Override de Providers

```dart
Widget createTestWidget() {
  return ProviderScope(
    overrides: [
      someProvider.overrideWith((ref) {
        return Stream.value(mockData);
      }),
    ],
    child: const MaterialApp(
      home: MyScreen(),
    ),
  );
}
```

### Evitar Conflictos de Imports

```dart
// Drift exporta isNull/isNotNull que conflictúan con matchers
import 'package:drift/drift.dart' hide isNull, isNotNull;
```

### Tests con Animaciones

```dart
testWidgets('descripción', (tester) async {
  await tester.pumpWidget(createTestWidget());
  await tester.pumpAndSettle(); // Esperar animaciones

  expect(find.text('Algo'), findsOneWidget);
});
```

## Comandos

```bash
# Ejecutar todos los tests
flutter test

# Con cobertura
flutter test --coverage

# Tests específicos
flutter test test/unit/
flutter test test/presentation/screens/dashboard_screen_test.dart

# Tests con verbose output
flutter test --reporter=expanded

# Tests con timeout personalizado
flutter test --timeout=60s
```

## Política de Tests

### Tests Fallando - Jerarquía de Acciones

1. **ARREGLAR** el código que el test expone como roto
2. **ARREGLAR** el test si está mal escrito
3. **SKIP + ISSUE** si requiere investigación profunda
4. **NUNCA ELIMINAR** un test sin documentación

### Formato para Skip

```dart
testWidgets('descripción',
  skip: 'Flaky - Issue #123: Timing en animaciones',
  (tester) async {
    // ...
  },
);
```

### Métricas de Salud

- ✅ Tests pasando: objetivo 100%
- ⚠️ Tests skipped: máximo 5%
- ❌ Tests eliminados sin issue: PROHIBIDO

## CI/CD

```yaml
# .github/workflows/test.yml
name: Tests
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: dart run build_runner build --delete-conflicting-outputs
      - run: flutter test --coverage
      - run: flutter analyze
```
