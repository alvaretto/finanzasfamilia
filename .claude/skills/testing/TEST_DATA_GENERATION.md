# Test Data Generation Guide

Guía para generar datos de prueba válidos y prevenir anti-patrones comunes.

## Anti-Patrón Crítico: Montos de Transacción = 0

### El Problema

```dart
// ❌ ANTI-PATRÓN: Genera amount = 0 cuando i = 0
for (int i = 0; i < 100; i++) {
  await repo.createTransaction(TransactionModel(
    amount: i.toDouble(),  // ← FALLA cuando i = 0
    ...
  ));
}
```

**Por qué falla**:
- `TransactionRepository` valida `amount > 0` (lib/features/transactions/data/repositories/transaction_repository.dart:116)
- Cuando `i = 0`, `amount = 0.0` → `ArgumentError: El monto debe ser mayor a cero`
- Esto rompe tests de performance, integration y E2E que generan datos en loops

### Soluciones

#### Opción 1: Offset en el índice (Simple)

```dart
// ✅ CORRECTO: Usa i+1 para garantizar amount >= 1.0
for (int i = 0; i < 100; i++) {
  amount: (i + 1).toDouble(),  // 1, 2, 3, ...
}
```

**Ventajas**: Simple, explícito, no requiere imports adicionales
**Desventajas**: Fácil de olvidar, se repite en cada test

#### Opción 2: Helper estandarizado (Recomendado)

```dart
// ✅ MEJOR: Usa helper que valida automáticamente
import '../helpers/test_helpers.dart';

final tx = generateTestTransaction(
  index: i,  // Puede ser 0, el helper lo maneja
  userId: userId,
);
```

**Ventajas**: Centralizado, auto-documenta, validación incorporada
**Desventajas**: Requiere import, menos flexible para casos edge

#### Opción 3: List.generate con helper (Óptimo)

```dart
// ✅ ÓPTIMO: Para listas completas
import '../helpers/test_helpers.dart';

final txs = generateTestTransactionList(
  count: 100,
  userId: userId,
  baseAmount: 10.0,
);

for (final tx in txs) {
  await repo.createTransaction(tx);
}
```

**Ventajas**: Más limpio, menos código, no hay loops manuales
**Desventajas**: Menos control sobre cada transacción individual

---

## Uso del Helper

### generateTestTransaction()

Genera una transacción de prueba con montos válidos garantizados.

**Firma**:
```dart
TransactionModel generateTestTransaction({
  required int index,
  required String userId,
  String? accountId,
  TransactionType type = TransactionType.expense,
  double baseAmount = 1.0,
  double multiplier = 1.0,
  String? description,
  String? categoryId,
})
```

**Parámetros**:
- `index` (required): Índice del loop (puede ser 0)
- `userId` (required): ID del usuario
- `accountId` (optional): ID de cuenta (default: 'default-account')
- `type` (optional): TransactionType (default: expense)
- `baseAmount` (optional): Monto base (default: 1.0)
- `multiplier` (optional): Multiplicador (default: 1.0)
- `description` (optional): Descripción
- `categoryId` (optional): ID de categoría

**Cálculo de monto**: `baseAmount * (index + 1) * multiplier`

**Ejemplos**:

```dart
// Ejemplo 1: Montos 10, 20, 30, ...
for (int i = 0; i < 100; i++) {
  final tx = generateTestTransaction(
    index: i,
    userId: 'user-1',
    baseAmount: 10.0,
  );
  // amount = 10.0 * (0+1) = 10.0 en primera iteración
  // amount = 10.0 * (1+1) = 20.0 en segunda iteración
}

// Ejemplo 2: Montos 1, 2, 3, ... (mínimo)
final tx = generateTestTransaction(
  index: 0,
  userId: 'u1',
);
// amount = 1.0 * (0+1) = 1.0

// Ejemplo 3: Montos 100, 200, 300, ...
final tx = generateTestTransaction(
  index: 0,
  userId: 'u1',
  baseAmount: 100.0,
);
// amount = 100.0 * (0+1) = 100.0

// Ejemplo 4: Ingresos con categoría
final income = generateTestTransaction(
  index: 5,
  userId: 'user-123',
  type: TransactionType.income,
  categoryId: 'salary-cat',
  baseAmount: 50.0,
);
// amount = 50.0 * (5+1) = 300.0
```

