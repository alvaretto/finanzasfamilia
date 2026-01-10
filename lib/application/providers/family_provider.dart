import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart';

import '../../data/local/database.dart';
import '../../data/local/daos/families_dao.dart';
import '../../data/local/tables/families_table.dart';
import 'database_provider.dart';

part 'family_provider.g.dart';

/// Provider para el DAO de familias
@riverpod
FamiliesDao familiesDao(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  return FamiliesDao(db);
}

/// Datos de una familia con sus miembros
class FamilyWithMembers {
  final FamilyEntry family;
  final List<FamilyMemberEntry> members;
  final FamilyMemberEntry? currentUserMember;

  const FamilyWithMembers({
    required this.family,
    required this.members,
    this.currentUserMember,
  });

  bool get isOwner => currentUserMember?.role == 'owner';
  bool get isAdmin =>
      currentUserMember?.role == 'owner' || currentUserMember?.role == 'admin';
  bool get canInvite => isAdmin;
  bool get canManageMembers => isAdmin;
  int get memberCount => members.length;
}

/// Provider para el ID del usuario actual (debe ser establecido por AuthProvider)
@riverpod
class CurrentUserId extends _$CurrentUserId {
  @override
  String? build() => null;

  void setUserId(String? userId) {
    state = userId;
  }
}

/// Provider para la familia actualmente seleccionada
@riverpod
class SelectedFamilyId extends _$SelectedFamilyId {
  @override
  String? build() => null;

  void selectFamily(String? familyId) {
    state = familyId;
  }
}

/// Provider para obtener las familias del usuario actual
@riverpod
Future<List<FamilyEntry>> userFamilies(Ref ref) async {
  final dao = ref.watch(familiesDaoProvider);
  final userId = ref.watch(currentUserIdProvider);

  if (userId == null) return [];
  return dao.getFamiliesForUser(userId);
}

/// Provider para observar las familias del usuario
@riverpod
Stream<List<FamilyEntry>> watchUserFamilies(Ref ref) {
  final dao = ref.watch(familiesDaoProvider);
  final userId = ref.watch(currentUserIdProvider);

  if (userId == null) return Stream.value([]);
  return dao.watchFamiliesForUser(userId);
}

/// Provider para obtener una familia con sus miembros
@riverpod
Future<FamilyWithMembers?> familyWithMembers(Ref ref, String familyId) async {
  final dao = ref.watch(familiesDaoProvider);
  final userId = ref.watch(currentUserIdProvider);

  final family = await dao.getFamilyById(familyId);
  if (family == null) return null;

  final members = await dao.getMembersForFamily(familyId);
  final currentMember =
      userId != null ? members.where((m) => m.userId == userId).firstOrNull : null;

  return FamilyWithMembers(
    family: family,
    members: members,
    currentUserMember: currentMember,
  );
}

/// Provider para observar miembros de una familia
@riverpod
Stream<List<FamilyMemberEntry>> watchFamilyMembers(Ref ref, String familyId) {
  final dao = ref.watch(familiesDaoProvider);
  return dao.watchMembersForFamily(familyId);
}

/// Provider para invitaciones pendientes del usuario
@riverpod
Future<List<FamilyInvitationEntry>> pendingInvitations(
  Ref ref,
  String email,
) async {
  final dao = ref.watch(familiesDaoProvider);
  return dao.getPendingInvitationsForEmail(email);
}

/// Notifier para gestión de familias
@riverpod
class FamilyNotifier extends _$FamilyNotifier {
  @override
  FutureOr<void> build() async {}

  FamiliesDao get _dao => ref.read(familiesDaoProvider);
  String? get _userId => ref.read(currentUserIdProvider);

