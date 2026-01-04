---
name: testing
description: Estrategias de testing para Finanzas Familiares. Incluye tests unitarios, widgets, integracion, AI Chat, seguridad, performance, PWA/offline, Android y produccion. Usar para crear, ejecutar, o mejorar tests.
---

# Testing

Skill de testing completo para Finanzas Familiares (300+ tests).

## Estructura de Tests

```
test/
├── unit/                 # Tests de logica pura (29)
│   ├── models/           # Tests de modelos
│   └── providers/        # Tests de providers
├── widget/               # Tests de UI (28)
│   └── features/         # Por feature
├── integration/          # Tests de flujos (28)
│   └── flows/
├── ai_chat/              # Tests del asistente IA (41)
│   ├── ai_chat_service_test.dart
│   └── chat_widget_test.dart
├── security/             # Tests de seguridad (20)
│   └── api_security_test.dart
├── performance/          # Tests de rendimiento (18)
│   └── chat_performance_test.dart
├── pwa/                  # Tests PWA/Offline (17)
│   └── service_worker_test.dart
├── android/              # Tests Android (12)
│   └── android_compatibility_test.dart
├── production/           # Tests agresivos (40+)
│   └── production_readiness_test.dart
├── e2e/                  # Tests end-to-end (81)
│   └── scenarios/
├── supabase/             # Tests Supabase Auth/RLS
│   ├── auth_test.dart
│   └── security_rls_test.dart
└── helpers/              # Mocks y utilidades compartidas
    └── test_helpers.dart
```

## Comandos Rapidos

```bash
# Todos los tests
flutter test

# Por categoria
flutter test test/unit/
flutter test test/widget/
flutter test test/integration/
flutter test test/ai_chat/
flutter test test/security/
flutter test test/performance/
flutter test test/pwa/
flutter test test/android/
flutter test test/production/

# Con coverage
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

## Estado Actual

| Categoria | Tests | Descripcion |
|-----------|-------|-------------|
| Unit | 29 | Modelos, repositorios, utils |
| Widget | 28 | Componentes UI, forms |
| Integration | 28 | Flujos completos |
| AI Chat | 41 | Servicio Gemini, mensajes, contexto |
| Security | 20 | Validacion, RLS, API |
| Performance | 18 | Tiempos, memoria, stress |
| PWA/Offline | 17 | Sync, cache, offline-first |
| Android | 12 | Pantallas, orientacion, temas |
| Production | 40+ | Edge cases, valores extremos |
| E2E | 81 | Requieren Supabase activo |
| **Total** | **300+** | **Pasando (excepto E2E)** |

## Documentacion Detallada

- [TESTING_STRATEGY.md](TESTING_STRATEGY.md) - Estrategia completa
- [PWA_OFFLINE_TESTS.md](PWA_OFFLINE_TESTS.md) - Tests offline-first
- [SUPABASE_AUTH_TESTS.md](SUPABASE_AUTH_TESTS.md) - Tests de autenticacion
- [SECURITY_RLS_TESTS.md](SECURITY_RLS_TESTS.md) - Tests de seguridad RLS
- [PRODUCTION_TESTS.md](PRODUCTION_TESTS.md) - Tests agresivos de produccion

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
