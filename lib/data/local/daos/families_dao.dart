import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/families_table.dart';

part 'families_dao.g.dart';

/// DAO para gestión de familias y miembros
@DriftAccessor(tables: [Families, FamilyMembers, FamilyInvitations, SharedAccounts])
class FamiliesDao extends DatabaseAccessor<AppDatabase>
    with _$FamiliesDaoMixin {
  FamiliesDao(super.db);

  // ==================== FAMILIAS ====================

  /// Obtiene todas las familias activas del usuario
  /// Considera isActive = NULL como activo (valor por defecto)
  Future<List<FamilyEntry>> getFamiliesForUser(String userId) async {
    final query = select(families).join([
      innerJoin(
        familyMembers,
        familyMembers.familyId.equalsExp(families.id),
      ),
    ])
      ..where(familyMembers.userId.equals(userId))
      ..where(familyMembers.isActive.equals(true) | familyMembers.isActive.isNull())
      ..where(families.isActive.equals(true) | families.isActive.isNull());

    final rows = await query.get();
    return rows.map((row) => row.readTable(families)).toList();
  }

  /// Obtiene una familia por ID
  Future<FamilyEntry?> getFamilyById(String id) async {
    return (select(families)..where((f) => f.id.equals(id))).getSingleOrNull();
  }

  /// Crea una nueva familia
  Future<void> createFamily(FamiliesCompanion family) async {
    await into(families).insert(family);
  }

  /// Actualiza una familia existente
  Future<void> updateFamily(FamiliesCompanion family) async {
    await (update(families)..where((f) => f.id.equals(family.id.value)))
        .write(family);
  }

  /// Elimina una familia (soft delete)
  Future<void> deleteFamily(String id) async {
    await (update(families)..where((f) => f.id.equals(id))).write(
      FamiliesCompanion(
        isActive: const Value(false),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Observa las familias del usuario en tiempo real
  /// Considera isActive = NULL como activo (valor por defecto)
  Stream<List<FamilyEntry>> watchFamiliesForUser(String userId) {
    final query = select(families).join([
      innerJoin(
        familyMembers,
        familyMembers.familyId.equalsExp(families.id),
      ),
    ])
      ..where(familyMembers.userId.equals(userId))
      ..where(familyMembers.isActive.equals(true) | familyMembers.isActive.isNull())
      ..where(families.isActive.equals(true) | families.isActive.isNull());

    return query.watch().map(
          (rows) => rows.map((row) => row.readTable(families)).toList(),
        );
  }

  /// Genera un código de invitación único
  Future<String> generateInviteCode(String familyId) async {
    final code = _generateRandomCode(8);
    await (update(families)..where((f) => f.id.equals(familyId))).write(
      FamiliesCompanion(
        inviteCode: Value(code),
        updatedAt: Value(DateTime.now()),
      ),
    );
    return code;
  }

  /// Busca familia por código de invitación
  /// Considera isActive = NULL como activo (valor por defecto)
  Future<FamilyEntry?> getFamilyByInviteCode(String code) async {
    return (select(families)
          ..where((f) => f.inviteCode.equals(code))
          ..where((f) => f.isActive.equals(true) | f.isActive.isNull()))
        .getSingleOrNull();
  }

  // ==================== MIEMBROS ====================

  /// Obtiene los miembros de una familia
  /// Considera isActive = NULL como activo (valor por defecto)
  Future<List<FamilyMemberEntry>> getMembersForFamily(String familyId) async {
    return (select(familyMembers)
          ..where((m) => m.familyId.equals(familyId))
          ..where((m) => m.isActive.equals(true) | m.isActive.isNull())
          ..orderBy([(m) => OrderingTerm.asc(m.joinedAt)]))
        .get();
  }

  /// Obtiene un miembro específico
  Future<FamilyMemberEntry?> getMember(String familyId, String userId) async {
    return (select(familyMembers)
          ..where((m) => m.familyId.equals(familyId))
          ..where((m) => m.userId.equals(userId)))
        .getSingleOrNull();
  }

  /// Agrega un miembro a una familia
  Future<void> addMember(FamilyMembersCompanion member) async {
    await into(familyMembers).insert(member);
  }

  /// Actualiza el rol de un miembro
  Future<void> updateMemberRole(String memberId, FamilyMemberRole role) async {
    await (update(familyMembers)..where((m) => m.id.equals(memberId))).write(
      FamilyMembersCompanion(
        role: Value(role.name),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Elimina un miembro de la familia (soft delete)
  Future<void> removeMember(String memberId) async {
    await (update(familyMembers)..where((m) => m.id.equals(memberId))).write(
      FamilyMembersCompanion(
        isActive: const Value(false),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Verifica si un usuario tiene permisos de admin en la familia
  Future<bool> isAdminOrOwner(String familyId, String userId) async {
    final member = await getMember(familyId, userId);
    if (member == null) return false;
    return member.role == 'owner' || member.role == 'admin';
  }

  /// Cuenta los miembros de una familia
  /// Considera isActive = NULL como activo (valor por defecto)
  Future<int> countMembers(String familyId) async {
    final query = selectOnly(familyMembers)
      ..addColumns([familyMembers.id.count()])
      ..where(familyMembers.familyId.equals(familyId))
      ..where(familyMembers.isActive.equals(true) | familyMembers.isActive.isNull());

    final result = await query.getSingle();
    return result.read(familyMembers.id.count()) ?? 0;
  }

  /// Observa los miembros de una familia
  /// Considera isActive = NULL como activo (valor por defecto)
  Stream<List<FamilyMemberEntry>> watchMembersForFamily(String familyId) {
    return (select(familyMembers)
          ..where((m) => m.familyId.equals(familyId))
          ..where((m) => m.isActive.equals(true) | m.isActive.isNull())
          ..orderBy([(m) => OrderingTerm.asc(m.joinedAt)]))
        .watch();
  }

  // ==================== INVITACIONES ====================

  /// Crea una nueva invitación
  Future<void> createInvitation(FamilyInvitationsCompanion invitation) async {
    await into(familyInvitations).insert(invitation);
  }

  /// Obtiene invitaciones pendientes para un email
  /// Considera status = NULL como 'pending' (valor por defecto)
  Future<List<FamilyInvitationEntry>> getPendingInvitationsForEmail(
    String email,
  ) async {
    return (select(familyInvitations)
          ..where((i) => i.invitedEmail.equals(email.toLowerCase()))
          ..where((i) => i.status.equals('pending') | i.status.isNull())
          ..where((i) => i.expiresAt.isBiggerThanValue(DateTime.now())))
        .get();
  }

  /// Obtiene invitaciones pendientes de una familia
  /// Considera status = NULL como 'pending' (valor por defecto)
  Future<List<FamilyInvitationEntry>> getPendingInvitationsForFamily(
    String familyId,
  ) async {
    return (select(familyInvitations)
          ..where((i) => i.familyId.equals(familyId))
          ..where((i) => i.status.equals('pending') | i.status.isNull()))
        .get();
  }

  /// Obtiene una invitación por token
  /// Considera status = NULL como 'pending' (valor por defecto)
  Future<FamilyInvitationEntry?> getInvitationByToken(String token) async {
    return (select(familyInvitations)
          ..where((i) => i.token.equals(token))
          ..where((i) => i.status.equals('pending') | i.status.isNull())
          ..where((i) => i.expiresAt.isBiggerThanValue(DateTime.now())))
        .getSingleOrNull();
  }

  /// Acepta una invitación
  Future<void> acceptInvitation(String invitationId) async {
    await (update(familyInvitations)..where((i) => i.id.equals(invitationId)))
        .write(
      FamilyInvitationsCompanion(
        status: const Value('accepted'),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Rechaza una invitación
  Future<void> rejectInvitation(String invitationId) async {
    await (update(familyInvitations)..where((i) => i.id.equals(invitationId)))
        .write(
      FamilyInvitationsCompanion(
        status: const Value('rejected'),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Cancela una invitación
  Future<void> cancelInvitation(String invitationId) async {
    await (update(familyInvitations)..where((i) => i.id.equals(invitationId)))
        .write(
      FamilyInvitationsCompanion(
        status: const Value('cancelled'),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  // ==================== CUENTAS COMPARTIDAS ====================

  /// Comparte una cuenta con la familia
  Future<void> shareAccount(SharedAccountsCompanion sharedAccount) async {
    await into(sharedAccounts).insert(sharedAccount);
  }

  /// Obtiene cuentas compartidas de una familia
  Future<List<SharedAccountEntry>> getSharedAccountsForFamily(
    String familyId,
  ) async {
    return (select(sharedAccounts)
          ..where((sa) => sa.familyId.equals(familyId)))
        .get();
  }

  /// Deja de compartir una cuenta
  Future<void> unshareAccount(String sharedAccountId) async {
    await (delete(sharedAccounts)
          ..where((sa) => sa.id.equals(sharedAccountId)))
        .go();
  }

  /// Actualiza permisos de cuenta compartida
  Future<void> updateSharedAccountPermissions(
    String sharedAccountId, {
    bool? visibleToAll,
    bool? membersCanTransact,
  }) async {
    await (update(sharedAccounts)..where((sa) => sa.id.equals(sharedAccountId)))
        .write(
      SharedAccountsCompanion(
        visibleToAll: visibleToAll != null ? Value(visibleToAll) : const Value.absent(),
        membersCanTransact: membersCanTransact != null
            ? Value(membersCanTransact)
            : const Value.absent(),
      ),
    );
  }

  /// Observa cuentas compartidas de una familia
  Stream<List<SharedAccountEntry>> watchSharedAccountsForFamily(
    String familyId,
  ) {
    return (select(sharedAccounts)
          ..where((sa) => sa.familyId.equals(familyId)))
        .watch();
  }

  // ==================== HELPERS ====================

  /// Genera un código aleatorio para invitaciones
  String _generateRandomCode(int length) {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    final buffer = StringBuffer();
    for (var i = 0; i < length; i++) {
      buffer.write(chars[(random + i * 7) % chars.length]);
    }
    return buffer.toString();
  }
}
