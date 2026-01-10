import 'package:drift/drift.dart';

/// Roles disponibles para miembros de una familia
enum FamilyMemberRole {
  /// Dueño de la familia (creador). Solo puede haber uno.
  owner,

  /// Administrador con permisos completos (CRUD de transacciones, cuentas, miembros)
  admin,

  /// Miembro estándar (CRUD de transacciones propias, ver cuentas compartidas)
  member,

  /// Solo lectura (dashboard, reportes, sin modificar datos)
  viewer,
}

/// Estados de una invitación familiar
enum FamilyInvitationStatus {
  pending,
  accepted,
  rejected,
  expired,
  cancelled,
}

/// Tabla de familias/grupos
/// Una familia agrupa usuarios que comparten finanzas
@DataClassName('FamilyEntry')
class Families extends Table {
  /// UUID único de la familia
  TextColumn get id => text()();

  /// Nombre de la familia (ej: "Familia García", "Casa Principal")
  TextColumn get name => text().withLength(min: 1, max: 100)();

  /// Descripción opcional
  TextColumn get description => text().nullable()();

  /// Icono emoji o código
  TextColumn get icon => text().withLength(max: 10).nullable()();

  /// Color identificativo (hex)
  TextColumn get color => text().withLength(max: 7).nullable()();

  /// ID del usuario que creó la familia (owner)
  TextColumn get ownerId => text()();

  /// Código de invitación único (para compartir)
  TextColumn get inviteCode => text().withLength(min: 6, max: 12).nullable()();

  /// Si la familia está activa
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  /// Timestamps
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// Tabla de miembros de familia
/// Relaciona usuarios con familias y define sus roles
@DataClassName('FamilyMemberEntry')
class FamilyMembers extends Table {
  /// UUID único del registro
  TextColumn get id => text()();

  /// ID de la familia
  TextColumn get familyId => text().references(Families, #id)();

  /// ID del usuario (de Supabase Auth)
  TextColumn get userId => text()();

  /// Email del usuario (para mostrar en UI)
  TextColumn get userEmail => text().nullable()();

  /// Nombre para mostrar
  TextColumn get displayName => text().nullable()();

  /// Avatar URL
  TextColumn get avatarUrl => text().nullable()();

  /// Rol del miembro: owner, admin, member, viewer
  TextColumn get role => text().withDefault(const Constant('member'))();

  /// Si el miembro está activo en la familia
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  /// Fecha en que se unió
  DateTimeColumn get joinedAt => dateTime().withDefault(currentDateAndTime)();

  /// Timestamps
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// Tabla de invitaciones a familia
/// Gestiona las invitaciones pendientes
@DataClassName('FamilyInvitationEntry')
class FamilyInvitations extends Table {
  /// UUID único de la invitación
  TextColumn get id => text()();

  /// ID de la familia
  TextColumn get familyId => text().references(Families, #id)();

  /// Email del invitado
  TextColumn get invitedEmail => text()();

  /// ID del usuario que invita
  TextColumn get invitedByUserId => text()();

  /// Rol que tendrá al aceptar: admin, member, viewer
  TextColumn get role => text().withDefault(const Constant('member'))();

  /// Estado: pending, accepted, rejected, expired, cancelled
  TextColumn get status => text().withDefault(const Constant('pending'))();

  /// Token único de la invitación (para link de invitación)
  TextColumn get token => text()();

  /// Fecha de expiración de la invitación
  DateTimeColumn get expiresAt => dateTime()();

  /// Mensaje personalizado del invitador
  TextColumn get message => text().nullable()();

  /// Timestamps
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// Tabla de cuentas compartidas en familia
/// Define qué cuentas están disponibles para la familia
@DataClassName('SharedAccountEntry')
class SharedAccounts extends Table {
  /// UUID único
  TextColumn get id => text()();

  /// ID de la familia
  TextColumn get familyId => text().references(Families, #id)();

  /// ID de la cuenta (referencia a Accounts)
  TextColumn get accountId => text()();

  /// ID del dueño original de la cuenta
  TextColumn get ownerUserId => text()();

  /// Si todos los miembros pueden ver el saldo
  BoolColumn get visibleToAll => boolean().withDefault(const Constant(true))();

  /// Si miembros pueden crear transacciones en esta cuenta
  BoolColumn get membersCanTransact =>
      boolean().withDefault(const Constant(false))();

  /// Timestamps
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