---

### generateTestTransactionList()

Genera lista completa de transacciones con montos válidos.

**Firma**:
```dart
List<TransactionModel> generateTestTransactionList({
  required int count,
  required String userId,
  String? accountId,
  int startIndex = 0,
  double baseAmount = 1.0,
  TransactionType type = TransactionType.expense,
})
```

**Parámetros**:
- `count` (required): Número de transacciones a generar
- `userId` (required): ID del usuario
- `accountId` (optional): ID de cuenta para todas las transacciones
- `startIndex` (optional): Índice inicial (default: 0)
- `baseAmount` (optional): Monto base (default: 1.0)
- `type` (optional): TransactionType (default: expense)

**Ejemplos**:

```dart
// Ejemplo 1: 100 gastos con montos 5, 10, 15, ...
final txs = generateTestTransactionList(
  count: 100,
  userId: 'user-123',
  baseAmount: 5.0,
  type: TransactionType.expense,
);

// Usar en tests
for (final tx in txs) {
  await repo.createTransaction(tx);
}

// Ejemplo 2: Ingresos y gastos combinados
final expenses = generateTestTransactionList(
  count: 50,
  userId: userId,
  type: TransactionType.expense,
  baseAmount: 10.0,
);

final incomes = generateTestTransactionList(
  count: 20,
  userId: userId,
  type: TransactionType.income,
  baseAmount: 100.0,
);

// Ejemplo 3: Iniciar desde un índice diferente
final moreTxs = generateTestTransactionList(
  count: 50,
  userId: userId,
  startIndex: 100,  // Índices 100-149
  baseAmount: 2.0,
);
// Primera tx: amount = 2.0 * (100+1) = 202.0
// Segunda tx: amount = 2.0 * (101+1) = 204.0
```

---

### TestDataValidators

Valida que datos generados cumplen reglas de negocio.

**Métodos**:

#### validateTransaction()
```dart
static void validateTransaction(TransactionModel tx)
```

Valida una transacción individual. Lanza `ArgumentError` si:
- `amount <= 0`
- `userId` está vacío
- `accountId` está vacío

**Ejemplo**:
```dart
final tx = generateTestTransaction(index: 0, userId: 'u1');
TestDataValidators.validateTransaction(tx);  // OK

final badTx = TransactionModel(
  id: 'test',
  userId: '',
  amount: 0,  // ← Invalido
  ...
);
TestDataValidators.validateTransaction(badTx);  // Throws ArgumentError
```

#### validateTransactionList()
```dart
static void validateTransactionList(List<TransactionModel> txs)
```

Valida lista completa de transacciones. Llama a `validateTransaction()` para cada item.

**Ejemplo**:
```dart
final txs = generateTestTransactionList(count: 100, userId: 'u1');
TestDataValidators.validateTransactionList(txs);  // OK - todas válidas

// En tests, antes de insertar datos
final testData = generateTestTransactionList(count: 1000, userId: userId);
TestDataValidators.validateTransactionList(testData);  // Verifica antes de insertar
for (final tx in testData) {
  await repo.createTransaction(tx);
}
```

---

## Patrones Recomendados por Tipo de Test

### Performance Tests

**Objetivo**: Medir velocidad de inserts/queries sin errores de validación

```dart
test('Insertar 1000 transacciones < 5s', () async {
  final stopwatch = Stopwatch()..start();

  final txs = generateTestTransactionList(
    count: 1000,
    userId: userId,
    baseAmount: 1.0,  // Monto mínimo válido
  );

  for (final tx in txs) {
    await repo.createTransaction(tx);
  }

  stopwatch.stop();
  expect(stopwatch.elapsedMilliseconds, lessThan(5000));
});
```

### Integration Tests

**Objetivo**: Probar flujos completos con variedad de datos

