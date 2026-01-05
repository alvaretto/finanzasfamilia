# Walkthrough - Finanzas Familiares AS

Guia paso a paso para desarrolladores que quieran entender y contribuir al proyecto.

## Tabla de Contenidos

1. [Configuracion Inicial](#configuracion-inicial)
2. [Estructura del Proyecto](#estructura-del-proyecto)
3. [Flujo de Datos](#flujo-de-datos)
4. [Agregar una Nueva Feature](#agregar-una-nueva-feature)
5. [Testing](#testing)
6. [Sincronizacion Offline-First](#sincronizacion-offline-first)
7. [Error Tracking](#error-tracking)
8. [Claude Code Integration](#claude-code-integration)

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
├── regression/              # Tests generados de errores
└── helpers/
    └── test_helpers.dart    # Utilidades compartidas
```

### Escribir un Test con Drift In-Memory

```dart
import 'package:flutter_test/flutter_test.dart';
import '../helpers/test_helpers.dart';

void main() {
  late AppDatabase testDb;
  late MiRepository repo;

  setUpAll(() {
    setupFullTestEnvironment(); // Bindings + path_provider mock + Supabase test mode
  });

  setUp(() {
    testDb = createTestDatabase(); // In-memory database
    repo = MiRepository(database: testDb);
  });

  tearDown(() async {
    await testDb.close();
  });

  tearDownAll(() {
    SupabaseClientProvider.reset();
  });

  test('Mi test con base de datos', () async {
    // Arrange - la db ya esta lista

    // Act
    final result = await repo.create(miModelo);

    // Assert
    expect(result, isNotNull);
    expect(result.isSynced, false); // Offline-first
  });
}
```

### Test Helpers Disponibles

```dart
// test/helpers/test_helpers.dart

// Setup completo
setupFullTestEnvironment(); // Bindings + PathProvider mock + Supabase

// Base de datos in-memory
createTestDatabase(); // AppDatabase con NativeDatabase.memory()

// Widgets de test
createTestApp(child: widget); // Con GoRouter
createSimpleTestApp(child: widget); // Sin GoRouter
TestMainScaffold(child: widget); // Scaffold simplificado
```

### Ejecutar Tests

```bash
# Todos
flutter test

# Categoria especifica
flutter test test/ai_chat/

# Tests de regresion (generados del error tracker)
flutter test test/regression/

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

## Error Tracking

Sistema de documentacion acumulativa de errores para evitar regresiones.

### Estructura

```
.error-tracker/
├── errors/              # JSONs individuales (ERR-XXXX.json)
├── scripts/             # Scripts Python de gestion
│   ├── add_error.py     # Agregar/actualizar errores
│   ├── search_errors.py # Buscar errores similares
│   ├── detect_recurrence.py # Detectar errores recurrentes
│   ├── mark_failed.py   # Marcar solucion fallida
│   ├── generate_test.py # Generar test de regresion
│   └── rebuild_index.py # Regenerar indice
├── patterns.json        # Patrones de deteccion
├── anti-patterns.json   # Soluciones que NO funcionan
└── index.md             # Indice auto-generado
```

### Workflow al Corregir Errores

```bash
# 1. ANTES de implementar, buscar errores similares
python .error-tracker/scripts/search_errors.py "RLS policy recursion"

# 2. Revisar anti-patrones si hay resultados
# 3. Implementar la solucion

# 4. Documentar el error corregido
python .error-tracker/scripts/add_error.py
# Sigue el prompt interactivo:
#   - Titulo breve
#   - Descripcion detallada
#   - Severidad
#   - Archivos afectados
#   - Tags

# 5. Generar test de regresion
python .error-tracker/scripts/generate_test.py ERR-0001
# Genera: test/regression/{tipo}/{feature}/err_0001_regression_test.dart

# 6. Completar el test generado (tiene TODOs)
code test/regression/unit/err_0001_regression_test.dart

# 7. Ejecutar para verificar
flutter test test/regression/
```

### Cuando una Solucion Falla

```bash
# 1. Marcar como fallida
python .error-tracker/scripts/mark_failed.py ERR-0001 "Causa timeout en sync"

# Esto automaticamente:
# - Mueve la solucion a anti-patterns del error
# - Actualiza anti-patterns.json global
# - Cambia estado a "reopened"
# - Regenera index.md

# 2. Buscar nueva solucion (revisar anti-patrones primero)
cat .error-tracker/errors/ERR-0001.json | jq '.anti_patterns'

# 3. Implementar y documentar nueva solucion
python .error-tracker/scripts/add_error.py --update ERR-0001
```

### Deteccion de Errores Recurrentes

```bash
# Al encontrar un error, verificar si ya existe
python .error-tracker/scripts/detect_recurrence.py "infinite recursion in policy"

# Si encuentra similares, muestra:
# - ID y titulo del error
# - Porcentaje de similitud
# - Solucion si existe
# - Anti-patrones (lo que NO hacer)
```

### Esquema JSON de Error

```json
{
  "id": "ERR-0001",
  "title": "RLS Recursion en family_members",
  "severity": "high",
  "status": "resolved",
  "error_details": {
    "message": "infinite recursion detected in policy",
    "error_type": "database"
  },
  "context": {
    "affected_files": [{"path": "lib/.../provider.dart"}]
  },
  "solution": {
    "summary": "Usar funcion helper con SECURITY DEFINER",
    "root_cause": "Policy referenciaba a si misma"
  },
  "anti_patterns": [
    {
      "attempted_solution": "SECURITY DEFINER sin materializar",
      "why_failed": "Causa recursion infinita"
    }
  ],
  "metadata": {
    "tags": ["supabase", "rls", "database"]
  }
}
```

Ver [ERROR_TRACKER_GUIDE.md](ERROR_TRACKER_GUIDE.md) para documentacion completa.

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
flutter test test/regression/         # Solo regresion
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

### 4. Buscar Errores Antes de Corregir

```bash
# Siempre buscar si el error ya fue documentado
python .error-tracker/scripts/search_errors.py "descripcion"
# Evita repetir soluciones que no funcionaron
```

---

## Claude Code Integration

Este proyecto incluye configuracion completa para desarrollo con Claude Code.

### Estructura .claude/

```
.claude/
├── README.md           # Documentacion Progressive Disclosure
├── commands/           # 11 comandos slash
│   ├── build-apk.md
│   ├── run-tests.md
│   ├── full-workflow.md
│   └── ...
├── skills/             # 6 dominios de conocimiento
│   ├── sync-management/
│   ├── financial-analysis/
│   ├── flutter-architecture/
│   ├── testing/
│   ├── data-testing/
│   └── error-tracker/    # Documentacion de errores
└── hooks/              # Automatizaciones
```

### Comandos Disponibles

| Comando | Descripcion |
|---------|-------------|
| `/build-apk` | Construir APK release |
| `/run-tests` | Ejecutar suite de tests |
| `/full-workflow` | Workflow completo (docs, tests, build, git, deploy) |
| `/quick-test` | Tests rapidos (unit + widget) |
| `/sync-check` | Verificar sync offline-first |

### Workflow Automatizado

```bash
# Ejecutar ciclo completo
/full-workflow

# Esto hace automaticamente:
# 1. Actualizar documentacion
# 2. Ejecutar tests
# 3. Build APK
# 4. Git commit detallado
# 5. Git push
# 6. Deploy a emulador
```

### Skill de Error Tracking

Claude Code activa automaticamente el skill `error-tracker` cuando mencionas:
- "error", "bug", "fix"
- "solucion", "corregir"
- "falla", "no funciona", "reaparece"

Ver [CLAUDE_WORKFLOW.md](CLAUDE_WORKFLOW.md) para diagramas Mermaid detallados.

---

**Version**: 1.9.8
**Ultima actualizacion**: 2026-01-05

**Siguiente**: Ver [USER_MANUAL.md](USER_MANUAL.md) para guia de usuario final.
