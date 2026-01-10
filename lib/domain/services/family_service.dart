// FamilyService - Lógica de negocio para gestión de familias
// Extraído de family_provider.dart (FASE R6)

import 'package:uuid/uuid.dart';

/// Interfaz de repositorio para familias (independiente de Drift)
abstract class FamilyRepository {
  Future<FamilyData?> getFamilyById(String id);
  Future<FamilyData?> getFamilyByInviteCode(String code);
  Future<List<FamilyData>> getFamiliesForUser(String userId);
  Future<void> createFamily(FamilyData family);
  Future<void> updateFamily(FamilyData family);
  Future<void> deleteFamily(String id);
  Future<String> generateInviteCode(String familyId);
}

/// Interfaz de repositorio para miembros de familia
abstract class FamilyMemberRepository {
  Future<List<FamilyMemberData>> getMembersForFamily(String familyId);
  Future<FamilyMemberData?> getMember(String familyId, String userId);
  Future<void> addMember(FamilyMemberData member);
  Future<void> updateMemberRole(String memberId, String role);
  Future<void> removeMember(String memberId);
  Future<bool> isAdminOrOwner(String familyId, String userId);
}

/// Interfaz de repositorio para invitaciones
abstract class FamilyInvitationRepository {
  Future<List<FamilyInvitationData>> getPendingForEmail(String email);
  Future<FamilyInvitationData?> getById(String id);
  Future<void> createInvitation(FamilyInvitationData invitation);
  Future<void> acceptInvitation(String id);
  Future<void> rejectInvitation(String id);
}

/// Interfaz de repositorio para cuentas compartidas
abstract class SharedAccountRepository {
  Future<List<SharedAccountData>> getForFamily(String familyId);
  Future<void> shareAccount(SharedAccountData data);
  Future<void> unshareAccount(String id);
  Future<void> updatePermissions(String id, {bool? visibleToAll, bool? membersCanTransact});
}

// ============================================================
// MODELOS DE DOMINIO
// ============================================================

/// Datos de familia para la capa de dominio
class FamilyData {
  final String id;
  final String name;
  final String? description;
  final String? icon;
  final String? color;
  final String ownerId;
  final String? inviteCode;
  final DateTime createdAt;
  final DateTime updatedAt;

  const FamilyData({
    required this.id,
    required this.name,
    this.description,
    this.icon,
    this.color,
    required this.ownerId,
    this.inviteCode,
    required this.createdAt,
    required this.updatedAt,
  });

