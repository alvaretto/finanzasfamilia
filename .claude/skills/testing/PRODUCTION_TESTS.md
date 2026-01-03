# Tests de Produccion

Tests agresivos que verifican la app esta lista para deployment.

## Ubicacion

```
test/production/production_readiness_test.dart
```

## Categorias de Tests

### 1. Valores Extremos

Verificar que los modelos manejan valores limite:

```dart
test('AccountModel maneja valores extremos', () {
  // Balance muy grande
  final large = AccountModel.create(
    userId: 'test',
    name: 'Large',
    type: AccountType.bank,
    currency: 'MXN',
    balance: 999999999999.99,
  );
  expect(large.balance, 999999999999.99);

  // Balance negativo extremo
  final negative = AccountModel.create(
    userId: 'test',
    name: 'Negative',
    type: AccountType.credit,
    currency: 'MXN',
    balance: -999999999999.99,
  );
  expect(negative.balance, -999999999999.99);

  // Balance cero
  final zero = AccountModel.create(
    userId: 'test',
    name: 'Zero',
    type: AccountType.cash,
    currency: 'MXN',
    balance: 0,
  );
  expect(zero.balance, 0);
});
```

### 2. Caracteres Especiales

Verificar que strings con caracteres especiales no rompen la app:

```dart
test('TransactionModel maneja caracteres especiales', () {
  final tx = TransactionModel.create(
    userId: 'test',
    accountId: 'acc-1',
    amount: 100,
    type: TransactionType.expense,
    description: 'Test <script>alert("xss")</script> & "quotes"',
    notes: 'Emojis 💰🎉 y acentos: áéíóú ñ',
  );

  expect(tx.description, contains('<script>'));
  expect(tx.notes, contains('💰'));
});
```

### 3. Division por Cero

Verificar que calculos no fallan con divisores cero:

```dart
test('BudgetModel previene division por cero', () {
  final budget = BudgetModel.create(
    userId: 'test',
    categoryId: 1,
    amount: 0,  // Presupuesto de $0
    period: BudgetPeriod.monthly,
  );

  expect(budget.percentSpent, 0);  // No debe ser NaN o Infinity
  expect(budget.remaining, 0);
});

test('GoalModel calcula progreso con target cero', () {
  final goal = GoalModel.create(
    userId: 'test',
    name: 'Zero Goal',
    targetAmount: 0,
    currentAmount: 100,
  );

  expect(goal.percentComplete, 0);  // No division por cero
});
```

### 4. Seguridad de Memoria

Verificar que listas grandes no causan problemas:

```dart
test('Crear muchos modelos no causa problemas', () {
  final accounts = List.generate(1000, (i) => AccountModel.create(
    userId: 'test',
    name: 'Account $i',
    type: AccountType.bank,
    currency: 'MXN',
    balance: i * 100.0,
  ));

  expect(accounts.length, 1000);
});

test('Filtrar listas grandes es eficiente', () {
  final transactions = List.generate(10000, (i) => TransactionModel.create(
    userId: 'test',
    accountId: 'acc-${i % 10}',
    amount: i * 1.5,
    type: i % 3 == 0 ? TransactionType.income : TransactionType.expense,
  ));

  const filters = TransactionFilters(
    type: TransactionType.income,
    minAmount: 1000,
  );

  final stopwatch = Stopwatch()..start();
  final result = filters.apply(transactions);
  stopwatch.stop();

  expect(result.isNotEmpty, true);
  expect(stopwatch.elapsedMilliseconds, lessThan(1000));  // < 1 segundo
});
```

### 5. Null Safety

Verificar que campos nullable se manejan correctamente:

```dart
test('AccountModel maneja campos nullable', () {
  final account = AccountModel.create(
    userId: 'test',
    name: 'Test',
    type: AccountType.bank,
    currency: 'MXN',
  );

  expect(account.bankName, isNull);
  expect(account.lastFourDigits, isNull);
  expect(account.familyId, isNull);
  expect(account.color, isNotNull);  // Tiene default
  expect(account.icon, isNotNull);   // Tiene default
});
```

### 6. Calculos Financieros

Verificar que calculos criticos son correctos:

```dart
test('Calculo de patrimonio neto es correcto', () {
  final accounts = [
    AccountModel(id: '1', userId: 'test', name: 'Bank',
      type: AccountType.bank, currency: 'MXN', balance: 10000),
    AccountModel(id: '2', userId: 'test', name: 'Cash',
      type: AccountType.cash, currency: 'MXN', balance: 5000),
    AccountModel(id: '3', userId: 'test', name: 'Credit',
      type: AccountType.credit, currency: 'MXN', balance: -3000),
    AccountModel(id: '4', userId: 'test', name: 'Loan',
      type: AccountType.loan, currency: 'MXN', balance: -50000),
  ];

  final assets = accounts
    .where((a) => a.type.isAsset)
    .fold(0.0, (sum, a) => sum + a.balance);
  final liabilities = accounts
    .where((a) => a.type.isLiability)
    .fold(0.0, (sum, a) => sum + a.balance.abs());

  expect(assets, 15000);
  expect(liabilities, 53000);
  expect(assets - liabilities, -38000);
});
```

## Ejecutar Tests de Produccion

```bash
# Solo tests de produccion
flutter test test/production/

# Con verbose output
flutter test test/production/ --reporter expanded
```

## Agregar Nuevos Tests

1. Identificar edge case o escenario critico
2. Agregar test en `production_readiness_test.dart`
3. Agrupar en categoria apropiada (`group()`)
4. Verificar que el test pasa
5. Documentar si es necesario
