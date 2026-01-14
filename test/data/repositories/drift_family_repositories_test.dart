import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';

import 'package:finanzas_familiares/data/local/database.dart';
import 'package:finanzas_familiares/data/local/daos/families_dao.dart';
import 'package:finanzas_familiares/data/repositories/drift_family_repositories.dart';
import 'package:finanzas_familiares/domain/services/family_service.dart';

void main() {
  late AppDatabase db;
  late FamiliesDao dao;
  const uuid = Uuid();

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dao = FamiliesDao(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('DriftFamilyRepository', () {
    late DriftFamilyRepository repository;

    setUp(() {
      repository = DriftFamilyRepository(dao);
    });

    test('getFamilyById retorna FamilyData con mapeo correcto', () async {
      final familyId = uuid.v4();
      final ownerId = uuid.v4();
      final now = DateTime.now();

      await dao.createFamily(FamiliesCompanion(
        id: Value(familyId),
        name: const Value('Familia Test'),
        description: const Value('Descripción'),
        icon: const Value('🏠'),
        color: const Value('#FF0000'),
        ownerId: Value(ownerId),
        createdAt: Value(now),
        updatedAt: Value(now),
      ));

      final result = await repository.getFamilyById(familyId);

      expect(result, isNotNull);
      expect(result, isA<FamilyData>());
      expect(result!.id, equals(familyId));
      expect(result.name, equals('Familia Test'));
      expect(result.description, equals('Descripción'));
      expect(result.icon, equals('🏠'));
      expect(result.color, equals('#FF0000'));
      expect(result.ownerId, equals(ownerId));
    });

    test('getFamilyById retorna null para ID inexistente', () async {
      final result = await repository.getFamilyById('non-existent');
      expect(result, isNull);
    });

    test('getFamilyByInviteCode retorna familia por código', () async {
      final familyId = uuid.v4();
      await dao.createFamily(FamiliesCompanion(
        id: Value(familyId),
        name: const Value('Test'),
        ownerId: Value(uuid.v4()),
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ));

      final code = await dao.generateInviteCode(familyId);
      final result = await repository.getFamilyByInviteCode(code);

      expect(result, isNotNull);
      expect(result!.id, equals(familyId));
    });

    test('getFamiliesForUser retorna lista de FamilyData', () async {
      final userId = uuid.v4();
      final familyId1 = uuid.v4();
      final familyId2 = uuid.v4();

      for (final id in [familyId1, familyId2]) {
        await dao.createFamily(FamiliesCompanion(
          id: Value(id),
          name: Value('Familia $id'),
          ownerId: Value(uuid.v4()),
          createdAt: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()),
        ));
        await dao.addMember(FamilyMembersCompanion(
          id: Value(uuid.v4()),
          familyId: Value(id),
          userId: Value(userId),
          role: const Value('member'),
          joinedAt: Value(DateTime.now()),
          createdAt: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()),
        ));
      }

      final result = await repository.getFamiliesForUser(userId);

      expect(result, hasLength(2));
      // Todos los resultados son FamilyData por tipo del repositorio
    });

    test('createFamily persiste FamilyData correctamente', () async {
      final familyData = FamilyData(
        id: uuid.v4(),
        name: 'Nueva Familia',
        description: 'Descripción',
        icon: '👪',
        color: '#00FF00',
        ownerId: uuid.v4(),
        inviteCode: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await repository.createFamily(familyData);
      final result = await repository.getFamilyById(familyData.id);

      expect(result, isNotNull);
      expect(result!.name, equals('Nueva Familia'));
      expect(result.description, equals('Descripción'));
      expect(result.icon, equals('👪'));
    });

    test('updateFamily actualiza FamilyData correctamente', () async {
      final familyId = uuid.v4();
      final now = DateTime.now();

      await dao.createFamily(FamiliesCompanion(
        id: Value(familyId),
        name: const Value('Original'),
        ownerId: Value(uuid.v4()),
        createdAt: Value(now),
        updatedAt: Value(now),
      ));

      final updated = FamilyData(
        id: familyId,
        name: 'Actualizado',
        description: 'Nueva descripción',
        icon: '🏦',
        color: '#0000FF',
        ownerId: uuid.v4(),
        inviteCode: null,
        createdAt: now,
        updatedAt: DateTime.now(),
      );

      await repository.updateFamily(updated);
      final result = await repository.getFamilyById(familyId);

      expect(result!.name, equals('Actualizado'));
      expect(result.description, equals('Nueva descripción'));
    });

    test('deleteFamily elimina familia', () async {
      final userId = uuid.v4();
      final familyId = uuid.v4();

      await dao.createFamily(FamiliesCompanion(
        id: Value(familyId),
        name: const Value('A Eliminar'),
        ownerId: Value(uuid.v4()),
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ));
      await dao.addMember(FamilyMembersCompanion(
        id: Value(uuid.v4()),
        familyId: Value(familyId),
        userId: Value(userId),
        role: const Value('member'),
        joinedAt: Value(DateTime.now()),
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ));

      await repository.deleteFamily(familyId);
      final families = await repository.getFamiliesForUser(userId);

      expect(families, isEmpty);
    });

    test('generateInviteCode retorna código de 8 caracteres', () async {
      final familyId = uuid.v4();
      await dao.createFamily(FamiliesCompanion(
        id: Value(familyId),
        name: const Value('Test'),
        ownerId: Value(uuid.v4()),
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ));

      final code = await repository.generateInviteCode(familyId);

      expect(code, hasLength(8));
    });
  });

  group('DriftFamilyMemberRepository', () {
    late DriftFamilyMemberRepository repository;
    late String familyId;

    setUp(() async {
      repository = DriftFamilyMemberRepository(dao);
      familyId = uuid.v4();
      await dao.createFamily(FamiliesCompanion(
        id: Value(familyId),
        name: const Value('Test Family'),
        ownerId: Value(uuid.v4()),
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ));
    });

    test('getMembersForFamily retorna lista de FamilyMemberData', () async {
      final userId = uuid.v4();
      await dao.addMember(FamilyMembersCompanion(
        id: Value(uuid.v4()),
        familyId: Value(familyId),
        userId: Value(userId),
        role: const Value('admin'),
        joinedAt: Value(DateTime.now()),
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ));

      final members = await repository.getMembersForFamily(familyId);

      expect(members, hasLength(1));
      expect(members.first, isA<FamilyMemberData>());
      expect(members.first.role, equals('admin'));
    });

    test('getMember retorna FamilyMemberData con mapeo correcto', () async {
      final userId = uuid.v4();
      final memberId = uuid.v4();
      final joinedAt = DateTime.now();

      await dao.addMember(FamilyMembersCompanion(
        id: Value(memberId),
        familyId: Value(familyId),
        userId: Value(userId),
        role: const Value('owner'),
        isActive: const Value(true),
        joinedAt: Value(joinedAt),
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ));

      final result = await repository.getMember(familyId, userId);

      expect(result, isNotNull);
      expect(result!.id, equals(memberId));
      expect(result.familyId, equals(familyId));
      expect(result.userId, equals(userId));
      expect(result.role, equals('owner'));
      expect(result.isActive, isTrue);
    });

    test('addMember persiste FamilyMemberData', () async {
      final memberData = FamilyMemberData(
        id: uuid.v4(),
        familyId: familyId,
        userId: uuid.v4(),
        role: 'member',
        isActive: true,
        joinedAt: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await repository.addMember(memberData);
      final result = await repository.getMember(familyId, memberData.userId);

      expect(result, isNotNull);
      expect(result!.role, equals('member'));
    });

    test('updateMemberRole actualiza rol correctamente', () async {
      final userId = uuid.v4();
      final memberId = uuid.v4();

      await dao.addMember(FamilyMembersCompanion(
        id: Value(memberId),
        familyId: Value(familyId),
        userId: Value(userId),
        role: const Value('member'),
        joinedAt: Value(DateTime.now()),
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ));

      await repository.updateMemberRole(memberId, 'admin');
      final result = await repository.getMember(familyId, userId);

      expect(result!.role, equals('admin'));
    });

    test('removeMember elimina miembro', () async {
      final userId = uuid.v4();
      final memberId = uuid.v4();

      await dao.addMember(FamilyMembersCompanion(
        id: Value(memberId),
        familyId: Value(familyId),
        userId: Value(userId),
        role: const Value('member'),
        joinedAt: Value(DateTime.now()),
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ));

      await repository.removeMember(memberId);
      final members = await repository.getMembersForFamily(familyId);

      expect(members, isEmpty);
    });

    test('isAdminOrOwner verifica permisos correctamente', () async {
      final ownerUserId = uuid.v4();
      final memberUserId = uuid.v4();

      await dao.addMember(FamilyMembersCompanion(
        id: Value(uuid.v4()),
        familyId: Value(familyId),
        userId: Value(ownerUserId),
        role: const Value('owner'),
        joinedAt: Value(DateTime.now()),
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ));
      await dao.addMember(FamilyMembersCompanion(
        id: Value(uuid.v4()),
        familyId: Value(familyId),
        userId: Value(memberUserId),
        role: const Value('member'),
        joinedAt: Value(DateTime.now()),
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ));

      expect(await repository.isAdminOrOwner(familyId, ownerUserId), isTrue);
      expect(await repository.isAdminOrOwner(familyId, memberUserId), isFalse);
    });
  });

  group('DriftFamilyInvitationRepository', () {
    late DriftFamilyInvitationRepository repository;
    late String familyId;

    setUp(() async {
      repository = DriftFamilyInvitationRepository(dao);
      familyId = uuid.v4();
      await dao.createFamily(FamiliesCompanion(
        id: Value(familyId),
        name: const Value('Test Family'),
        ownerId: Value(uuid.v4()),
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ));
    });

    test('getPendingForEmail retorna lista de FamilyInvitationData', () async {
      const email = 'test@example.com';
      await dao.createInvitation(FamilyInvitationsCompanion(
        id: Value(uuid.v4()),
        familyId: Value(familyId),
        invitedEmail: const Value(email),
        invitedByUserId: Value(uuid.v4()),
        role: const Value('member'),
        token: const Value('TOKEN123'),
        expiresAt: Value(DateTime.now().add(const Duration(days: 7))),
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ));

      final invitations = await repository.getPendingForEmail(email);

      expect(invitations, hasLength(1));
      expect(invitations.first, isA<FamilyInvitationData>());
      expect(invitations.first.invitedEmail, equals(email));
    });

    test('createInvitation persiste FamilyInvitationData', () async {
      final invitationData = FamilyInvitationData(
        id: uuid.v4(),
        familyId: familyId,
        invitedEmail: 'nuevo@example.com',
        invitedByUserId: uuid.v4(),
        role: 'admin',
        token: 'NEW_TOKEN',
        message: 'Únete a nuestra familia',
        status: 'pending',
        expiresAt: DateTime.now().add(const Duration(days: 7)),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await repository.createInvitation(invitationData);
      final result = await repository.getPendingForEmail('nuevo@example.com');

      expect(result, hasLength(1));
      expect(result.first.role, equals('admin'));
      expect(result.first.message, equals('Únete a nuestra familia'));
    });

    test('acceptInvitation actualiza estado', () async {
      final invitationId = uuid.v4();
      await dao.createInvitation(FamilyInvitationsCompanion(
        id: Value(invitationId),
        familyId: Value(familyId),
        invitedEmail: const Value('accept@example.com'),
        invitedByUserId: Value(uuid.v4()),
        token: const Value('TOKEN'),
        expiresAt: Value(DateTime.now().add(const Duration(days: 7))),
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ));

      await repository.acceptInvitation(invitationId);
      final pending = await repository.getPendingForEmail('accept@example.com');

      expect(pending, isEmpty);
    });

    test('rejectInvitation actualiza estado', () async {
      final invitationId = uuid.v4();
      await dao.createInvitation(FamilyInvitationsCompanion(
        id: Value(invitationId),
        familyId: Value(familyId),
        invitedEmail: const Value('reject@example.com'),
        invitedByUserId: Value(uuid.v4()),
        token: const Value('TOKEN'),
        expiresAt: Value(DateTime.now().add(const Duration(days: 7))),
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ));

      await repository.rejectInvitation(invitationId);
      final pending = await repository.getPendingForEmail('reject@example.com');

      expect(pending, isEmpty);
    });

    test('getById retorna null (no implementado)', () async {
      final result = await repository.getById(uuid.v4());
      expect(result, isNull);
    });
  });

  group('DriftSharedAccountRepository', () {
    late DriftSharedAccountRepository repository;
    late String familyId;

    setUp(() async {
      repository = DriftSharedAccountRepository(dao);
      familyId = uuid.v4();
      await dao.createFamily(FamiliesCompanion(
        id: Value(familyId),
        name: const Value('Test Family'),
        ownerId: Value(uuid.v4()),
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ));
    });

    test('getForFamily retorna lista de SharedAccountData', () async {
      await dao.shareAccount(SharedAccountsCompanion(
        id: Value(uuid.v4()),
        familyId: Value(familyId),
        accountId: Value(uuid.v4()),
        ownerUserId: Value(uuid.v4()),
        visibleToAll: const Value(true),
        membersCanTransact: const Value(false),
        createdAt: Value(DateTime.now()),
      ));

      final accounts = await repository.getForFamily(familyId);

      expect(accounts, hasLength(1));
      expect(accounts.first, isA<SharedAccountData>());
      expect(accounts.first.visibleToAll, isTrue);
      expect(accounts.first.membersCanTransact, isFalse);
    });

    test('shareAccount persiste SharedAccountData', () async {
      final accountData = SharedAccountData(
        id: uuid.v4(),
        familyId: familyId,
        accountId: uuid.v4(),
        ownerUserId: uuid.v4(),
        visibleToAll: true,
        membersCanTransact: true,
        createdAt: DateTime.now(),
      );

      await repository.shareAccount(accountData);
      final accounts = await repository.getForFamily(familyId);

      expect(accounts, hasLength(1));
      expect(accounts.first.membersCanTransact, isTrue);
    });

    test('updatePermissions actualiza permisos correctamente', () async {
      final sharedId = uuid.v4();
      await dao.shareAccount(SharedAccountsCompanion(
        id: Value(sharedId),
        familyId: Value(familyId),
        accountId: Value(uuid.v4()),
        ownerUserId: Value(uuid.v4()),
        visibleToAll: const Value(true),
        membersCanTransact: const Value(false),
        createdAt: Value(DateTime.now()),
      ));

      await repository.updatePermissions(
        sharedId,
        visibleToAll: false,
        membersCanTransact: true,
      );

      final accounts = await repository.getForFamily(familyId);
      expect(accounts.first.visibleToAll, isFalse);
      expect(accounts.first.membersCanTransact, isTrue);
    });

    test('unshareAccount elimina cuenta compartida', () async {
      final sharedId = uuid.v4();
      await dao.shareAccount(SharedAccountsCompanion(
        id: Value(sharedId),
        familyId: Value(familyId),
        accountId: Value(uuid.v4()),
        ownerUserId: Value(uuid.v4()),
        createdAt: Value(DateTime.now()),
      ));

      await repository.unshareAccount(sharedId);
      final accounts = await repository.getForFamily(familyId);

      expect(accounts, isEmpty);
    });
  });
}
