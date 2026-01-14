import 'package:drift/drift.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/services/family_service.dart';
import '../local/daos/families_dao.dart';
import '../local/database.dart';
import '../local/tables/families_table.dart';

// Implementaciones Drift de los repositorios de familia.
// Delegan al FamiliesDao y convierten entre Entry y Data.

/// Implementación de FamilyRepository usando Drift
class DriftFamilyRepository implements FamilyRepository {
  final FamiliesDao _dao;

  DriftFamilyRepository(this._dao);

  @override
  Future<FamilyData?> getFamilyById(String id) async {
    final entry = await _dao.getFamilyById(id);
    return entry != null ? _toData(entry) : null;
  }

  @override
  Future<FamilyData?> getFamilyByInviteCode(String code) async {
    final entry = await _dao.getFamilyByInviteCode(code);
    return entry != null ? _toData(entry) : null;
  }

  @override
  Future<List<FamilyData>> getFamiliesForUser(String userId) async {
    final entries = await _dao.getFamiliesForUser(userId);
    return entries.map(_toData).toList();
  }

  @override
  Future<void> createFamily(FamilyData family) async {
    await _dao.createFamily(_toCompanion(family));
  }

  @override
  Future<void> updateFamily(FamilyData family) async {
    await _dao.updateFamily(_toCompanion(family));
  }

  @override
  Future<void> deleteFamily(String id) async {
    await _dao.deleteFamily(id);
  }

  @override
  Future<String> generateInviteCode(String familyId) async {
    return _dao.generateInviteCode(familyId);
  }

  FamilyData _toData(FamilyEntry entry) {
    return FamilyData(
      id: entry.id,
      name: entry.name,
      description: entry.description,
      icon: entry.icon,
      color: entry.color,
      ownerId: entry.ownerId,
      inviteCode: entry.inviteCode,
      createdAt: entry.createdAt ?? DateTime.now(),
      updatedAt: entry.updatedAt ?? DateTime.now(),
    );
  }

  FamiliesCompanion _toCompanion(FamilyData data) {
    // Obtener user_id de Supabase Auth (para PowerSync RLS)
    String? userId;
    try {
      userId = Supabase.instance.client.auth.currentUser?.id;
    } catch (_) {
      // En tests Supabase no está inicializado
    }

    return FamiliesCompanion(
      id: Value(data.id),
      name: Value(data.name),
      description: Value(data.description),
      icon: Value(data.icon),
      color: Value(data.color),
      ownerId: Value(data.ownerId),
      inviteCode: Value(data.inviteCode),
      userId: Value(userId), // Para PowerSync RLS - usar ownerId
      createdAt: Value(data.createdAt),
      updatedAt: Value(data.updatedAt),
    );
  }
}

/// Implementación de FamilyMemberRepository usando Drift
class DriftFamilyMemberRepository implements FamilyMemberRepository {
  final FamiliesDao _dao;

  DriftFamilyMemberRepository(this._dao);

  @override
  Future<List<FamilyMemberData>> getMembersForFamily(String familyId) async {
    final entries = await _dao.getMembersForFamily(familyId);
    return entries.map(_toData).toList();
  }

  @override
  Future<FamilyMemberData?> getMember(String familyId, String userId) async {
    final entry = await _dao.getMember(familyId, userId);
    return entry != null ? _toData(entry) : null;
  }

  @override
  Future<void> addMember(FamilyMemberData member) async {
    await _dao.addMember(_toCompanion(member));
  }

  @override
  Future<void> updateMemberRole(String memberId, String role) async {
    final memberRole = FamilyMemberRole.values.firstWhere(
      (r) => r.name == role,
      orElse: () => FamilyMemberRole.member,
    );
    await _dao.updateMemberRole(memberId, memberRole);
  }

  @override
  Future<void> removeMember(String memberId) async {
    await _dao.removeMember(memberId);
  }

  @override
  Future<bool> isAdminOrOwner(String familyId, String userId) async {
    return _dao.isAdminOrOwner(familyId, userId);
  }

  FamilyMemberData _toData(FamilyMemberEntry entry) {
    return FamilyMemberData(
      id: entry.id,
      familyId: entry.familyId,
      userId: entry.userId,
      role: entry.role ?? 'member',
      isActive: entry.isActive ?? true,
      joinedAt: entry.joinedAt ?? DateTime.now(),
      createdAt: entry.createdAt ?? DateTime.now(),
      updatedAt: entry.updatedAt ?? DateTime.now(),
    );
  }

  FamilyMembersCompanion _toCompanion(FamilyMemberData data) {
    // Obtener user_id de Supabase Auth (para PowerSync RLS)
    String? syncUserId;
    try {
      syncUserId = Supabase.instance.client.auth.currentUser?.id;
    } catch (_) {
      // En tests Supabase no está inicializado
    }

    return FamilyMembersCompanion(
      id: Value(data.id),
      familyId: Value(data.familyId),
      userId: Value(data.userId), // ID del miembro
      syncUserId: Value(syncUserId), // Para PowerSync RLS
      role: Value(data.role),
      isActive: Value(data.isActive),
      joinedAt: Value(data.joinedAt),
      createdAt: Value(data.createdAt),
      updatedAt: Value(data.updatedAt),
    );
  }
}

