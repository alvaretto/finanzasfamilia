import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';

import 'package:finanzas_familiares/data/local/database.dart';
import 'package:finanzas_familiares/data/local/daos/families_dao.dart';
import 'package:finanzas_familiares/data/local/tables/families_table.dart';

void main() {
  late AppDatabase db;
  late FamiliesDao dao;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dao = FamiliesDao(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('FamiliesDao - Families', () {
    Future<String> createTestFamily({
      String? ownerId,
      String name = 'Test Family',
      String? description,
      String? icon,
      String? color,
    }) async {
      final id = const Uuid().v4();
      final owner = ownerId ?? const Uuid().v4();

      await dao.createFamily(FamiliesCompanion(
        id: Value(id),
        name: Value(name),
        description: Value(description),
        icon: Value(icon),
        color: Value(color),
        ownerId: Value(owner),
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ));

      return id;
    }

    Future<void> addTestMember({
      required String familyId,
      required String userId,
      String role = 'member',
    }) async {
      await dao.addMember(FamilyMembersCompanion(
        id: Value(const Uuid().v4()),
        familyId: Value(familyId),
        userId: Value(userId),
        role: Value(role),
        joinedAt: Value(DateTime.now()),
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ));
    }

    test('createFamily crea una familia correctamente', () async {
      final familyId = await createTestFamily(name: 'Familia García');

      final family = await dao.getFamilyById(familyId);
      expect(family, isNotNull);
      expect(family!.name, equals('Familia García'));
    });

    test('getFamilyById retorna null para familia inexistente', () async {
      final family = await dao.getFamilyById('non-existent');
      expect(family, isNull);
    });

    test('getFamiliesForUser retorna familias del usuario', () async {
      final userId = const Uuid().v4();
      final familyId1 = await createTestFamily(name: 'Familia 1');
      final familyId2 = await createTestFamily(name: 'Familia 2');
      await createTestFamily(name: 'Otra Familia'); // Sin miembro

      await addTestMember(familyId: familyId1, userId: userId);
      await addTestMember(familyId: familyId2, userId: userId);

      final families = await dao.getFamiliesForUser(userId);
      expect(families.length, equals(2));
    });

    test('updateFamily actualiza correctamente', () async {
      final familyId = await createTestFamily(name: 'Nombre Original');

      await dao.updateFamily(FamiliesCompanion(
        id: Value(familyId),
        name: const Value('Nombre Actualizado'),
        updatedAt: Value(DateTime.now()),
      ));

      final family = await dao.getFamilyById(familyId);
      expect(family!.name, equals('Nombre Actualizado'));
    });

    test('deleteFamily hace soft delete', () async {
      final userId = const Uuid().v4();
      final familyId = await createTestFamily();
      await addTestMember(familyId: familyId, userId: userId);

      await dao.deleteFamily(familyId);

      final families = await dao.getFamiliesForUser(userId);
      expect(families.length, equals(0));

      // La familia aún existe pero inactiva
      final family = await dao.getFamilyById(familyId);
      expect(family, isNotNull);
      expect(family!.isActive, isFalse);
    });

    test('generateInviteCode crea código único', () async {
      final familyId = await createTestFamily();

      final code = await dao.generateInviteCode(familyId);
      expect(code.length, equals(8));

      final family = await dao.getFamilyById(familyId);
      expect(family!.inviteCode, equals(code));
    });

    test('getFamilyByInviteCode encuentra familia por código', () async {
      final familyId = await createTestFamily();
      final code = await dao.generateInviteCode(familyId);

      final family = await dao.getFamilyByInviteCode(code);
      expect(family, isNotNull);
      expect(family!.id, equals(familyId));
    });
  });

  group('FamiliesDao - Members', () {
    Future<String> createFamilyWithOwner() async {
      final familyId = const Uuid().v4();
      final ownerId = const Uuid().v4();

      await dao.createFamily(FamiliesCompanion(
        id: Value(familyId),
        name: const Value('Test Family'),
        ownerId: Value(ownerId),
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ));

      await dao.addMember(FamilyMembersCompanion(
        id: Value(const Uuid().v4()),
        familyId: Value(familyId),
        userId: Value(ownerId),
        role: const Value('owner'),
        joinedAt: Value(DateTime.now()),
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ));

      return familyId;
    }

    test('addMember agrega miembro correctamente', () async {
      final familyId = await createFamilyWithOwner();
      final newUserId = const Uuid().v4();

      await dao.addMember(FamilyMembersCompanion(
        id: Value(const Uuid().v4()),
        familyId: Value(familyId),
        userId: Value(newUserId),
        displayName: const Value('Juan García'),
        role: const Value('member'),
        joinedAt: Value(DateTime.now()),
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ));

      final members = await dao.getMembersForFamily(familyId);
      expect(members.length, equals(2)); // Owner + nuevo miembro
    });

    test('getMember obtiene miembro específico', () async {
      final familyId = await createFamilyWithOwner();
      final userId = const Uuid().v4();

      await dao.addMember(FamilyMembersCompanion(
        id: Value(const Uuid().v4()),
        familyId: Value(familyId),
        userId: Value(userId),
        displayName: const Value('María'),
        role: const Value('admin'),
        joinedAt: Value(DateTime.now()),
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ));

      final member = await dao.getMember(familyId, userId);
      expect(member, isNotNull);
      expect(member!.displayName, equals('María'));
      expect(member.role, equals('admin'));
    });

    test('updateMemberRole actualiza rol correctamente', () async {
      final familyId = await createFamilyWithOwner();
      final userId = const Uuid().v4();
      final memberId = const Uuid().v4();

      await dao.addMember(FamilyMembersCompanion(
        id: Value(memberId),
        familyId: Value(familyId),
        userId: Value(userId),
        role: const Value('member'),
        joinedAt: Value(DateTime.now()),
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ));

      await dao.updateMemberRole(memberId, FamilyMemberRole.admin);

      final member = await dao.getMember(familyId, userId);
      expect(member!.role, equals('admin'));
    });

    test('removeMember hace soft delete', () async {
      final familyId = await createFamilyWithOwner();
      final userId = const Uuid().v4();
      final memberId = const Uuid().v4();

      await dao.addMember(FamilyMembersCompanion(
        id: Value(memberId),
        familyId: Value(familyId),
        userId: Value(userId),
        role: const Value('member'),
        joinedAt: Value(DateTime.now()),
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ));

      final membersBefore = await dao.getMembersForFamily(familyId);
      expect(membersBefore.length, equals(2));

      await dao.removeMember(memberId);

      final membersAfter = await dao.getMembersForFamily(familyId);
      expect(membersAfter.length, equals(1)); // Solo el owner
    });

    test('isAdminOrOwner verifica permisos correctamente', () async {
      final familyId = await createFamilyWithOwner();
      final members = await dao.getMembersForFamily(familyId);
      final ownerUserId = members.first.userId;

      final memberUserId = const Uuid().v4();
      await dao.addMember(FamilyMembersCompanion(
        id: Value(const Uuid().v4()),
        familyId: Value(familyId),
        userId: Value(memberUserId),
        role: const Value('member'),
        joinedAt: Value(DateTime.now()),
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ));

      expect(await dao.isAdminOrOwner(familyId, ownerUserId), isTrue);
      expect(await dao.isAdminOrOwner(familyId, memberUserId), isFalse);
    });

    test('countMembers cuenta correctamente', () async {
      final familyId = await createFamilyWithOwner();

      for (var i = 0; i < 3; i++) {
        await dao.addMember(FamilyMembersCompanion(
          id: Value(const Uuid().v4()),
          familyId: Value(familyId),
          userId: Value(const Uuid().v4()),
          role: const Value('member'),
          joinedAt: Value(DateTime.now()),
          createdAt: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()),
        ));
      }

      final count = await dao.countMembers(familyId);
      expect(count, equals(4)); // Owner + 3 miembros
    });
  });

  group('FamiliesDao - Invitations', () {
    test('createInvitation crea invitación', () async {
      final familyId = const Uuid().v4();
      await dao.createFamily(FamiliesCompanion(
        id: Value(familyId),
        name: const Value('Test'),
        ownerId: Value(const Uuid().v4()),
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ));

      await dao.createInvitation(FamilyInvitationsCompanion(
        id: Value(const Uuid().v4()),
        familyId: Value(familyId),
        invitedEmail: const Value('test@example.com'),
        invitedByUserId: Value(const Uuid().v4()),
        role: const Value('member'),
        token: const Value('ABC123'),
        expiresAt: Value(DateTime.now().add(const Duration(days: 7))),
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ));

      final invitations =
          await dao.getPendingInvitationsForEmail('test@example.com');
      expect(invitations.length, equals(1));
    });

    test('getInvitationByToken encuentra invitación válida', () async {
      final familyId = const Uuid().v4();
      await dao.createFamily(FamiliesCompanion(
        id: Value(familyId),
        name: const Value('Test'),
        ownerId: Value(const Uuid().v4()),
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ));

      const token = 'UNIQUE_TOKEN_123';
      await dao.createInvitation(FamilyInvitationsCompanion(
        id: Value(const Uuid().v4()),
        familyId: Value(familyId),
        invitedEmail: const Value('test@example.com'),
        invitedByUserId: Value(const Uuid().v4()),
        token: const Value(token),
        expiresAt: Value(DateTime.now().add(const Duration(days: 7))),
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ));

      final invitation = await dao.getInvitationByToken(token);
      expect(invitation, isNotNull);
      expect(invitation!.invitedEmail, equals('test@example.com'));
    });

    test('acceptInvitation actualiza estado', () async {
      final familyId = const Uuid().v4();
      final invitationId = const Uuid().v4();

      await dao.createFamily(FamiliesCompanion(
        id: Value(familyId),
        name: const Value('Test'),
        ownerId: Value(const Uuid().v4()),
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ));

      await dao.createInvitation(FamilyInvitationsCompanion(
        id: Value(invitationId),
        familyId: Value(familyId),
        invitedEmail: const Value('test@example.com'),
        invitedByUserId: Value(const Uuid().v4()),
        token: const Value('TOKEN'),
        expiresAt: Value(DateTime.now().add(const Duration(days: 7))),
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ));

      await dao.acceptInvitation(invitationId);

      // La invitación ya no está pending
      final invitations =
          await dao.getPendingInvitationsForEmail('test@example.com');
      expect(invitations.length, equals(0));
    });
  });

  group('FamiliesDao - SharedAccounts', () {
    test('shareAccount comparte cuenta', () async {
      final familyId = const Uuid().v4();
      await dao.createFamily(FamiliesCompanion(
        id: Value(familyId),
        name: const Value('Test'),
        ownerId: Value(const Uuid().v4()),
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ));

      await dao.shareAccount(SharedAccountsCompanion(
        id: Value(const Uuid().v4()),
        familyId: Value(familyId),
        accountId: Value(const Uuid().v4()),
        ownerUserId: Value(const Uuid().v4()),
        createdAt: Value(DateTime.now()),
      ));

      final sharedAccounts = await dao.getSharedAccountsForFamily(familyId);
      expect(sharedAccounts.length, equals(1));
    });

    test('updateSharedAccountPermissions actualiza permisos', () async {
      final familyId = const Uuid().v4();
      final sharedAccountId = const Uuid().v4();

      await dao.createFamily(FamiliesCompanion(
        id: Value(familyId),
        name: const Value('Test'),
        ownerId: Value(const Uuid().v4()),
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ));

      await dao.shareAccount(SharedAccountsCompanion(
        id: Value(sharedAccountId),
        familyId: Value(familyId),
        accountId: Value(const Uuid().v4()),
        ownerUserId: Value(const Uuid().v4()),
        visibleToAll: const Value(true),
        membersCanTransact: const Value(false),
        createdAt: Value(DateTime.now()),
      ));

      await dao.updateSharedAccountPermissions(
        sharedAccountId,
        membersCanTransact: true,
      );

      final accounts = await dao.getSharedAccountsForFamily(familyId);
      expect(accounts.first.membersCanTransact, isTrue);
    });

    test('unshareAccount elimina cuenta compartida', () async {
      final familyId = const Uuid().v4();
      final sharedAccountId = const Uuid().v4();

      await dao.createFamily(FamiliesCompanion(
        id: Value(familyId),
        name: const Value('Test'),
        ownerId: Value(const Uuid().v4()),
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ));

      await dao.shareAccount(SharedAccountsCompanion(
        id: Value(sharedAccountId),
        familyId: Value(familyId),
        accountId: Value(const Uuid().v4()),
        ownerUserId: Value(const Uuid().v4()),
        createdAt: Value(DateTime.now()),
      ));

      await dao.unshareAccount(sharedAccountId);

      final accounts = await dao.getSharedAccountsForFamily(familyId);
      expect(accounts.length, equals(0));
    });
  });
}