  /// Crea una nueva familia
  Future<String> createFamily({
    required String name,
    String? description,
    String? icon,
    String? color,
  }) async {
    if (_userId == null) throw Exception('Usuario no autenticado');

    state = const AsyncLoading();

    try {
      final familyId = const Uuid().v4();
      final memberId = const Uuid().v4();

      // Crear la familia
      await _dao.createFamily(FamiliesCompanion(
        id: Value(familyId),
        name: Value(name),
        description: Value(description),
        icon: Value(icon),
        color: Value(color),
        ownerId: Value(_userId!),
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ));

      // Agregar al creador como owner
      await _dao.addMember(FamilyMembersCompanion(
        id: Value(memberId),
        familyId: Value(familyId),
        userId: Value(_userId!),
        role: const Value('owner'),
        joinedAt: Value(DateTime.now()),
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ));

      state = const AsyncData(null);
      ref.invalidate(userFamiliesProvider);

      return familyId;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  /// Actualiza una familia
  Future<void> updateFamily({
    required String familyId,
    String? name,
    String? description,
    String? icon,
    String? color,
  }) async {
    state = const AsyncLoading();

    try {
      await _dao.updateFamily(FamiliesCompanion(
        id: Value(familyId),
        name: name != null ? Value(name) : const Value.absent(),
        description: Value(description),
        icon: Value(icon),
        color: Value(color),
        updatedAt: Value(DateTime.now()),
      ));

      state = const AsyncData(null);
      ref.invalidate(userFamiliesProvider);
      ref.invalidate(familyWithMembersProvider(familyId));
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  /// Elimina una familia (solo owner)
  Future<void> deleteFamily(String familyId) async {
    if (_userId == null) throw Exception('Usuario no autenticado');

    state = const AsyncLoading();

    try {
      final isOwner = await _isOwner(familyId);
      if (!isOwner) throw Exception('Solo el dueño puede eliminar la familia');

      await _dao.deleteFamily(familyId);

      state = const AsyncData(null);
      ref.invalidate(userFamiliesProvider);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  /// Genera código de invitación
  Future<String> generateInviteCode(String familyId) async {
    final isAdmin = await _isAdminOrOwner(familyId);
    if (!isAdmin) throw Exception('No tienes permisos para invitar');

    return _dao.generateInviteCode(familyId);
  }

  /// Invita a un usuario por email
  Future<void> inviteByEmail({
    required String familyId,
    required String email,
    FamilyMemberRole role = FamilyMemberRole.member,
    String? message,
  }) async {
    if (_userId == null) throw Exception('Usuario no autenticado');

    final isAdmin = await _isAdminOrOwner(familyId);
    if (!isAdmin) throw Exception('No tienes permisos para invitar');

    // No permitir invitar como owner
    if (role == FamilyMemberRole.owner) {
      throw Exception('No puedes invitar como dueño');
    }

    final invitationId = const Uuid().v4();
    final token = const Uuid().v4().replaceAll('-', '').substring(0, 16);

    await _dao.createInvitation(FamilyInvitationsCompanion(
      id: Value(invitationId),
      familyId: Value(familyId),
      invitedEmail: Value(email.toLowerCase()),
      invitedByUserId: Value(_userId!),
      role: Value(role.name),
      token: Value(token),
      message: Value(message),
      expiresAt: Value(DateTime.now().add(const Duration(days: 7))),
      createdAt: Value(DateTime.now()),
      updatedAt: Value(DateTime.now()),
    ));

    ref.invalidate(pendingInvitationsProvider(email));
  }

  /// Acepta una invitación
  Future<void> acceptInvitation(String invitationId) async {
    if (_userId == null) throw Exception('Usuario no autenticado');

    state = const AsyncLoading();

    try {
      // TODO: Implementar búsqueda directa de invitación por ID
      // Por ahora aceptamos directamente
      await _dao.acceptInvitation(invitationId);

      // Agregar al usuario como miembro
      // (Esto debería hacerse con la información de la invitación)

      state = const AsyncData(null);
      ref.invalidate(userFamiliesProvider);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  /// Unirse a familia por código
  Future<void> joinByCode(String code) async {
    if (_userId == null) throw Exception('Usuario no autenticado');

    state = const AsyncLoading();

    try {
      final family = await _dao.getFamilyByInviteCode(code);
      if (family == null) {
        throw Exception('Código de invitación inválido');
      }

      // Verificar si ya es miembro
      final existingMember = await _dao.getMember(family.id, _userId!);
      if (existingMember != null && existingMember.isActive) {
        throw Exception('Ya eres miembro de esta familia');
      }

      // Agregar como miembro
      final memberId = const Uuid().v4();
      await _dao.addMember(FamilyMembersCompanion(
        id: Value(memberId),
        familyId: Value(family.id),
        userId: Value(_userId!),
        role: const Value('member'),
        joinedAt: Value(DateTime.now()),
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ));

      state = const AsyncData(null);
      ref.invalidate(userFamiliesProvider);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  /// Cambia el rol de un miembro
  Future<void> changeMemberRole(
    String memberId,
    FamilyMemberRole newRole,
  ) async {
    // No permitir cambiar a owner
    if (newRole == FamilyMemberRole.owner) {
      throw Exception('No puedes asignar el rol de dueño');
    }

    await _dao.updateMemberRole(memberId, newRole);
  }

  /// Elimina un miembro de la familia
  Future<void> removeMember(String familyId, String memberId) async {
    final isAdmin = await _isAdminOrOwner(familyId);
    if (!isAdmin) throw Exception('No tienes permisos para eliminar miembros');

    await _dao.removeMember(memberId);
    ref.invalidate(watchFamilyMembersProvider(familyId));
  }

  /// Sale de una familia
  Future<void> leaveFamily(String familyId) async {
    if (_userId == null) throw Exception('Usuario no autenticado');

    // Verificar que no sea el owner
    final member = await _dao.getMember(familyId, _userId!);
    if (member?.role == 'owner') {
      throw Exception('El dueño no puede abandonar la familia. Debes transferir la propiedad primero.');
    }

    if (member != null) {
      await _dao.removeMember(member.id);
      ref.invalidate(userFamiliesProvider);
    }
  }

  Future<bool> _isOwner(String familyId) async {
    if (_userId == null) return false;
    final member = await _dao.getMember(familyId, _userId!);
    return member?.role == 'owner';
  }

  Future<bool> _isAdminOrOwner(String familyId) async {
    if (_userId == null) return false;
    return _dao.isAdminOrOwner(familyId, _userId!);
  }
}

/// Provider para cuentas compartidas de una familia
@riverpod
Stream<List<SharedAccountEntry>> watchSharedAccounts(
  Ref ref,
  String familyId,
) {
  final dao = ref.watch(familiesDaoProvider);
  return dao.watchSharedAccountsForFamily(familyId);
}

/// Notifier para gestión de cuentas compartidas
@riverpod
class SharedAccountsNotifier extends _$SharedAccountsNotifier {
  @override
  FutureOr<void> build() async {}

  FamiliesDao get _dao => ref.read(familiesDaoProvider);
  String? get _userId => ref.read(currentUserIdProvider);

  /// Comparte una cuenta con la familia
  Future<void> shareAccount({
    required String familyId,
    required String accountId,
    bool visibleToAll = true,
    bool membersCanTransact = false,
  }) async {
    if (_userId == null) throw Exception('Usuario no autenticado');

    final id = const Uuid().v4();
    await _dao.shareAccount(SharedAccountsCompanion(
      id: Value(id),
      familyId: Value(familyId),
      accountId: Value(accountId),
      ownerUserId: Value(_userId!),
      visibleToAll: Value(visibleToAll),
      membersCanTransact: Value(membersCanTransact),
      createdAt: Value(DateTime.now()),
    ));

    ref.invalidate(watchSharedAccountsProvider(familyId));
  }

  /// Deja de compartir una cuenta
  Future<void> unshareAccount(String familyId, String sharedAccountId) async {
    await _dao.unshareAccount(sharedAccountId);
    ref.invalidate(watchSharedAccountsProvider(familyId));
  }

  /// Actualiza permisos de cuenta compartida
  Future<void> updatePermissions(
    String familyId,
    String sharedAccountId, {
    bool? visibleToAll,
    bool? membersCanTransact,
  }) async {
    await _dao.updateSharedAccountPermissions(
      sharedAccountId,
      visibleToAll: visibleToAll,
      membersCanTransact: membersCanTransact,
    );
    ref.invalidate(watchSharedAccountsProvider(familyId));
  }
}
