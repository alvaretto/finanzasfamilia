# Skill: Accounting PUC (Plan Único de Cuentas)

**Descripción**: Arquitectura contable basada en el Plan Único de Cuentas (PUC) colombiano con Domain-Driven Design (DDD).

**Cuándo usar**:
- Al crear/modificar cuentas financieras
- Al implementar lógica contable
- Al diseñar features relacionadas con balance/patrimonio
- Al necesitar estructura rígida pero flexible para cuentas

## Arquitectura de 3 Niveles

### Nivel 1: AccountClasses (Clases Contables PUC)
**INMUTABLES** - 5 registros fijos del sistema

```dart
// lib/core/database/tables/account_puc_tables.dart
class AccountClasses {
  IntColumn get id; // 1-5
  TextColumn get name; // "Activo", "Pasivo", etc.
  TextColumn get presentationName; // "Lo que Tengo", etc.
}
```

| ID | Nombre Técnico | Nombre UX | Descripción |
|----|----------------|-----------|-------------|
| 1  | Activo         | Lo que Tengo | Bienes y derechos |
| 2  | Pasivo         | Lo que Debo | Obligaciones y deudas |
| 3  | Patrimonio     | Mis Ahorros Netos | Riqueza real |
| 4  | Ingresos       | Dinero que Recibo | Todo lo que entra |
| 5  | Gastos         | Dinero que Pago | Todo lo que sale |

### Nivel 2: AccountGroups (Grupos PUC)
**INMUTABLES** - Códigos estándar PUC colombiano

```dart
class AccountGroups {
  TextColumn get id; // "1105", "2105", etc. (PUC code)
  IntColumn get classId; // FK a AccountClasses
  TextColumn get technicalName; // "Caja General"
  TextColumn get friendlyName; // "Efectivo y Bolsillos"
  TextColumn get nature; // DEBIT | CREDIT
  TextColumn get expenseType; // FIXED | VARIABLE (solo Class 5)
}
```

**Ejemplos de grupos PUC**:
```
CLASS 1 - ACTIVOS
  1105 = Caja General → "Efectivo y Bolsillos"
  1110 = Bancos → "Bancos / Nequi / Daviplata"
  1200 = Inversiones → "Inversiones (CDT, Acciones)"
  1524 = Equipos → "Computadores y Equipos"
  1540 = Vehículos → "Vehículos (Carro, Moto)"
  1516 = Propiedades → "Casas y Propiedades"

CLASS 2 - PASIVOS
  2105 = Tarjetas de Crédito
  2120 = Préstamos Bancarios
  2335 = Cuentas por Pagar
  2380 = Deudas con Personas

CLASS 5 - GASTOS
  FIXED (5100-5299):
    5100 = Vivienda
    5135 = Servicios Públicos
    5160 = Seguros

  VARIABLE (5300-5599):
    5300 = Ventas
    5400 = Gastos Personales
    5405 = Intereses
```

### Nivel 3: Accounts (Instancias del Usuario)
**FLEXIBLES** - Creadas por usuarios

```dart
class Accounts {
  TextColumn get id; // UUID
  TextColumn get userId;
  TextColumn get groupId; // FK a AccountGroups (RESTRICT)
  TextColumn get name; // ✅ Usuario puede editar
  TextColumn get type; // DEPRECATED - migrar a groupId
  RealColumn get balance;
  BoolColumn get archived;
}
```

**Reglas de negocio**:
- ✅ Usuario puede editar: `name`, `balance`, `color`, `icon`, `archived`
- ❌ Usuario NO puede editar: `groupId` (FK constraint RESTRICT)
- Si intenta cambiar groupId → crear nueva cuenta con groupId diferente

## Migración type → groupId

La app soporta el campo legacy `type` durante un período de transición:

```dart
// Mapeo automático en migración v4→v5
final typeToGroupId = {
  'cash': '1105',     // Efectivo → Caja General
  'bank': '1110',     // Banco → Bancos
  'savings': '1110',  // Ahorros → Bancos
  'wallet': '1105',   // Billetera → Caja General
  'credit': '2105',   // Tarjeta → Tarjetas de Crédito
  'investment': '1200', // Inversión → Inversiones
  'loan': '2120',     // Préstamo → Préstamos Bancarios
  'payable': '2335',  // Cuenta por pagar → Cuentas por Pagar
};
```

## Naturaleza Contable

| Nature | Descripción | Aumenta con | Ejemplos |
|--------|-------------|-------------|----------|
| DEBIT  | Deudora     | Débito (cargo) | Efectivo, Bancos, Equipos |
| CREDIT | Acreedora   | Crédito (abono) | Pasivos, Patrimonio, Ingresos |

## Tipo de Gasto (ExpenseType)

Solo aplica para Class 5 (Gastos):