  FamilyData copyWith({
    String? id,
    String? name,
    String? description,
    String? icon,
    String? color,
    String? ownerId,
    String? inviteCode,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FamilyData(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      ownerId: ownerId ?? this.ownerId,
      inviteCode: inviteCode ?? this.inviteCode,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Datos de miembro de familia
class FamilyMemberData {
  final String id;
  final String familyId;
  final String userId;
  final String role; // owner, admin, member, viewer
  final bool isActive;
  final DateTime joinedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const FamilyMemberData({
    required this.id,
    required this.familyId,
    required this.userId,
    required this.role,
    this.isActive = true,
    required this.joinedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isOwner => role == 'owner';
  bool get isAdmin => role == 'owner' || role == 'admin';
}

/// Datos de invitación a familia
class FamilyInvitationData {
  final String id;
  final String familyId;
  final String invitedEmail;
  final String invitedByUserId;
  final String role;
  final String token;
  final String? message;
  final String status; // pending, accepted, rejected, expired
  final DateTime expiresAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const FamilyInvitationData({
    required this.id,
    required this.familyId,
    required this.invitedEmail,
    required this.invitedByUserId,
    required this.role,
    required this.token,
    this.message,
    this.status = 'pending',
    required this.expiresAt,
    required this.createdAt,
    required this.updatedAt,
  });
}

/// Datos de cuenta compartida
class SharedAccountData {
  final String id;
  final String familyId;
  final String accountId;
  final String ownerUserId;
  final bool visibleToAll;
  final bool membersCanTransact;
  final DateTime createdAt;

  const SharedAccountData({
    required this.id,
    required this.familyId,
    required this.accountId,
    required this.ownerUserId,
    this.visibleToAll = true,
    this.membersCanTransact = false,
    required this.createdAt,
  });
}

/// Familia con sus miembros (agregado)
class FamilyWithMembersData {
  final FamilyData family;
  final List<FamilyMemberData> members;
  final FamilyMemberData? currentUserMember;

  const FamilyWithMembersData({
    required this.family,
    required this.members,
    this.currentUserMember,
  });

  bool get isOwner => currentUserMember?.isOwner ?? false;
  bool get isAdmin => currentUserMember?.isAdmin ?? false;
  bool get canInvite => isAdmin;
  bool get canManageMembers => isAdmin;
  int get memberCount => members.length;
}

// ============================================================
// SERVICIO DE DOMINIO
// ============================================================

/// Servicio de dominio para gestión de familias
/// Contiene toda la lógica de negocio, independiente del framework
class FamilyService {
  final FamilyRepository familyRepository;
  final FamilyMemberRepository memberRepository;
  final FamilyInvitationRepository invitationRepository;
  final SharedAccountRepository sharedAccountRepository;

  const FamilyService({
    required this.familyRepository,
    required this.memberRepository,
    required this.invitationRepository,
    required this.sharedAccountRepository,
  });

  /// Obtiene una familia con sus miembros
  Future<FamilyWithMembersData?> getFamilyWithMembers(
    String familyId,
    String? currentUserId,
  ) async {
    final family = await familyRepository.getFamilyById(familyId);
    if (family == null) return null;

    final members = await memberRepository.getMembersForFamily(familyId);
    final currentMember = currentUserId != null
        ? members.where((m) => m.userId == currentUserId).firstOrNull
        : null;

    return FamilyWithMembersData(
      family: family,
      members: members,
      currentUserMember: currentMember,
    );
  }

  /// Crea una nueva familia y agrega al creador como owner
  Future<String> createFamily({
    required String userId,
    required String name,
    String? description,
    String? icon,
    String? color,
  }) async {
    final familyId = const Uuid().v4();
    final memberId = const Uuid().v4();
    final now = DateTime.now();

    // Crear la familia
    await familyRepository.createFamily(FamilyData(
      id: familyId,
      name: name,
      description: description,
      icon: icon,
      color: color,
      ownerId: userId,
      createdAt: now,
      updatedAt: now,
    ));

    // Agregar al creador como owner
    await memberRepository.addMember(FamilyMemberData(
      id: memberId,
      familyId: familyId,
      userId: userId,
      role: 'owner',
      joinedAt: now,
      createdAt: now,
      updatedAt: now,
    ));

    return familyId;
  }

  /// Actualiza una familia
  Future<void> updateFamily({
    required String familyId,
    required String userId,
    String? name,
    String? description,
    String? icon,
    String? color,
  }) async {
    // Verificar permisos
    final isAdmin = await memberRepository.isAdminOrOwner(familyId, userId);
    if (!isAdmin) {
      throw const FamilyPermissionException('No tienes permisos para editar esta familia');
    }

    final existing = await familyRepository.getFamilyById(familyId);
    if (existing == null) {
      throw const FamilyNotFoundException('Familia no encontrada');
    }

    await familyRepository.updateFamily(existing.copyWith(
      name: name,
      description: description,
      icon: icon,
      color: color,
      updatedAt: DateTime.now(),
    ));
  }

  /// Elimina una familia (solo owner)
  Future<void> deleteFamily(String familyId, String userId) async {
    final member = await memberRepository.getMember(familyId, userId);
    if (member == null || !member.isOwner) {
      throw const FamilyPermissionException('Solo el dueño puede eliminar la familia');
    }

    await familyRepository.deleteFamily(familyId);
  }

  /// Genera código de invitación
  Future<String> generateInviteCode(String familyId, String userId) async {
    final isAdmin = await memberRepository.isAdminOrOwner(familyId, userId);
    if (!isAdmin) {
      throw const FamilyPermissionException('No tienes permisos para generar códigos');
    }

    return familyRepository.generateInviteCode(familyId);
  }

  /// Invita a un usuario por email
  Future<void> inviteByEmail({
    required String familyId,
    required String userId,
    required String email,
    required String role,
    String? message,
  }) async {
    // Validar permisos
    final isAdmin = await memberRepository.isAdminOrOwner(familyId, userId);
    if (!isAdmin) {
      throw const FamilyPermissionException('No tienes permisos para invitar');
    }

    // No permitir invitar como owner
    if (role == 'owner') {
      throw const FamilyBusinessException('No puedes invitar como dueño');
    }

    final invitationId = const Uuid().v4();
    final token = const Uuid().v4().replaceAll('-', '').substring(0, 16);
    final now = DateTime.now();

    await invitationRepository.createInvitation(FamilyInvitationData(
      id: invitationId,
      familyId: familyId,
      invitedEmail: email.toLowerCase(),
      invitedByUserId: userId,
      role: role,
      token: token,
      message: message,
      expiresAt: now.add(const Duration(days: 7)),
      createdAt: now,
      updatedAt: now,
    ));
  }

  /// Unirse a familia por código
  Future<void> joinByCode(String code, String userId) async {
    final family = await familyRepository.getFamilyByInviteCode(code);
    if (family == null) {
      throw const FamilyNotFoundException('Código de invitación inválido');
    }

    // Verificar si ya es miembro
    final existingMember = await memberRepository.getMember(family.id, userId);
    if (existingMember != null && existingMember.isActive) {
      throw const FamilyBusinessException('Ya eres miembro de esta familia');
    }

    // Agregar como miembro
    final memberId = const Uuid().v4();
    final now = DateTime.now();

    await memberRepository.addMember(FamilyMemberData(
      id: memberId,
      familyId: family.id,
      userId: userId,
      role: 'member',
      joinedAt: now,
      createdAt: now,
      updatedAt: now,
    ));
  }

  /// Cambia el rol de un miembro
  Future<void> changeMemberRole({
    required String familyId,
    required String adminUserId,
    required String memberId,
    required String newRole,
  }) async {
    // Validar permisos
    final isAdmin = await memberRepository.isAdminOrOwner(familyId, adminUserId);
    if (!isAdmin) {
      throw const FamilyPermissionException('No tienes permisos para cambiar roles');
    }

    // No permitir cambiar a owner
    if (newRole == 'owner') {
      throw const FamilyBusinessException('No puedes asignar el rol de dueño');
    }

    await memberRepository.updateMemberRole(memberId, newRole);
  }

  /// Elimina un miembro de la familia
  Future<void> removeMember({
    required String familyId,
    required String adminUserId,
    required String memberId,
  }) async {
    final isAdmin = await memberRepository.isAdminOrOwner(familyId, adminUserId);
    if (!isAdmin) {
      throw const FamilyPermissionException('No tienes permisos para eliminar miembros');
    }

    await memberRepository.removeMember(memberId);
  }

  /// Sale de una familia
  Future<void> leaveFamily(String familyId, String userId) async {
    final member = await memberRepository.getMember(familyId, userId);
    if (member == null) {
      throw const FamilyNotFoundException('No eres miembro de esta familia');
    }

    if (member.isOwner) {
      throw const FamilyBusinessException(
        'El dueño no puede abandonar la familia. Debes transferir la propiedad primero.',
      );
    }

    await memberRepository.removeMember(member.id);
  }

  /// Comparte una cuenta con la familia
  Future<void> shareAccount({
    required String familyId,
    required String userId,
    required String accountId,
    bool visibleToAll = true,
    bool membersCanTransact = false,
  }) async {
    final id = const Uuid().v4();

    await sharedAccountRepository.shareAccount(SharedAccountData(
      id: id,
      familyId: familyId,
      accountId: accountId,
      ownerUserId: userId,
      visibleToAll: visibleToAll,
      membersCanTransact: membersCanTransact,
      createdAt: DateTime.now(),
    ));
  }

  /// Deja de compartir una cuenta
  Future<void> unshareAccount(String sharedAccountId) async {
    await sharedAccountRepository.unshareAccount(sharedAccountId);
  }

  /// Actualiza permisos de cuenta compartida
  Future<void> updateSharedAccountPermissions(
    String sharedAccountId, {
    bool? visibleToAll,
    bool? membersCanTransact,
  }) async {
    await sharedAccountRepository.updatePermissions(
      sharedAccountId,
      visibleToAll: visibleToAll,
      membersCanTransact: membersCanTransact,
    );
  }
}

// ============================================================
// EXCEPCIONES DE DOMINIO
// ============================================================

class FamilyException implements Exception {
  final String message;
  const FamilyException(this.message);
  @override
  String toString() => message;
}

class FamilyNotFoundException extends FamilyException {
  const FamilyNotFoundException(super.message);
}

class FamilyPermissionException extends FamilyException {
  const FamilyPermissionException(super.message);
}

class FamilyBusinessException extends FamilyException {
  const FamilyBusinessException(super.message);
}
