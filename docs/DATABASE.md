# Esquema de Base de Datos (Drift/SQLite)

## Versión Actual: 3

## Diagrama de Relaciones

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│   Categories    │     │    Accounts     │     │   Transactions  │
├─────────────────┤     ├─────────────────┤     ├─────────────────┤
│ id (PK)         │◄────┤ categoryId (FK) │     │ id (PK)         │
│ name            │     │ id (PK)         │◄────┤ accountId (FK)  │
│ type            │     │ name            │     │ categoryId (FK) │────►
│ parentId (FK)   │─┐   │ balance         │     │ amount          │
│ level           │ │   │ icon            │     │ type            │
│ icon            │ │   │ color           │     │ date            │
└─────────────────┘ │   │ includeInTotal  │     │ description     │
        ▲           │   └─────────────────┘     └─────────────────┘
        └───────────┘                                    │
                                                         ▼
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│     Budgets     │     │ JournalEntries  │     │TransactionDetails│
├─────────────────┤     ├─────────────────┤     ├─────────────────┤
│ id (PK)         │     │ id (PK)         │     │ id (PK)         │
│ categoryId (FK) │────►│ transactionId   │◄────┤ transactionId   │
│ amount          │     │ accountId (FK)  │     │ concept         │
│ spent           │     │ debit           │     │ quantity        │
│ month           │     │ credit          │     │ unitPrice       │
│ year            │     └─────────────────┘     │ unitId (FK)     │
└─────────────────┘                             └─────────────────┘

┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│MeasurementUnits │     │     Places      │     │ PaymentMethods  │
├─────────────────┤     ├─────────────────┤     ├─────────────────┤
│ id (PK)         │     │ id (PK)         │     │ id (PK)         │
│ name            │     │ name            │     │ name            │
│ abbreviation    │     │ type            │     │ accountId (FK)  │
│ type            │     │ address         │     │ isActive        │
└─────────────────┘     └─────────────────┘     └─────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                    RecurringTransactions                         │
├─────────────────────────────────────────────────────────────────┤
│ id (PK)           │ name              │ type                    │
│ amount            │ categoryId (FK)   │ frequency               │
│ dayOfExecution    │ startDate         │ endDate                 │
│ nextExecutionDate │ lastExecutedAt    │ isActive                │
│ requiresConfirmation │ executionCount │ fromAccountId (FK)      │
│ toAccountId (FK)  │ description       │ createdAt, updatedAt    │
└─────────────────────────────────────────────────────────────────┘
```

## Tablas Detalladas

### Categories (Taxonomía Financiera)

```dart
class Categories extends Table {
  TextColumn get id => text()();                    // UUID
  TextColumn get name => text()();                  // "Alimentación"
  TextColumn get type => text()();                  // asset|liability|income|expense
  TextColumn get parentId => text().nullable()      // Jerarquía
      .references(Categories, #id)();
  IntColumn get level => integer().withDefault(const Constant(0))();
  TextColumn get icon => text().nullable()();       // Emoji: "🍎"
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
```

**Tipos de Categoría:**
- `asset` - Activos (Lo que tengo)
- `liability` - Pasivos (Lo que debo)
- `income` - Ingresos (Dinero que entra)
- `expense` - Gastos (Dinero que sale)

### Accounts (Cuentas Financieras)

```dart
class Accounts extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();                  // "Nequi"
  TextColumn get categoryId => text()              // Vincula a categoría
      .references(Categories, #id)();
  RealColumn get balance => real().withDefault(const Constant(0))();
  TextColumn get icon => text().withDefault(const Constant('💰'))();
  TextColumn get color => text().withDefault(const Constant('#4CAF50'))();
  TextColumn get description => text().nullable()();
  BoolColumn get includeInTotal => boolean().withDefault(const Constant(true))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
```

### Transactions (Encabezado)

```dart
class Transactions extends Table {
  TextColumn get id => text()();
  TextColumn get type => text()();                  // income|expense|transfer
  RealColumn get totalAmount => real()();
  DateTimeColumn get date => dateTime()();
  TextColumn get description => text().nullable()();
  TextColumn get accountId => text().nullable()
      .references(Accounts, #id)();
  TextColumn get categoryId => text().nullable()
      .references(Categories, #id)();
  TextColumn get placeId => text().nullable()
      .references(Places, #id)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
```

### TransactionDetails (Carrito de Compras)

```dart
class TransactionDetails extends Table {
  TextColumn get id => text()();
  TextColumn get transactionId => text()
      .references(Transactions, #id)();
  TextColumn get concept => text()();               // "Manzanas"
  RealColumn get quantity => real().withDefault(const Constant(1))();
  RealColumn get unitPrice => real()();
  RealColumn get totalValue => real()();
  TextColumn get unitId => text().nullable()
      .references(MeasurementUnits, #id)();
  TextColumn get paymentMethodId => text().nullable()
      .references(PaymentMethods, #id)();
  TextColumn get mode => text().withDefault(const Constant('cash'))();  // cash|credit
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
```

### JournalEntries (Asientos Contables - Partida Doble)

```dart
class JournalEntries extends Table {
  TextColumn get id => text()();
  TextColumn get transactionId => text()
      .references(Transactions, #id)();
  TextColumn get accountId => text()
      .references(Accounts, #id)();
  RealColumn get debit => real().withDefault(const Constant(0))();
  RealColumn get credit => real().withDefault(const Constant(0))();
  TextColumn get description => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
```

**Regla de Oro:**
```
DÉBITO = Lo que ENTRA o AUMENTA
CRÉDITO = Lo que SALE o DISMINUYE
Σ Débitos = Σ Créditos (siempre balanceado)
```

### RecurringTransactions (Pagos Automáticos)

```dart
enum RecurrenceFrequency {
  daily,      // Diario
  weekly,     // Semanal
  biweekly,   // Quincenal
  monthly,    // Mensual
  bimonthly,  // Bimestral
  quarterly,  // Trimestral
  semiannual, // Semestral
  yearly,     // Anual
}

class RecurringTransactions extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();                  // "EDEQ - Luz"
  TextColumn get type => text()();                  // expense|income|transfer
  RealColumn get amount => real()();
  TextColumn get description => text().nullable()();
  TextColumn get fromAccountId => text().nullable()
      .references(Accounts, #id)();
  TextColumn get toAccountId => text().nullable()
      .references(Accounts, #id)();
  TextColumn get categoryId => text()
      .references(Categories, #id)();
  TextColumn get frequency => text()();             // RecurrenceFrequency.name
  IntColumn get dayOfExecution => integer()
      .withDefault(const Constant(1))();            // Día 1-31
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get endDate => dateTime().nullable()();
  DateTimeColumn get lastExecutedAt => dateTime().nullable()();
  DateTimeColumn get nextExecutionDate => dateTime()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  BoolColumn get requiresConfirmation => boolean()
      .withDefault(const Constant(false))();
  IntColumn get executionCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
```

### Budgets (Presupuestos)

```dart
class Budgets extends Table {
  TextColumn get id => text()();
  TextColumn get categoryId => text()
      .references(Categories, #id)();
  RealColumn get amount => real()();                // Presupuesto asignado
  RealColumn get spent => real().withDefault(const Constant(0))();
  IntColumn get month => integer()();               // 1-12
  IntColumn get year => integer()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
```

### Catálogos

```dart
// Unidades de medida
class MeasurementUnits extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();                  // "Libra"
  TextColumn get abbreviation => text()();          // "lb"
  TextColumn get type => text()();                  // weight|volume|unit|package
}

// Lugares
class Places extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();                  // "Éxito Armenia"
  TextColumn get type => text()();                  // supermarket|street|web|store|restaurant|other
  TextColumn get address => text().nullable()();
}

// Métodos de pago
class PaymentMethods extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();                  // "Tarjeta Nequi"
  TextColumn get accountId => text().nullable()
      .references(Accounts, #id)();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
}
```

## Migraciones

```dart
// lib/data/local/database.dart
@override
int get schemaVersion => 3;

@override
MigrationStrategy get migration => MigrationStrategy(
  onCreate: (m) async {
    await m.createAll();
  },
  onUpgrade: (m, from, to) async {
    if (from < 2) {
      // v1 → v2: Agregar campos a accounts
      await m.addColumn(accounts, accounts.icon);
      await m.addColumn(accounts, accounts.color);
    }
    if (from < 3) {
      // v2 → v3: RecurringTransactions
      await m.createTable(recurringTransactions);
    }
  },
);
```

## Índices Recomendados

```sql
-- Transacciones por fecha (reportes)
CREATE INDEX idx_transactions_date ON transactions(date);

-- Transacciones por categoría (agrupación)
CREATE INDEX idx_transactions_category ON transactions(category_id);

-- Journal entries por transacción (partida doble)
CREATE INDEX idx_journal_transaction ON journal_entries(transaction_id);

-- Recurring transactions activas
CREATE INDEX idx_recurring_active ON recurring_transactions(is_active, next_execution_date);
```

## Seeders (Datos Iniciales)

```dart
// lib/data/local/seeders/
class CategorySeeder {
  static Future<void> seed(AppDatabase db) async {
    // Crear taxonomía base
    await db.into(db.categories).insertAll([
      // Activos
      CategoriesCompanion(id: Value('asset-root'), name: Value('Activos'), type: Value('asset'), level: Value(0)),
      CategoriesCompanion(id: Value('asset-cash'), name: Value('Efectivo'), type: Value('asset'), parentId: Value('asset-root'), level: Value(1)),
      CategoriesCompanion(id: Value('asset-banks'), name: Value('Bancos'), type: Value('asset'), parentId: Value('asset-root'), level: Value(1)),
      // ... más categorías
    ]);
  }
}
```
