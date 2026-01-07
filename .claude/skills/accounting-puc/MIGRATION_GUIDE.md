# Guía de Migración: Arquitectura PUC

## Para Desarrolladores

### Migración Automática v4→v5

La migración se ejecuta automáticamente la primera vez que un usuario abre la app después de actualizar a v1.9.13+.

**Qué sucede**:
1. Se crean las tablas `account_classes` y `account_groups`
2. Se insertan 5 clases contables y 30+ grupos PUC
3. Se agrega la columna `groupId` a la tabla `accounts` (nullable)
4. Se agrega la columna `archived` a la tabla `accounts`
5. Se ejecuta el mapeo automático de `type` → `groupId` para todas las cuentas existentes

**Mapeo type → groupId**:
| type (legacy) | groupId (PUC) | Descripción |
|---------------|---------------|-------------|
| cash          | 1105          | Efectivo → Caja General |
| bank          | 1110          | Banco → Bancos |
| savings       | 1110          | Ahorros → Bancos |
| wallet        | 1105          | Billetera → Caja General |
| credit        | 2105          | Tarjeta → Tarjetas de Crédito |
| investment    | 1200          | Inversión → Inversiones |
| loan          | 2120          | Préstamo → Préstamos Bancarios |
| payable       | 2335          | Cuenta por pagar → Cuentas por Pagar |

**Fallback**: Si un `type` no está en el mapeo, se asigna `groupId = '1105'` (Efectivo).

### Código Afectado

#### Antes (v1.9.12 y anteriores)
```dart
// Crear cuenta usando type
final account = AccountsCompanion.insert(
  id: uuid.v4(),
  userId: userId,
  name: 'Mi cuenta',
  type: 'bank', // ❌ Legacy
  balance: 0.0,
);
```

#### Después (v1.9.13+)
```dart
// Crear cuenta usando groupId
final account = AccountsCompanion.insert(
  id: uuid.v4(),
  userId: userId,
  name: 'Cuenta Bancolombia',
  type: 'bank', // ⚠️ Mantener por compatibilidad temporal
  groupId: Value('1110'), // ✅ Nuevo campo (Bancos)
  balance: 0.0,
);
```

### Adaptar Repositorios

#### AccountRepository

**Antes**:
```dart
Future<Account> createAccount({
  required String name,
  required String type, // cash, bank, credit, etc.
}) async {
  // ...
}
```

**Después**:
```dart
Future<Account> createAccount({
  required String name,
  required String groupId, // "1105", "1110", "2105", etc.
  @Deprecated('Use groupId') String? type,
}) async {
  // Validar que groupId existe
  final group = await (db.select(db.accountGroups)
    ..where((tbl) => tbl.id.equals(groupId)))
    .getSingleOrNull();

  if (group == null) {
    throw Exception('Invalid groupId: $groupId');
  }

  return db.into(db.accounts).insert(AccountsCompanion.insert(
    id: _uuid.v4(),
    userId: userId,
    name: name,
    groupId: Value(groupId),
    type: type ?? _inferTypeFromGroupId(groupId), // Backward compat
  ));
}

/// Helper temporal para compatibilidad con código legacy
String _inferTypeFromGroupId(String groupId) {
  const groupToType = {
    '1105': 'cash',
    '1110': 'bank',
    '1200': 'investment',
    '2105': 'credit',
    '2120': 'loan',
    '2335': 'payable',
  };
  return groupToType[groupId] ?? 'cash';
}
```

#### Queries con JOIN

**Obtener cuentas con información del grupo**:
```dart
Future<List<AccountWithGroup>> getAccountsWithGroups() async {
  final query = db.select(db.accounts).join([
    innerJoin(
      db.accountGroups,
      db.accountGroups.id.equalsExp(db.accounts.groupId),
    ),
  ]);

  final results = await query.get();

  return results.map((row) {
    final account = row.readTable(db.accounts);
    final group = row.readTable(db.accountGroups);
    return AccountWithGroup(account: account, group: group);
  }).toList();
}
```

### Adaptar UI

#### Selector de Tipo de Cuenta

**Antes**: Dropdown con tipos hardcodeados
```dart
DropdownButton<String>(
  items: [
    DropdownMenuItem(value: 'cash', child: Text('Efectivo')),
    DropdownMenuItem(value: 'bank', child: Text('Banco')),
    DropdownMenuItem(value: 'credit', child: Text('Tarjeta de Crédito')),
  ],
  onChanged: (type) => setState(() => _selectedType = type),
);
```

