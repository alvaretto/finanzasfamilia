# Schema Plan - PowerSync + Supabase

## Arquitectura de Datos

```
┌─────────────────────────────────────────────────────────────────┐
│                        Flutter App                               │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │                    PowerSync Client                         │ │
│  │  ┌─────────────┐    ┌─────────────────────────────────────┐ │ │
│  │  │   SQLite    │◀──▶│  Sync Engine (Background)           │ │ │
│  │  │   (Drift)   │    │  - Bidirectional sync               │ │ │
│  │  └─────────────┘    │  - Conflict resolution              │ │ │
│  │                     │  - Offline queue                    │ │ │
│  │                     └─────────────────────────────────────┘ │ │
│  └─────────────────────────────────────────────────────────────┘ │
└───────────────────────────────────────────────────────────────┬─┘
                                                                │
                                                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                     PowerSync Service                            │
│                  (Sync Rules + Replication)                      │
└───────────────────────────────────────────────────────────────┬─┘
                                                                │
                                                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Supabase Postgres                             │
│                   (Source of Truth)                              │
└─────────────────────────────────────────────────────────────────┘
```

## Tablas

### users
```sql
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT UNIQUE NOT NULL,
  display_name TEXT,
  avatar_url TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);
```

### accounts (Lo que Tengo)
```sql
CREATE TABLE accounts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,                    -- "Nequi", "Efectivo Billetera"
  type TEXT NOT NULL,                    -- cash, bank, digital_wallet, investment
  subtype TEXT,                          -- savings, checking, cdt
  balance DECIMAL(15,2) DEFAULT 0,
  currency TEXT DEFAULT 'COP',
  icon TEXT,                             -- emoji o icon name
  color TEXT,                            -- hex color
  is_active BOOLEAN DEFAULT true,
  sort_order INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Tipos:
-- cash: Efectivo (Billetera, Caja Menor, Alcancía)
-- bank: Cuenta bancaria (Davivienda, Bancolombia)
-- digital_wallet: Billetera digital (Nequi, DaviPlata, PayPal)
-- investment: Inversiones (CDT, Propiedades)
```

### liabilities (Lo que Debo)
```sql
CREATE TABLE liabilities (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,                    -- "Visa Davivienda", "Préstamo Vehículo"
  type TEXT NOT NULL,                    -- credit_card, loan, payable
  subtype TEXT,                          -- mortgage, vehicle, personal, tax
  balance DECIMAL(15,2) DEFAULT 0,       -- Saldo actual adeudado
  credit_limit DECIMAL(15,2),            -- Límite (para tarjetas)
  interest_rate DECIMAL(5,2),            -- Tasa de interés
  due_day INTEGER,                       -- Día de corte/vencimiento
  currency TEXT DEFAULT 'COP',
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);
```

### categories
```sql
CREATE TABLE categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  parent_id UUID REFERENCES categories(id),  -- Para subcategorías
  name TEXT NOT NULL,                    -- "Alimentación", "Mercado", "Frutas"
  type TEXT NOT NULL,                    -- income, expense
  icon TEXT,
  color TEXT,
  is_system BOOLEAN DEFAULT false,       -- Categorías predefinidas
  sort_order INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Jerarquía ejemplo:
-- Alimentación (parent_id: null)
--   └── Mercado (parent_id: Alimentación)
--         └── Frutas (parent_id: Mercado)
--         └── Cárnicos (parent_id: Mercado)
--   └── Restaurantes (parent_id: Alimentación)
```

### transactions
```sql
CREATE TABLE transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  account_id UUID REFERENCES accounts(id),
  liability_id UUID REFERENCES liabilities(id),  -- Si es pago de deuda
  category_id UUID REFERENCES categories(id),
  type TEXT NOT NULL,                    -- income, expense, transfer
  amount DECIMAL(15,2) NOT NULL,
  description TEXT,
  date DATE NOT NULL,
  time TIME,
  is_recurring BOOLEAN DEFAULT false,
  recurring_id UUID,                     -- Referencia a transacción recurrente
  tags TEXT[],
  attachments TEXT[],                    -- URLs de fotos/recibos
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Índices para consultas frecuentes
CREATE INDEX idx_transactions_user_date ON transactions(user_id, date DESC);
CREATE INDEX idx_transactions_category ON transactions(category_id);
CREATE INDEX idx_transactions_account ON transactions(account_id);
```

