import 'package:drift/drift.dart';
import 'accounts_table.dart';

/// Tabla de metas de ahorro
/// Para gamificación del ahorro personal
@DataClassName('SavingsGoalEntry')
class SavingsGoals extends Table {
  /// UUID único de la meta
  TextColumn get id => text()();

  /// Nombre de la meta (ej: "Vacaciones", "iPhone", "Fondo emergencia")
  TextColumn get name => text().withLength(min: 1, max: 100)();

  /// Descripción opcional de la meta
  TextColumn get description => text().nullable()();

  /// Monto objetivo a alcanzar
  RealColumn get targetAmount => real()();

  /// Monto actual acumulado
  RealColumn get currentAmount => real().withDefault(const Constant(0.0))();

  /// Fecha límite para alcanzar la meta (opcional)
  DateTimeColumn get targetDate => dateTime().nullable()();

  /// Cuenta destino donde se acumula el ahorro (opcional)
  TextColumn get accountId => text().nullable().references(Accounts, #id)();

  /// Color del tema para la meta (hex color)
  IntColumn get color => integer().withDefault(const Constant(0xFF4CAF50))();

  /// Icono de la meta (código del icono Material)
  IntColumn get icon => integer().withDefault(const Constant(0xe57f))(); // savings icon

  /// Si la meta está activa
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  /// Si la meta fue completada
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();

  /// Fecha en que se completó la meta
  DateTimeColumn get completedAt => dateTime().nullable()();

  /// Timestamps
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// Tabla de contribuciones a metas de ahorro
/// Vincula transacciones con metas
@DataClassName('SavingsContributionEntry')
class SavingsContributions extends Table {
  /// UUID único de la contribución
  TextColumn get id => text()();

  /// Meta de ahorro asociada
  TextColumn get goalId => text().references(SavingsGoals, #id)();

  /// Monto de la contribución
  RealColumn get amount => real()();

  /// Nota opcional
  TextColumn get note => text().nullable()();

  /// Fecha de la contribución
  DateTimeColumn get date => dateTime()();

  /// Timestamps
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