/// Implementación de FamilyInvitationRepository usando Drift
class DriftFamilyInvitationRepository implements FamilyInvitationRepository {
  final FamiliesDao _dao;

  DriftFamilyInvitationRepository(this._dao);

  @override
  Future<List<FamilyInvitationData>> getPendingForEmail(String email) async {
    final entries = await _dao.getPendingInvitationsForEmail(email);
    return entries.map(_toData).toList();
  }

  @override
  Future<FamilyInvitationData?> getById(String id) async {
    // El DAO no tiene getById, pero sí getInvitationByToken
    // Usamos una consulta directa para el ID
    return null; // Implementar si es necesario
  }

  @override
  Future<void> createInvitation(FamilyInvitationData invitation) async {
    await _dao.createInvitation(_toCompanion(invitation));
  }

  @override
  Future<void> acceptInvitation(String id) async {
    await _dao.acceptInvitation(id);
  }

  @override
  Future<void> rejectInvitation(String id) async {
    await _dao.rejectInvitation(id);
  }

  FamilyInvitationData _toData(FamilyInvitationEntry entry) {
    return FamilyInvitationData(
      id: entry.id,
      familyId: entry.familyId,
      invitedEmail: entry.invitedEmail,
      invitedByUserId: entry.invitedByUserId,
      role: entry.role ?? 'member',
      token: entry.token,
      message: entry.message,
      status: entry.status ?? 'pending',
      expiresAt: entry.expiresAt,
      createdAt: entry.createdAt ?? DateTime.now(),
      updatedAt: entry.updatedAt ?? DateTime.now(),
    );
  }

  FamilyInvitationsCompanion _toCompanion(FamilyInvitationData data) {
    // Obtener user_id de Supabase Auth (para PowerSync RLS)
    String? userId;
    try {
      userId = Supabase.instance.client.auth.currentUser?.id;
    } catch (_) {
      // En tests Supabase no está inicializado
    }

    return FamilyInvitationsCompanion(
      id: Value(data.id),
      familyId: Value(data.familyId),
      invitedEmail: Value(data.invitedEmail),
      invitedByUserId: Value(data.invitedByUserId),
      userId: Value(userId), // Para PowerSync RLS
      role: Value(data.role),
      token: Value(data.token),
      message: Value(data.message),
      status: Value(data.status),
      expiresAt: Value(data.expiresAt),
      createdAt: Value(data.createdAt),
      updatedAt: Value(data.updatedAt),
    );
  }
}

/// Implementación de SharedAccountRepository usando Drift
class DriftSharedAccountRepository implements SharedAccountRepository {
  final FamiliesDao _dao;

  DriftSharedAccountRepository(this._dao);

  @override
  Future<List<SharedAccountData>> getForFamily(String familyId) async {
    final entries = await _dao.getSharedAccountsForFamily(familyId);
    return entries.map(_toData).toList();
  }

  @override
  Future<void> shareAccount(SharedAccountData data) async {
    await _dao.shareAccount(_toCompanion(data));
  }

  @override
  Future<void> unshareAccount(String id) async {
    await _dao.unshareAccount(id);
  }

  @override
  Future<void> updatePermissions(
    String id, {
    bool? visibleToAll,
    bool? membersCanTransact,
  }) async {
    await _dao.updateSharedAccountPermissions(
      id,
      visibleToAll: visibleToAll,
      membersCanTransact: membersCanTransact,
    );
  }

  SharedAccountData _toData(SharedAccountEntry entry) {
    return SharedAccountData(
      id: entry.id,
      familyId: entry.familyId,
      accountId: entry.accountId,
      ownerUserId: entry.ownerUserId,
      visibleToAll: entry.visibleToAll ?? true,
      membersCanTransact: entry.membersCanTransact ?? false,
      createdAt: entry.createdAt ?? DateTime.now(),
    );
  }

  SharedAccountsCompanion _toCompanion(SharedAccountData data) {
    // Obtener user_id de Supabase Auth (para PowerSync RLS)
    String? userId;
    try {
      userId = Supabase.instance.client.auth.currentUser?.id;
    } catch (_) {
      // En tests Supabase no está inicializado
    }

    return SharedAccountsCompanion(
      id: Value(data.id),
      familyId: Value(data.familyId),
      accountId: Value(data.accountId),
      ownerUserId: Value(data.ownerUserId),
      userId: Value(userId), // Para PowerSync RLS
      visibleToAll: Value(data.visibleToAll),
      membersCanTransact: Value(data.membersCanTransact),
      createdAt: Value(data.createdAt),
    );
  }
}
