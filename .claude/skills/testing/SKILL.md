---
name: testing
description: Estrategias de testing para Finanzas Familiares. Incluye tests unitarios, de widgets, integracion, E2E, y tests de produccion. Usar para crear, ejecutar, o mejorar tests.
---

# Testing

Skill de testing para Finanzas Familiares.

## Estructura de Tests

```
test/
├── unit/                 # Tests de logica pura
│   ├── models/           # Tests de modelos
│   └── providers/        # Tests de providers
├── widget/               # Tests de UI
│   └── features/         # Por feature
├── integration/          # Tests de flujos
│   └── flows/
├── e2e/                  # Tests end-to-end
│   └── scenarios/
├── production/           # Tests agresivos
│   └── production_readiness_test.dart
└── mocks/                # Mocks compartidos
```

## Comandos Rapidos

```bash
# Todos los tests
flutter test

# Tests unitarios
flutter test test/unit/

# Tests de widget
flutter test test/widget/

# Tests de integracion
flutter test test/integration/

# Tests de produccion
flutter test test/production/

# Con coverage
flutter test --coverage
```

## Estado Actual

| Tipo | Tests | Estado |
|------|-------|--------|
| Unit | 29 | Pasando |
| Widget | 13 | Pasando |
| Integration | 8 | Pasando |
| Production | 16 | Pasando |
| E2E | 81 | Requieren Supabase |
| **Total** | **172** | **Pasando** |

## Documentacion Detallada

- [UNIT_TESTS.md](UNIT_TESTS.md) - Tests unitarios
- [WIDGET_TESTS.md](WIDGET_TESTS.md) - Tests de widgets
- [E2E_TESTS.md](E2E_TESTS.md) - Tests end-to-end
- [PRODUCTION_TESTS.md](PRODUCTION_TESTS.md) - Tests agresivos

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