### recurring_transactions
```sql
CREATE TABLE recurring_transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  account_id UUID REFERENCES accounts(id),
  category_id UUID REFERENCES categories(id),
  type TEXT NOT NULL,
  amount DECIMAL(15,2) NOT NULL,
  description TEXT,
  frequency TEXT NOT NULL,               -- daily, weekly, monthly, yearly
  interval INTEGER DEFAULT 1,            -- cada N frecuencias
  start_date DATE NOT NULL,
  end_date DATE,
  next_date DATE,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now()
);
```

### budgets
```sql
CREATE TABLE budgets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  category_id UUID REFERENCES categories(id),
  amount DECIMAL(15,2) NOT NULL,
  period TEXT NOT NULL,                  -- monthly, yearly
  start_date DATE,
  end_date DATE,
  alert_threshold DECIMAL(3,2) DEFAULT 0.80,  -- Alertar al 80%
  created_at TIMESTAMPTZ DEFAULT now()
);
```

## PowerSync Sync Rules

```yaml
# powersync.yaml
bucket_definitions:
  user_data:
    parameters:
      - SELECT id as user_id FROM users WHERE id = token_parameters.user_id
    data:
      - SELECT * FROM accounts WHERE user_id = bucket.user_id
      - SELECT * FROM liabilities WHERE user_id = bucket.user_id
      - SELECT * FROM categories WHERE user_id = bucket.user_id OR is_system = true
      - SELECT * FROM transactions WHERE user_id = bucket.user_id
      - SELECT * FROM recurring_transactions WHERE user_id = bucket.user_id
      - SELECT * FROM budgets WHERE user_id = bucket.user_id
```

## Drift Schema (Flutter)

```dart
// lib/src/core/database/schema.dart
class Accounts extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get name => text()();
  TextColumn get type => text()();
  TextColumn get subtype => text().nullable()();
  RealColumn get balance => real().withDefault(const Constant(0))();
  TextColumn get currency => text().withDefault(const Constant('COP'))();
  TextColumn get icon => text().nullable()();
  TextColumn get color => text().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
```

## Categorías Predefinidas (Seed)

Basado en `nuevo-mermaid2.md`:

```dart
final systemCategories = [
  // Gastos - Nivel 1
  Category(name: 'Impuestos', type: 'expense', icon: '🏛️'),
  Category(name: 'Servicios', type: 'expense', icon: '💡'),
  Category(name: 'Alimentación', type: 'expense', icon: '🍽️'),
  Category(name: 'Transporte', type: 'expense', icon: '🚗'),
  Category(name: 'Entretenimiento', type: 'expense', icon: '🎬'),
  Category(name: 'Salud', type: 'expense', icon: '🏥'),
  Category(name: 'Educación', type: 'expense', icon: '📚'),
  Category(name: 'Aseo', type: 'expense', icon: '🧹'),
  Category(name: 'Otros Gastos', type: 'expense', icon: '📦'),

  // Alimentación - Nivel 2
  Category(name: 'Mercado', type: 'expense', parent: 'Alimentación'),
  Category(name: 'Restaurantes', type: 'expense', parent: 'Alimentación'),
  Category(name: 'Domicilios', type: 'expense', parent: 'Alimentación'),

  // Mercado - Nivel 3
  Category(name: 'Frutas', type: 'expense', parent: 'Mercado'),
  Category(name: 'Verduras', type: 'expense', parent: 'Mercado'),
  Category(name: 'Cárnicos', type: 'expense', parent: 'Mercado'),
  Category(name: 'Lácteos', type: 'expense', parent: 'Mercado'),
  Category(name: 'Granos', type: 'expense', parent: 'Mercado'),
  Category(name: 'Mecato', type: 'expense', parent: 'Mercado'),
  // ... más subcategorías

  // Ingresos
  Category(name: 'Salario', type: 'income', icon: '💰'),
  Category(name: 'Ventas', type: 'income', icon: '🛒'),
  Category(name: 'Rendimientos', type: 'income', icon: '📈'),
  Category(name: 'Otros Ingresos', type: 'income', icon: '💵'),
];
```
