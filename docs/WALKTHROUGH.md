# Walkthrough - Finanzas Familiares AS

Guia paso a paso para desarrolladores que quieran entender y contribuir al proyecto.

## Tabla de Contenidos

1. [Configuracion Inicial](#configuracion-inicial)
2. [Estructura del Proyecto](#estructura-del-proyecto)
3. [Flujo de Datos](#flujo-de-datos)
4. [Agregar una Nueva Feature](#agregar-una-nueva-feature)
5. [Testing](#testing)
6. [Sincronizacion Offline-First](#sincronizacion-offline-first)

---

## Configuracion Inicial

### 1. Clonar y Configurar

```bash
git clone https://github.com/alvaretto/finanzasfamilia.git
cd finanzasfamilia
flutter pub get
dart run build_runner build -d
```

### 2. Configurar Supabase

1. Crear proyecto en [supabase.com](https://supabase.com)
2. Copiar URL y anon key
3. Crear `.env`:

```env
SUPABASE_URL=https://xxx.supabase.co
SUPABASE_ANON_KEY=eyJ...
GEMINI_API_KEY=AIza...
```

### 3. Ejecutar Migraciones SQL

```sql
-- En Supabase SQL Editor
CREATE TABLE accounts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id),
  name TEXT NOT NULL,
  type TEXT NOT NULL,
  currency TEXT DEFAULT 'MXN',
  balance DECIMAL DEFAULT 0,
  -- ... mas campos
);

-- Habilitar RLS
ALTER TABLE accounts ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage own accounts"
  ON accounts FOR ALL
  USING (auth.uid() = user_id);
```

---

## Estructura del Proyecto

### Core Layer

```
lib/core/
├── database/
│   ├── app_database.dart       # Drift database definition
│   └── tables/                 # Drift table definitions
├── network/
│   └── supabase_client.dart    # Singleton con test mode
├── router/
│   └── app_router.dart         # go_router configuration
└── theme/
    └── app_theme.dart          # Material 3 theme
```

### Feature Layer

Cada feature sigue la misma estructura:

```
lib/features/accounts/
├── data/
│   └── repositories/
│       └── account_repository.dart  # CRUD + sync
├── domain/
│   └── models/
│       └── account_model.dart       # freezed model
└── presentation/
    ├── providers/
    │   └── account_provider.dart    # Riverpod notifier
    ├── screens/
    │   └── accounts_screen.dart     # UI principal
    └── widgets/
        └── account_card.dart        # Componentes reutilizables
```

---

## Flujo de Datos

### 1. UI -> Provider -> Repository -> Database

```
AccountsScreen
    |
    v
accountsProvider.createAccount(data)
    |
    v
AccountRepository.createAccount(model)
    |
    v
Drift Database (local)
    |
    v (async, si hay conexion)
Supabase (remote)
```

### 2. Patron Offline-First

```dart
// En account_repository.dart
Future<AccountModel> createAccount(AccountModel account) async {
  // 1. Guardar localmente PRIMERO
  await _db.into(_db.accounts).insert(companion);

  // 2. Marcar como no sincronizado
  return account.copyWith(isSynced: false);

  // 3. La sincronizacion ocurre despues (timer o manual)
}
```

---

## Agregar una Nueva Feature

### Paso 1: Crear Modelo (freezed)

```dart
// lib/features/nueva/domain/models/nueva_model.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'nueva_model.freezed.dart';
part 'nueva_model.g.dart';

@freezed
class NuevaModel with _$NuevaModel {
  const factory NuevaModel({
    required String id,
    required String userId,
    required String nombre,
    @Default(false) bool isSynced,
  }) = _NuevaModel;

  factory NuevaModel.fromJson(Map<String, dynamic> json) =>
      _$NuevaModelFromJson(json);
}
```

### Paso 2: Crear Tabla Drift

```dart
// lib/core/database/tables/nuevas.dart
import 'package:drift/drift.dart';

class Nuevas extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get nombre => text()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
```

### Paso 3: Crear Repository

```dart
// lib/features/nueva/data/repositories/nueva_repository.dart
class NuevaRepository {
  final AppDatabase _db;
  final SupabaseClient? _supabase;

  NuevaRepository() : _db = AppDatabase(),
    _supabase = SupabaseClientProvider.clientOrNull;

  bool get _isOnline => _supabase != null;

  // CRUD methods...
}
```

### Paso 4: Crear Provider

```dart
// lib/features/nueva/presentation/providers/nueva_provider.dart
final nuevasProvider = StateNotifierProvider<NuevasNotifier, NuevasState>((ref) {
  return NuevasNotifier(NuevaRepository());
});
```

### Paso 5: Regenerar Codigo

```bash
dart run build_runner build -d
```

---

## Testing

### Estructura de Tests

```
test/
├── unit/                    # Logica pura
│   └── models/
├── widget/                  # UI components
│   └── features/
├── integration/             # Flujos completos
├── ai_chat/                 # Tests de IA
├── security/                # Seguridad API
├── performance/             # Rendimiento
├── pwa/                     # Offline-first
├── android/                 # Compatibilidad
└── helpers/
    └── test_helpers.dart    # Utilidades compartidas
```

### Escribir un Test

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:finanzas_familiares/core/network/supabase_client.dart';

void main() {
  setUpAll(() {
    SupabaseClientProvider.enableTestMode(); // IMPORTANTE
  });

  tearDownAll(() {
    SupabaseClientProvider.reset();
  });

  test('Mi test', () {
    // Arrange
    final repo = MiRepository();

    // Act
    final result = repo.doSomething();

    // Assert
    expect(result, isNotNull);
  });
}
```

### Ejecutar Tests

```bash
# Todos
flutter test

# Categoria especifica
flutter test test/ai_chat/

# Con coverage
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

---

## Sincronizacion Offline-First

### Estrategia

1. **Escritura local primero**: Todas las operaciones CRUD van a SQLite
2. **Flag isSynced**: Marca registros pendientes de sincronizar
3. **Sync periodico**: Timer cada 5 minutos + al recuperar conexion
4. **Conflict resolution**: Last-Write-Wins con timestamps

### Implementacion

```dart
Future<void> syncWithSupabase(String userId) async {
  if (!_isOnline) return; // Sin conexion, salir

  // 1. Subir locales no sincronizados
  final unsynced = await getUnsyncedItems();
  for (final item in unsynced) {
    await _supabase!.from('tabla').upsert(item.toMap());
    await markAsSynced(item.id);
  }

  // 2. Descargar remotos
  final remote = await _fetchFromSupabase(userId);

  // 3. Merge con conflictos
  for (final r in remote) {
    final local = await getById(r.id);
    if (local == null) {
      await insertFromRemote(r); // Nuevo del servidor
    } else if (local.isSynced) {
      await updateFromRemote(r); // Actualizar desde servidor
    }
    // Si !local.isSynced, priorizar local (ya se subio arriba)
  }
}
```

---

## Comandos de Desarrollo

```bash
# Desarrollo
flutter run                           # Debug mode
flutter run --release                 # Release mode
flutter run -d linux                  # Linux desktop

# Build
flutter build apk --release           # Android APK
flutter build linux --release         # Linux

# Codigo
dart run build_runner build -d        # Generar codigo
dart run build_runner watch           # Watch mode
dart format lib/ test/                # Formatear
flutter analyze                       # Lint

# Tests
flutter test                          # Todos
flutter test --coverage               # Con coverage
```

---

## Tips y Trucos

### 1. Debug de Drift

```dart
// Ver queries SQL generadas
final db = AppDatabase();
db.customSelect('EXPLAIN QUERY PLAN SELECT * FROM accounts').watch();
```

### 2. Mock de Supabase en Tests

```dart
SupabaseClientProvider.enableTestMode();
// Ahora _supabase es null y _isOnline es false
// Los repositorios funcionan solo con SQLite
```

### 3. Hot Reload con Riverpod

Los providers se mantienen durante hot reload. Para forzar re-creacion:

```dart
// En terminal
r // Hot reload
R // Hot restart (reinicia providers)
```

---

**Siguiente**: Ver [USER_MANUAL.md](USER_MANUAL.md) para guia de usuario final.
