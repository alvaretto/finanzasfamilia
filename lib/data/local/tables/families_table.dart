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

  /// Icono emoji o código (máx 50 para emojis compuestos como '👨‍👩‍👧‍👦')
  TextColumn get icon => text().withLength(max: 50).nullable()();

  /// Color identificativo (hex)
  TextColumn get color => text().withLength(max: 7).nullable()();

  /// ID del usuario que creó la familia (owner)
  TextColumn get ownerId => text()();

  /// Código de invitación único (para compartir)
  TextColumn get inviteCode => text().withLength(min: 6, max: 12).nullable()();

  /// ID del usuario autenticado (para sincronización PowerSync con RLS)
  TextColumn get userId => text().nullable()();

  /// Si la familia está activa - Nullable para compatibilidad con PowerSync
  BoolColumn get isActive => boolean().nullable()();

  /// Orden global de sincronización (estilo Linear)
  IntColumn get syncSequence => integer().nullable()();

  /// Timestamps - Nullable para compatibilidad con PowerSync
  DateTimeColumn get createdAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime().nullable()();

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

  /// Rol del miembro: owner, admin, member, viewer - Nullable para compatibilidad con PowerSync
  TextColumn get role => text().nullable()();

  /// ID del usuario autenticado (para sincronización PowerSync con RLS)
  /// NOTA: Este campo es DIFERENTE de userId (que identifica al miembro).
  /// Este campo se usa para RLS y debe apuntar al auth.users actual.
  TextColumn get syncUserId => text().nullable()();

  /// Si el miembro está activo en la familia - Nullable para compatibilidad con PowerSync
  BoolColumn get isActive => boolean().nullable()();

  /// Fecha en que se unió - Nullable para compatibilidad con PowerSync
  DateTimeColumn get joinedAt => dateTime().nullable()();

  /// Orden global de sincronización (estilo Linear)
  IntColumn get syncSequence => integer().nullable()();

  /// Timestamps - Nullable para compatibilidad con PowerSync
  DateTimeColumn get createdAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime().nullable()();

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

  /// Rol que tendrá al aceptar: admin, member, viewer - Nullable para compatibilidad con PowerSync
  TextColumn get role => text().nullable()();

  /// Estado: pending, accepted, rejected, expired, cancelled - Nullable para compatibilidad con PowerSync
  TextColumn get status => text().nullable()();

  /// Token único de la invitación (para link de invitación)
  TextColumn get token => text()();

  /// ID del usuario autenticado (para sincronización PowerSync con RLS)
  TextColumn get userId => text().nullable()();

  /// Fecha de expiración de la invitación
  DateTimeColumn get expiresAt => dateTime()();

  /// Mensaje personalizado del invitador
  TextColumn get message => text().nullable()();

  /// Timestamps - Nullable para compatibilidad con PowerSync
  DateTimeColumn get createdAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime().nullable()();

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

  /// ID del usuario autenticado (para sincronización PowerSync con RLS)
  TextColumn get userId => text().nullable()();

  /// Si todos los miembros pueden ver el saldo - Nullable para compatibilidad con PowerSync
  BoolColumn get visibleToAll => boolean().nullable()();

  /// Si miembros pueden crear transacciones en esta cuenta - Nullable para compatibilidad con PowerSync
  BoolColumn get membersCanTransact => boolean().nullable()();

  /// Timestamps - Nullable para compatibilidad con PowerSync
  DateTimeColumn get createdAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
