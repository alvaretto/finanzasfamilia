import 'package:drift/drift.dart';
import 'accounts_table.dart';

/// Tabla de metas de ahorro
/// Para gamificación del ahorro personal
@DataClassName('SavingsGoalEntry')
class SavingsGoals extends Table {
  /// UUID único de la meta
  TextColumn get id => text()();

  /// ID del usuario propietario (para sincronización con PowerSync)
  TextColumn get userId => text().nullable()();

  /// Nombre de la meta (ej: "Vacaciones", "iPhone", "Fondo emergencia")
  TextColumn get name => text().withLength(min: 1, max: 100)();

  /// Descripción opcional de la meta
  TextColumn get description => text().nullable()();

  /// Monto objetivo a alcanzar
  RealColumn get targetAmount => real()();

  /// Monto actual acumulado - Nullable para compatibilidad con PowerSync
  RealColumn get currentAmount => real().nullable()();

  /// Fecha límite para alcanzar la meta (opcional)
  DateTimeColumn get targetDate => dateTime().nullable()();

  /// Cuenta destino donde se acumula el ahorro (opcional)
  TextColumn get accountId => text().nullable().references(Accounts, #id)();

  /// Color del tema para la meta (hex color) - Nullable para compatibilidad con PowerSync
  IntColumn get color => integer().nullable()();

  /// Icono de la meta (código del icono Material) - Nullable para compatibilidad con PowerSync
  IntColumn get icon => integer().nullable()();

  /// Si la meta está activa - Nullable para compatibilidad con PowerSync
  BoolColumn get isActive => boolean().nullable()();

  /// Si la meta fue completada - Nullable para compatibilidad con PowerSync
  BoolColumn get isCompleted => boolean().nullable()();

  /// Fecha en que se completó la meta
  DateTimeColumn get completedAt => dateTime().nullable()();

  /// Orden global de sincronización (estilo Linear)
  IntColumn get syncSequence => integer().nullable()();

  /// Timestamps - Nullable para compatibilidad con PowerSync
  DateTimeColumn get createdAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Tabla de contribuciones a metas de ahorro
/// Vincula transacciones con metas
@DataClassName('SavingsContributionEntry')
class SavingsContributions extends Table {
  /// UUID único de la contribución
  TextColumn get id => text()();

  /// ID del usuario propietario (para sincronización con PowerSync)
  TextColumn get userId => text().nullable()();

  /// Meta de ahorro asociada
  TextColumn get goalId => text().references(SavingsGoals, #id)();

  /// Monto de la contribución
  RealColumn get amount => real()();

  /// Nota opcional
  TextColumn get note => text().nullable()();

  /// Fecha de la contribución
  DateTimeColumn get date => dateTime()();

  /// Orden global de sincronización (estilo Linear)
  IntColumn get syncSequence => integer().nullable()();

  /// Timestamps - Nullable para compatibilidad con PowerSync
  DateTimeColumn get createdAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