```dart
test('Dashboard muestra balance correcto', () async {
  // Crear datos variados
  final expenses = generateTestTransactionList(
    count: 10,
    userId: userId,
    type: TransactionType.expense,
    baseAmount: 50.0,  // Gastos de 50, 100, 150, ...
  );

  final incomes = generateTestTransactionList(
    count: 5,
    userId: userId,
    type: TransactionType.income,
    baseAmount: 100.0,  // Ingresos de 100, 200, 300, ...
  );

  // Insertar todos
  for (final tx in [...expenses, ...incomes]) {
    await repo.createTransaction(tx);
  }

  // Verificar balance
  final balance = await repo.getTotalBalance(userId);
  final expectedBalance =
    (100 + 200 + 300 + 400 + 500) - (50 + 100 + 150 + ... + 500);
  expect(balance, expectedBalance);
});
```

### E2E Tests

**Objetivo**: Escenarios realistas con datos específicos

```dart
testWidgets('Crear transacción desde pantalla', (tester) async {
  final tx = generateTestTransaction(
    index: 0,
    userId: currentUser.id,
    accountId: selectedAccount.id,
    categoryId: 'groceries',
    description: 'Supermercado del Ahorro',
    baseAmount: 85.5,
  );

  // ... interactuar con UI para crear tx

  // Verificar que se creó
  final created = await repo.getTransaction(tx.id);
  expect(created.amount, tx.amount);
});
```

---

## Checklist: Antes de Crear Tests con Loops

Antes de escribir un test que genera datos en loops, verifica:

- [ ] ¿Usas `amount: i.toDouble()` directamente? → **Cambia a `(i + 1).toDouble()`**
- [ ] ¿El loop empieza en 0? → **Usa helper o agrega offset (+1)**
- [ ] ¿Generas >10 transacciones? → **Considera `generateTestTransactionList()`**
- [ ] ¿Validaste que ningún monto puede ser 0? → **Usa `TestDataValidators`**
- [ ] ¿El test necesita montos específicos? → **Usa parámetro `baseAmount`**
- [ ] ¿Necesitas UUIDs únicos? → **El helper usa `Uuid().v4()` automáticamente**

---

## Anti-Patrones Adicionales

### 1. UUIDs Hardcoded

```dart
// ❌ MAL: UUID repetido causa conflictos
for (int i = 0; i < 100; i++) {
  TransactionModel(
    id: 'transaction-1',  // Todos tienen el mismo ID!
    ...
  );
}

// ✅ BIEN: UUID único por transacción
for (int i = 0; i < 100; i++) {
  TransactionModel(
    id: const Uuid().v4(),  // Cada uno único
    ...
  );
}

// ✅ MEJOR: Helper ya lo hace
final tx = generateTestTransaction(index: i, userId: userId);
// ID es automáticamente Uuid().v4()
```

### 2. Fechas Sin Variedad

```dart
// ❌ MAL: Todas las transacciones en la misma fecha
for (int i = 0; i < 100; i++) {
  TransactionModel(
    date: DateTime.now(),  // Todas same timestamp
    ...
  );
}

// ✅ BIEN: Variar fechas para tests realistas
for (int i = 0; i < 100; i++) {
  TransactionModel(
    date: DateTime.now().subtract(Duration(days: i)),
    // 0 = hoy, 1 = ayer, 2 = anteayer, ...
    ...
  );
}
```

### 3. Descripciones Genéricas

```dart
// ❌ MAL: Difícil de debuggear
for (int i = 0; i < 100; i++) {
  TransactionModel(
    description: 'Test',  // Todas iguales
    ...
  );
}

// ✅ BIEN: Descripciones únicas
for (int i = 0; i < 100; i++) {
  TransactionModel(
    description: 'Test transaction $i',
    ...
  );
}

// ✅ MEJOR: Helper ya lo hace
final tx = generateTestTransaction(index: i, userId: userId);
// description = 'Test transaction 0', 'Test transaction 1', ...
```

### 4. No Validar Antes de Insertar

```dart
// ❌ MAL: Insertar datos sin validar
final txs = [...];  // Datos de algún lugar
for (final tx in txs) {
  await repo.createTransaction(tx);  // Puede fallar en runtime
}

// ✅ BIEN: Validar antes de insertar
final txs = generateTestTransactionList(count: 100, userId: userId);
TestDataValidators.validateTransactionList(txs);  // Falla early si inválido
for (final tx in txs) {
  await repo.createTransaction(tx);
}
```

