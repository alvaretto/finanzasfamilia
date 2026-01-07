/// Tablas PUC (Plan Único de Cuentas colombiano)
///
/// Estructura de 2 niveles inmutables:
/// 1. AccountClasses: Clases contables PUC (1-5)
/// 2. AccountGroups: Grupos rígidos del PUC (ej: 1105, 2105)
///
/// La tabla Accounts (nivel 3) está en app_database.dart
library;

import 'package:drift/drift.dart';

/// Nivel 1: Clases Contables PUC (Inmutable, 5 registros fijos)
///
/// Mapeo PUC → UX:
/// - Class 1 (Activo) → "Lo que Tengo"
/// - Class 2 (Pasivo) → "Lo que Debo"
/// - Class 3 (Patrimonio) → "Mis Ahorros Netos"
/// - Class 4 (Ingresos) → "Dinero que Recibo"
/// - Class 5 (Gastos) → "Dinero que Pago"
class AccountClasses extends Table {
  /// ID del PUC: 1, 2, 3, 4, 5
  IntColumn get id => integer()();

  /// Nombre técnico contable (PUC estándar)
  /// Ej: "Activo", "Pasivo", "Patrimonio"
  TextColumn get name => text().withLength(min: 1, max: 50)();

  /// Nombre de presentación en UX
  /// Ej: "Lo que Tengo", "Lo que Debo"
  TextColumn get presentationName => text().withLength(min: 1, max: 100)();

  /// Descripción breve para el usuario
  TextColumn get description => text().nullable()();

  /// Orden de presentación en la UI
  IntColumn get displayOrder => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Nivel 2: Grupos de Cuentas PUC (Contenedores Rígidos)
///
/// Estos son los códigos PUC estándar colombianos (ej: 1105, 2105).
/// Son INMUTABLES y definen la estructura contable del sistema.
class AccountGroups extends Table {
  /// Código PUC (String para soportar códigos como "1105", "2105")
  TextColumn get id => text().withLength(min: 1, max: 10)();

  /// FK a AccountClasses.id
  /// Ej: "1105" → classId = 1 (Activo)
  IntColumn get classId => integer().references(AccountClasses, #id)();

  /// Nombre técnico del grupo según PUC
  /// Ej: "Caja General"
  TextColumn get technicalName => text().withLength(min: 1, max: 100)();

  /// Nombre amigable para usuarios colombianos
  /// Ej: "Efectivo y Bolsillos"
  TextColumn get friendlyName => text().withLength(min: 1, max: 100)();

  /// Naturaleza contable: 'DEBIT' o 'CREDIT'
  TextColumn get nature => textEnum<AccountNature>()();

  /// ¿Es cuenta del sistema? (siempre true para PUC)
  BoolColumn get isFixed => boolean().withDefault(const Constant(true))();

  /// Tipo de gasto (solo para Class 5)
  /// 'FIXED' = Gastos Fijos (Obligatorios)
  /// 'VARIABLE' = Gastos Variables (Estilo de Vida)
  /// null = No aplica (otras clases)
  TextColumn get expenseType => textEnum<ExpenseType>().nullable()();

  /// Icono sugerido para la UI
  TextColumn get icon => text().nullable()();

  /// Color sugerido (hex)
  TextColumn get color => text().nullable()();

  /// Orden de presentación en la UI
  IntColumn get displayOrder => integer()();

  /// Fecha de creación del registro
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// Enum: Naturaleza contable
enum AccountNature {
  /// Naturaleza deudora (aumenta con débito)
  DEBIT,

  /// Naturaleza acreedora (aumenta con crédito)
  CREDIT,
}

/// Enum: Tipo de gasto (solo para Class 5)
enum ExpenseType {
  /// Gastos fijos/obligatorios (arriendo, servicios, seguros)
  FIXED,

  /// Gastos variables/estilo de vida (entretenimiento, ropa)
  VARIABLE,
}
