import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/local/daos/families_dao.dart';
import '../../data/repositories/drift_family_repositories.dart';
import '../../domain/services/family_service.dart';
import 'auth_provider.dart';
import 'database_provider.dart';

part 'family_provider.g.dart';

/// Provider para el DAO de familias
@riverpod
FamiliesDao familiesDao(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  return FamiliesDao(db);
}

/// Provider del repositorio de familias
@riverpod
FamilyRepository familyRepository(Ref ref) {
  final dao = ref.watch(familiesDaoProvider);
  return DriftFamilyRepository(dao);
}

/// Provider del repositorio de miembros
@riverpod
FamilyMemberRepository familyMemberRepository(Ref ref) {
  final dao = ref.watch(familiesDaoProvider);
  return DriftFamilyMemberRepository(dao);
}

/// Provider del repositorio de invitaciones
@riverpod
FamilyInvitationRepository familyInvitationRepository(Ref ref) {
  final dao = ref.watch(familiesDaoProvider);
  return DriftFamilyInvitationRepository(dao);
}

/// Provider del repositorio de cuentas compartidas
@riverpod
SharedAccountRepository sharedAccountRepository(Ref ref) {
  final dao = ref.watch(familiesDaoProvider);
  return DriftSharedAccountRepository(dao);
}

/// Provider del servicio de dominio de familias
@riverpod
FamilyService familyService(Ref ref) {
  return FamilyService(
    familyRepository: ref.watch(familyRepositoryProvider),
    memberRepository: ref.watch(familyMemberRepositoryProvider),
    invitationRepository: ref.watch(familyInvitationRepositoryProvider),
    sharedAccountRepository: ref.watch(sharedAccountRepositoryProvider),
  );
}