**Después**: Dropdown dinámico desde AccountGroups
```dart
// Obtener grupos de la BD
final groups = await (db.select(db.accountGroups)
  ..orderBy([(tbl) => OrderingTerm(expression: tbl.displayOrder)]))
  .get();

// Dropdown con grupos PUC
DropdownButton<String>(
  items: groups.map((group) {
    return DropdownMenuItem(
      value: group.id, // "1105", "1110", etc.
      child: Row(children: [
        Icon(Icons.fromString(group.icon ?? 'account_balance')),
        SizedBox(width: 8),
        Text(group.friendlyName), // "Efectivo", "Bancos", etc.
      ]),
    );
  }).toList(),
  onChanged: (groupId) => setState(() => _selectedGroupId = groupId),
);
```

#### Filtrar por Clase Contable

**Obtener solo cuentas de Activos (Class 1)**:
```dart
final accountsQuery = db.select(db.accounts).join([
  innerJoin(
    db.accountGroups,
    db.accountGroups.id.equalsExp(db.accounts.groupId),
  ),
])..where(db.accountGroups.classId.equals(1)); // Class 1 = Activos

final activosAccounts = await accountsQuery.get();
```

### Testing

#### Test de Migración

```dart
testWidgets('Migración v4→v5 mapea type a groupId correctamente', (tester) async {
  // 1. Setup: DB en v4 con cuentas usando type
  final db = await AppDatabase.forTest(version: 4);
  await db.into(db.accounts).insert(AccountsCompanion.insert(
    id: 'acc-1',
    userId: 'user-1',
    name: 'Cuenta Banco',
    type: 'bank',
  ));

  // 2. Ejecutar migración a v5
  await db.close();
  final dbV5 = await AppDatabase.forTest(version: 5);

  // 3. Verificar que groupId fue asignado
  final account = await (dbV5.select(dbV5.accounts)
    ..where((tbl) => tbl.id.equals('acc-1')))
    .getSingle();

  expect(account.groupId, '1110'); // type 'bank' → groupId '1110'
  expect(account.type, 'bank'); // type se mantiene por compatibilidad
});
```

#### Test de Integridad

Ver: `test/unit/puc_integrity_test.dart`

```dart
test('AccountGroups tienen FK válido a AccountClasses', () async {
  final db = AppDatabase.instance;
  final groups = await db.select(db.accountGroups).get();

  for (final group in groups) {
    final classExists = await (db.select(db.accountClasses)
      ..where((tbl) => tbl.id.equals(group.classId)))
      .getSingleOrNull();

    expect(classExists, isNotNull,
        reason: 'Group ${group.id} has invalid classId ${group.classId}');
  }
});
```

### Rollback (si es necesario)

Si necesitas revertir a v4:

1. **Downgrade manualmente el schema**:
```sql
-- Eliminar columnas nuevas
ALTER TABLE accounts DROP COLUMN groupId;
ALTER TABLE accounts DROP COLUMN archived;

-- Eliminar tablas PUC
DROP TABLE account_groups;
DROP TABLE account_classes;

-- Actualizar schema version
PRAGMA user_version = 4;
```

2. **Reinstalar versión anterior** del APK

⚠️ **Advertencia**: Esto perderá la información de `groupId` y `archived`.

## Para Usuarios

La migración es **transparente** y **automática**.

**Lo que verán**:
- Sus cuentas existentes mantienen el mismo nombre y balance
- Ahora las cuentas están asociadas a un "Grupo Contable" (ej: "Bancos", "Efectivo")
- Pueden crear nuevas cuentas eligiendo entre 30+ categorías PUC

**No requiere acción manual** del usuario.

## Preguntas Frecuentes

### ¿Qué pasa con cuentas que tienen type desconocido?
Se asignan automáticamente a groupId `'1105'` (Efectivo/Caja General).

### ¿Cuándo se eliminará el campo type?
En la versión 1.10.0 (v6), después de confirmar que todos los usuarios migraron correctamente.

### ¿Puedo crear grupos PUC personalizados?
No. Los grupos PUC son inmutables y están definidos por el estándar colombiano. Los usuarios solo crean **instancias** (Accounts) que referencian grupos.

### ¿Cómo manejo cuentas que no encajan en el PUC?
Usa el grupo más cercano. Por ejemplo:
- Billeteras digitales → `1105` (Caja General)
- Inversiones en cripto → `1200` (Inversiones)
- Préstamos personales → `2380` (Deudas con Personas)

## Próximos Pasos

Después de implementar la migración:

1. ✅ Ejecutar suite completa de tests
2. ✅ Probar en emulador con datos de producción
3. ✅ Validar que cuentas existentes se migran correctamente
4. ✅ Actualizar documentación de API
5. 🔄 Crear tests de regresión para ERR-0007 (si aplica)
6. 🔄 Documentar en CHANGELOG.md

---

**Versión**: 1.9.13
**Schema**: v4 → v5
**Breaking Changes**: No (campo `type` se mantiene temporalmente)