| Type     | Códigos PUC | Descripción | Ejemplos |
|----------|-------------|-------------|----------|
| FIXED    | 5100-5299   | Gastos obligatorios | Arriendo, servicios, seguros |
| VARIABLE | 5300-5599   | Gastos discrecionales | Entretenimiento, viajes, ropa |

## Seed Data

**Archivo**: `lib/core/constants/puc_seed_data.dart`

Contiene:
- 5 `AccountClassSeed` (clases contables)
- 30+ `AccountGroupSeed` (grupos PUC colombianos)

**Inserción automática**: Se ejecuta en `onCreate` y en migración v4→v5

## Migración de Base de Datos

**Schema Version**: 5 (incrementado desde v4)

**Cambios en v4→v5**:
1. Crear tablas `account_classes` y `account_groups`
2. Insertar seed data PUC
3. Agregar columna `groupId` nullable a `accounts`
4. Agregar columna `archived` a `accounts`
5. Migrar datos existentes: `type` → `groupId`

**Código clave**:
```dart
// lib/core/database/app_database.dart:318-332
if (from < 5) {
  await m.createTable(accountClasses);
  await m.createTable(accountGroups);
  await _insertPUCSeedData();
  await m.addColumn(accounts, accounts.groupId);
  await m.addColumn(accounts, accounts.archived);
  await _migrateAccountTypeToGroupId();
}
```

## Queries Recomendados

### Obtener grupos por clase
```dart
final gruposActivos = await (select(accountGroups)
  ..where((tbl) => tbl.classId.equals(1))) // Class 1 = Activos
  .get();
```

### Obtener cuentas de usuario con join
```dart
final cuentasConGrupo = await (select(accounts).join([
  innerJoin(accountGroups, accountGroups.id.equalsExp(accounts.groupId)),
  innerJoin(accountClasses, accountClasses.id.equalsExp(accountGroups.classId)),
])).get();
```

### Filtrar gastos fijos vs variables
```dart
final gastosFijos = await (select(accountGroups)
  ..where((tbl) => tbl.expenseType.equals('FIXED')))
  .get();
```

## Validaciones

### Al crear cuenta
```dart
// 1. Verificar que groupId existe en AccountGroups
final groupExists = await (select(accountGroups)
  ..where((tbl) => tbl.id.equals(groupId)))
  .getSingleOrNull();

if (groupExists == null) {
  throw Exception('Invalid groupId: $groupId');
}

// 2. No permitir duplicados (userId + groupId + name)
// Esto está garantizado por uniqueKeys en Accounts table
```

### Al editar cuenta
```dart
// ❌ NO permitir cambiar groupId
if (oldAccount.groupId != newAccount.groupId) {
  throw Exception('Cannot change groupId. Create new account instead.');
}
```

## Tests Requeridos

Ver: `test/unit/puc_integrity_test.dart`

1. **Integridad de seed data**
   - Verificar que existen exactamente 5 AccountClasses
   - Verificar que todos los AccountGroups tienen classId válido
   - Verificar que no hay groupId duplicados

2. **FK constraints**
   - No se puede crear Account con groupId inválido
   - No se puede eliminar AccountGroup si hay Accounts referenciándolo

3. **Migración type→groupId**
   - Verificar mapeo correcto para cada tipo
   - Verificar fallback a '1105' si type no reconocido

4. **Naturaleza contable**
   - Activos (Class 1) son DEBIT
   - Pasivos (Class 2) son CREDIT
   - Gastos (Class 5) son DEBIT

## Próximas Mejoras (v6+)

1. **Eliminar campo `type` legacy** (después de período de transición)
2. **Agregar subcuentas PUC** (ej: 110505, 110510)
3. **Soporte multi-PUC** (otros países latinoamericanos)
4. **Validación contable**: Balance sheet debe cuadrar (Activos = Pasivos + Patrimonio)

## Referencias

- Seed data: `lib/core/constants/puc_seed_data.dart`
- Tablas: `lib/core/database/tables/account_puc_tables.dart`
- Migración: `lib/core/database/app_database.dart:318-332`
- Tests: `test/unit/puc_integrity_test.dart`

## Detección Automática

**Hooks recomendados** (agregar a `.claude/hooks/`):
```bash
# pre-account-create.sh
# Validar que groupId existe antes de crear cuenta

# post-db-migrate.sh
# Ejecutar tests de integridad PUC después de migraciones
```

## Comandos Útiles

```bash
# Ver estructura de tablas PUC
sqlite3 finanzas_familiares.db "SELECT * FROM account_classes;"
sqlite3 finanzas_familiares.db "SELECT * FROM account_groups WHERE classId = 5;"

# Ver cuentas migradas
sqlite3 finanzas_familiares.db "SELECT name, type, groupId FROM accounts;"
```

---

**Versión**: 1.9.13
**Última actualización**: 2026-01-07
**Schema Version**: 5