/// Provider para el ID del usuario actual (derivado de AuthProvider)
@riverpod
String? currentUserId(Ref ref) {
  final user = ref.watch(currentUserProvider);
  return user?.id;
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
Future<List<FamilyData>> userFamilies(Ref ref) async {
  final repository = ref.watch(familyRepositoryProvider);
  final userId = ref.watch(currentUserIdProvider);

  if (userId == null) return [];
  return repository.getFamiliesForUser(userId);
}

/// Provider para observar las familias del usuario (usa DAO directamente para Stream)
@riverpod
Stream<List<FamilyData>> watchUserFamilies(Ref ref) async* {
  final dao = ref.watch(familiesDaoProvider);
  final userId = ref.watch(currentUserIdProvider);

  if (userId == null) {
    yield [];
    return;
  }

  await for (final entries in dao.watchFamiliesForUser(userId)) {
    yield entries.map((e) => FamilyData(
      id: e.id,
      name: e.name,
      description: e.description,
      icon: e.icon,
      color: e.color,
      ownerId: e.ownerId,
      inviteCode: e.inviteCode,
      createdAt: e.createdAt ?? DateTime.now(),
      updatedAt: e.updatedAt ?? DateTime.now(),
    )).toList();
  }
}

/// Provider para obtener una familia con sus miembros
@riverpod
Future<FamilyWithMembersData?> familyWithMembers(Ref ref, String familyId) async {
  final service = ref.watch(familyServiceProvider);
  final userId = ref.watch(currentUserIdProvider);

  return service.getFamilyWithMembers(familyId, userId);
}

/// Provider para observar miembros de una familia (usa DAO directamente para Stream)
@riverpod
Stream<List<FamilyMemberData>> watchFamilyMembers(Ref ref, String familyId) async* {
  final dao = ref.watch(familiesDaoProvider);

  await for (final entries in dao.watchMembersForFamily(familyId)) {
    yield entries.map((e) => FamilyMemberData(
      id: e.id,
      familyId: e.familyId,
      userId: e.userId,
      role: e.role ?? 'member',
      isActive: e.isActive ?? true,
      joinedAt: e.joinedAt ?? DateTime.now(),
      createdAt: e.createdAt ?? DateTime.now(),
      updatedAt: e.updatedAt ?? DateTime.now(),
    )).toList();
  }
}

/// Provider para invitaciones pendientes del usuario
@riverpod
Future<List<FamilyInvitationData>> pendingInvitations(
  Ref ref,
  String email,
) async {
  final repository = ref.watch(familyInvitationRepositoryProvider);
  return repository.getPendingForEmail(email);
}

/// Notifier para gestión de familias
/// Delega toda la lógica de negocio a FamilyService
@riverpod
class FamilyNotifier extends _$FamilyNotifier {
  @override
  FutureOr<void> build() async {}

  FamilyService get _service => ref.read(familyServiceProvider);
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
      final familyId = await _service.createFamily(
        userId: _userId!,
        name: name,
        description: description,
        icon: icon,
        color: color,
      );

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
    if (_userId == null) throw Exception('Usuario no autenticado');

    state = const AsyncLoading();

    try {
      await _service.updateFamily(
        familyId: familyId,
        userId: _userId!,
        name: name,
        description: description,
        icon: icon,
        color: color,
      );

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
      await _service.deleteFamily(familyId, _userId!);

      state = const AsyncData(null);
      ref.invalidate(userFamiliesProvider);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  /// Genera código de invitación
  Future<String> generateInviteCode(String familyId) async {
    if (_userId == null) throw Exception('Usuario no autenticado');
    return _service.generateInviteCode(familyId, _userId!);
  }

  /// Invita a un usuario por email
  Future<void> inviteByEmail({
    required String familyId,
    required String email,
    String role = 'member',
    String? message,
  }) async {
    if (_userId == null) throw Exception('Usuario no autenticado');

    await _service.inviteByEmail(
      familyId: familyId,
      userId: _userId!,
      email: email,
      role: role,
      message: message,
    );

    ref.invalidate(pendingInvitationsProvider(email));
  }

  /// Acepta una invitación
  Future<void> acceptInvitation(String invitationId) async {
    if (_userId == null) throw Exception('Usuario no autenticado');

    state = const AsyncLoading();

    try {
      final repository = ref.read(familyInvitationRepositoryProvider);
      await repository.acceptInvitation(invitationId);

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
      await _service.joinByCode(code, _userId!);

      state = const AsyncData(null);
      ref.invalidate(userFamiliesProvider);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  /// Cambia el rol de un miembro
  Future<void> changeMemberRole(
    String familyId,
    String memberId,
    String newRole,
  ) async {
    if (_userId == null) throw Exception('Usuario no autenticado');

    await _service.changeMemberRole(
      familyId: familyId,
      adminUserId: _userId!,
      memberId: memberId,
      newRole: newRole,
    );

    ref.invalidate(watchFamilyMembersProvider(familyId));
  }

  /// Elimina un miembro de la familia
  Future<void> removeMember(String familyId, String memberId) async {
    if (_userId == null) throw Exception('Usuario no autenticado');

    await _service.removeMember(
      familyId: familyId,
      adminUserId: _userId!,
      memberId: memberId,
    );

    ref.invalidate(watchFamilyMembersProvider(familyId));
  }

  /// Sale de una familia
  Future<void> leaveFamily(String familyId) async {
    if (_userId == null) throw Exception('Usuario no autenticado');

    await _service.leaveFamily(familyId, _userId!);
    ref.invalidate(userFamiliesProvider);
  }
}

/// Provider para cuentas compartidas de una familia (usa DAO para Stream)
@riverpod
Stream<List<SharedAccountData>> watchSharedAccounts(
  Ref ref,
  String familyId,
) async* {
  final dao = ref.watch(familiesDaoProvider);

  await for (final entries in dao.watchSharedAccountsForFamily(familyId)) {
    yield entries.map((e) => SharedAccountData(
      id: e.id,
      familyId: e.familyId,
      accountId: e.accountId,
      ownerUserId: e.ownerUserId,
      visibleToAll: e.visibleToAll ?? true,
      membersCanTransact: e.membersCanTransact ?? false,
      createdAt: e.createdAt ?? DateTime.now(),
    )).toList();
  }
}

/// Notifier para gestión de cuentas compartidas
/// Delega la lógica a FamilyService
@riverpod
class SharedAccountsNotifier extends _$SharedAccountsNotifier {
  @override
  FutureOr<void> build() async {}

  FamilyService get _service => ref.read(familyServiceProvider);
  String? get _userId => ref.read(currentUserIdProvider);

  /// Comparte una cuenta con la familia
  Future<void> shareAccount({
    required String familyId,
    required String accountId,
    bool visibleToAll = true,
    bool membersCanTransact = false,
  }) async {
    if (_userId == null) throw Exception('Usuario no autenticado');

    await _service.shareAccount(
      familyId: familyId,
      userId: _userId!,
      accountId: accountId,
      visibleToAll: visibleToAll,
      membersCanTransact: membersCanTransact,
    );

    ref.invalidate(watchSharedAccountsProvider(familyId));
  }

  /// Deja de compartir una cuenta
  Future<void> unshareAccount(String familyId, String sharedAccountId) async {
    await _service.unshareAccount(sharedAccountId);
    ref.invalidate(watchSharedAccountsProvider(familyId));
  }

  /// Actualiza permisos de cuenta compartida
  Future<void> updatePermissions(
    String familyId,
    String sharedAccountId, {
    bool? visibleToAll,
    bool? membersCanTransact,
  }) async {
    await _service.updateSharedAccountPermissions(
      sharedAccountId,
      visibleToAll: visibleToAll,
      membersCanTransact: membersCanTransact,
    );
    ref.invalidate(watchSharedAccountsProvider(familyId));
  }
}