---

## Casos de Uso Avanzados

### Test de Stress con Variedad

```dart
test('Sistema maneja 10,000 transacciones mixtas', () async {
  // Crear datos con diferentes características
  final smallExpenses = generateTestTransactionList(
    count: 5000,
    userId: userId,
    type: TransactionType.expense,
    baseAmount: 1.0,  // Gastos pequeños: 1, 2, 3, ...
  );

  final largeIncomes = generateTestTransactionList(
    count: 3000,
    userId: userId,
    type: TransactionType.income,
    baseAmount: 100.0,  // Ingresos grandes: 100, 200, 300, ...
    startIndex: 5000,  // Evitar overlap con expenses
  );

  final transfers = generateTestTransactionList(
    count: 2000,
    userId: userId,
    type: TransactionType.transfer,
    baseAmount: 50.0,
    startIndex: 8000,
  );

  // Insertar todos
  final allTxs = [...smallExpenses, ...largeIncomes, ...transfers];
  for (final tx in allTxs) {
    await repo.createTransaction(tx);
  }

  // Verificar
  final allFromDb = await repo.getTransactions(userId);
  expect(allFromDb.length, 10000);
});
```

### Test Comparativo de Performance

```dart
group('Performance: Monto Impact', () {
  test('Montos pequeños vs grandes - mismo performance', () async {
    // Pequeños: 1, 2, 3, ...
    final small = generateTestTransactionList(
      count: 1000,
      userId: userId,
      baseAmount: 1.0,
    );

    final stopwatch1 = Stopwatch()..start();
    for (final tx in small) {
      await repo.createTransaction(tx);
    }
    final time1 = stopwatch1.elapsedMilliseconds;

    // Grandes: 1000000, 2000000, 3000000, ...
    final large = generateTestTransactionList(
      count: 1000,
      userId: userId,
      baseAmount: 1000000.0,
    );

    final stopwatch2 = Stopwatch()..start();
    for (final tx in large) {
      await repo.createTransaction(tx);
    }
    final time2 = stopwatch2.elapsedMilliseconds;

    // Performance no debe variar significativamente
    expect((time2 - time1).abs(), lessThan(500));
  });
});
```

---

## Referencias

**Código**:
- Helper: `test/helpers/test_data_generators.dart`
- Ejemplo de uso: `test/performance/app_performance_test.dart:98,128,153` (corregido)
- Validación en repository: `lib/features/transactions/data/repositories/transaction_repository.dart:116`

**Documentación**:
- Testing Strategy: [TESTING_STRATEGY.md](./TESTING_STRATEGY.md)
- Test README: [test/README.md](../../test/README.md)
- Error documentado: `.error-tracker/errors/ERR-0005.json`
- Test de regresión: `test/regression/unit/transactions/err_0005_amount_zero_regression_test.dart`

---

## FAQs

**P: ¿Por qué no simplemente cambiar la validación en TransactionRepository para aceptar amount = 0?**

R: La validación `amount > 0` es correcta y necesaria. En un sistema financiero real, no deben existir transacciones de $0. El problema está en cómo generamos datos de prueba, no en la validación de negocio.

**P: ¿Puedo usar el helper para otros modelos como BudgetModel o GoalModel?**

R: Por ahora el helper solo soporta TransactionModel. Si necesitas helpers para otros modelos, crea funciones similares siguiendo el mismo patrón.

**P: ¿El helper es obligatorio o puedo seguir usando loops manuales?**

R: El helper es opcional. Puedes seguir usando loops manuales siempre que uses `(i + 1)` para garantizar montos > 0. El helper es recomendado para centralizar la lógica y evitar olvidos.

**P: ¿Qué pasa si necesito un monto específico que no sea múltiplo del índice?**

R: Usa el parámetro `baseAmount` y `multiplier`, o simplemente crea la transacción manualmente con `TransactionModel(amount: tuMontoEspecifico, ...)`.

**P: ¿Por qué generateTestTransactionList() usa startIndex?**

R: Para poder generar múltiples listas sin overlap de montos. Por ejemplo, si generas 1000 items con startIndex=0 y luego otros 1000 con startIndex=1000, los montos serán diferentes.
