# Finanzas Familiares AS

## Quick Start (Nivel 1)

App de finanzas personales y familiares multiplataforma con soporte offline-first.

```bash
# Desarrollo
flutter pub get && flutter run

# Build Android
flutter build apk --release

# Build Linux Desktop
flutter build linux --release
```

## Arquitectura (Nivel 2)

### Stack Tecnologico
- **Flutter 3.24+** - Framework multiplataforma (Android, iOS, Linux, Windows, Web)
- **Drift + SQLite** - Persistencia local offline-first
- **Riverpod 3.0** - State management reactivo
- **Supabase** - Backend (Auth, Database, Realtime Sync)
- **fl_chart** - Visualizaciones financieras
- **freezed** - Modelos inmutables type-safe
- **go_router** - Navegacion declarativa

### Estructura del Proyecto
```
lib/
├── core/                  # Infraestructura base
│   ├── database/          # Drift tables y DAOs
│   ├── network/           # Supabase client, sync service
│   ├── theme/             # Design system, colores, tipografia
│   └── utils/             # Helpers, extensions, formatters
├── features/              # Modulos por funcionalidad
│   ├── auth/              # Login, registro, biometria
│   ├── accounts/          # Cuentas bancarias y efectivo
│   ├── transactions/      # Ingresos, gastos, transferencias
│   ├── budgets/           # Presupuestos por categoria
│   ├── goals/             # Metas de ahorro
│   ├── reports/           # Graficos y analytics
│   ├── family/            # Gestion familiar compartida
│   └── settings/          # Configuracion y preferencias
├── shared/                # Widgets y providers compartidos
└── main.dart              # Entry point
```

## Convenciones de Codigo (Nivel 3)

### Nombrado
- **Archivos**: snake_case (`transaction_repository.dart`)
- **Clases**: PascalCase (`TransactionRepository`)
- **Variables/funciones**: camelCase (`getMonthlyBalance`)
- **Constantes**: SCREAMING_SNAKE_CASE (`MAX_BUDGET_CATEGORIES`)

### Patrones
- **Repository Pattern**: Abstraccion de fuentes de datos (local/remote)
- **Notifier Pattern**: Riverpod AsyncNotifier para estado reactivo
- **Offline-First**: Guardar local primero, sincronizar despues

### Ejemplo de Feature Structure
```
features/transactions/
├── data/
│   ├── models/
│   │   └── transaction_model.dart      # freezed model
│   ├── repositories/
│   │   └── transaction_repository.dart # CRUD operations
│   └── datasources/
│       ├── transaction_local_ds.dart   # Drift queries
│       └── transaction_remote_ds.dart  # Supabase API
├── domain/
│   └── entities/
│       └── transaction.dart            # Domain entity
├── presentation/
│   ├── providers/
│   │   └── transactions_provider.dart  # Riverpod notifiers
│   ├── screens/
│   │   ├── transactions_screen.dart
│   │   └── transaction_detail_screen.dart
│   └── widgets/
│       ├── transaction_card.dart
│       └── transaction_form.dart
└── transactions.dart                   # Barrel export
```

## Base de Datos (Nivel 4)

### Esquema Drift (Local)
```dart
// Tabla de transacciones
class Transactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get uuid => text().unique()();
  RealColumn get amount => real()();
  TextColumn get description => text().nullable()();
  IntColumn get categoryId => integer().references(Categories, #id)();
  IntColumn get accountId => integer().references(Accounts, #id)();
  DateTimeColumn get date => dateTime()();
  BoolColumn get isIncome => boolean().withDefault(const Constant(false))();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().nullable()();
}
```

### Sincronizacion con Supabase
- Usar campo `synced` para marcar registros pendientes
- Timer cada 5 min para sync automatico
- Sync inmediato cuando hay conexion disponible
- Conflict resolution: Last Write Wins con timestamps

## Seguridad (Nivel 5)

### Encriptacion
- SQLCipher para base de datos local encriptada
- flutter_secure_storage para credenciales
- TLS 1.3 para comunicacion con Supabase

### Autenticacion
- Supabase Auth con email/password
- Biometria (huella/face) con local_auth
- JWT tokens con refresh automatico
- Row Level Security (RLS) en Supabase

### Datos Sensibles
- NUNCA loggear datos financieros
- Ofuscar montos en screenshots (FLAG_SECURE)
- Timeout de sesion configurable

## Testing (Nivel 6)

### Estructura
```
test/
├── unit/                 # Tests de logica pura
│   ├── models/
│   └── repositories/
├── widget/               # Tests de UI
│   └── features/
├── integration/          # Tests end-to-end
│   └── flows/
└── mocks/                # Mocks compartidos
```

### Comandos
```bash
# Unit tests
flutter test

# Con coverage
flutter test --coverage

# Integration tests
flutter test integration_test/
```

## Deployment (Nivel 7)

### Android
```bash
# APK release
flutter build apk --release --target-platform android-arm64

# AAB para Play Store
flutter build appbundle --release
```

### Linux Desktop
```bash
flutter build linux --release
# Output en build/linux/x64/release/bundle/
```

### Variables de Entorno
```bash
# .env (no commitear)
SUPABASE_URL=https://xxx.supabase.co
SUPABASE_ANON_KEY=xxx
ENCRYPTION_KEY=xxx
```

## Comandos Utiles

```bash
# Generar codigo (freezed, drift, riverpod)
dart run build_runner build --delete-conflicting-outputs

# Watch mode
dart run build_runner watch

# Limpiar y regenerar
flutter clean && flutter pub get && dart run build_runner build -d

# Analisis estatico
flutter analyze

# Formatear codigo
dart format lib/ test/
```
