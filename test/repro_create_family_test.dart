import 'package:flutter_test/flutter_test.dart';
import 'package:finanzas_familiares/domain/services/family_service.dart';

// ============================================================
// In-Memory Repositories
// ============================================================

class InMemoryFamilyRepository implements FamilyRepository {
  final Map<String, FamilyData> families = {};

  @override
  Future<FamilyData?> getFamilyById(String id) async => families[id];

  @override
  Future<FamilyData?> getFamilyByInviteCode(String code) async {
    try {
      return families.values.firstWhere((f) => f.inviteCode == code);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<FamilyData>> getFamiliesForUser(String userId) async {
    // In a real repo this would join with members, but here we can just return all for simplicity
    // or rely on the service to filter? 
    // Actually the logic is usually: select families where id in (select familyId from members where userId = ?)
    // But since this method is on the FamilyRepository, it relies on the implementation details.
    // For specific test of createFamily, we don't strictly need this unless the service calls it.
    // Service creates family then adds member. It doesn't call getFamiliesForUser.
    return families.values.toList(); 
  }

  @override
  Future<void> createFamily(FamilyData family) async {
    families[family.id] = family;
  }

  @override
  Future<void> updateFamily(FamilyData family) async {
    families[family.id] = family;
  }

  @override
  Future<void> deleteFamily(String id) async {
    families.remove(id);
  }

  @override
  Future<String> generateInviteCode(String familyId) async {
    const code = 'CODE123';
    final family = families[familyId];
    if (family != null) {
      families[familyId] = family.copyWith(inviteCode: code);
    }
    return code;
  }
}

class InMemoryFamilyMemberRepository implements FamilyMemberRepository {
  final List<FamilyMemberData> members = [];

  @override
  Future<List<FamilyMemberData>> getMembersForFamily(String familyId) async {
    return members.where((m) => m.familyId == familyId).toList();
  }

  @override
  Future<FamilyMemberData?> getMember(String familyId, String userId) async {
    return members
        .where((m) => m.familyId == familyId && m.userId == userId)
        .firstOrNull;
  }

  @override
  Future<void> addMember(FamilyMemberData member) async {
    members.add(member);
  }

  @override
  Future<void> updateMemberRole(String memberId, String role) async {
    final index = members.indexWhere((m) => m.id == memberId);
    if (index != -1) {
      // Create new fake member with updated role, can't copyWith easily if not freezed properly or if we don't have it handy
      // But FamilyMemberData is a regular class with copyWith?
      // No, it's defined in family_service.dart without copyWith shown in the view_file output, 
      // wait, FamilyData has copyWith, FamilyMemberData does NOT defined in the snippet I saw?
      // Actually let's assume valid implementation for now.
      // But for testing createFamily, we don't need updateMemberRole.
    }
  }

  @override
  Future<void> removeMember(String memberId) async {
    members.removeWhere((m) => m.id == memberId);
  }

  @override
  Future<bool> isAdminOrOwner(String familyId, String userId) async {
    final member = await getMember(familyId, userId);
    return member != null && (member.role == 'owner' || member.role == 'admin');
  }
}

class InMemoryFamilyInvitationRepository implements FamilyInvitationRepository {
  @override
  Future<List<FamilyInvitationData>> getPendingForEmail(String email) async => [];
  @override
  Future<FamilyInvitationData?> getById(String id) async => null;
  @override
  Future<void> createInvitation(FamilyInvitationData invitation) async {}
  @override
  Future<void> acceptInvitation(String id) async {}
  @override
  Future<void> rejectInvitation(String id) async {}
}

class InMemorySharedAccountRepository implements SharedAccountRepository {
  @override
  Future<List<SharedAccountData>> getForFamily(String familyId) async => [];
  @override
  Future<void> shareAccount(SharedAccountData data) async {}
  @override
  Future<void> unshareAccount(String id) async {}
  @override
  Future<void> updatePermissions(String id, {bool? visibleToAll, bool? membersCanTransact}) async {}
}

void main() {
  group('Repro: Create Family Service Logic', () {
    late FamilyService service;
    late InMemoryFamilyRepository familyRepo;
    late InMemoryFamilyMemberRepository memberRepo;

    setUp(() {
      familyRepo = InMemoryFamilyRepository();
      memberRepo = InMemoryFamilyMemberRepository();
      service = FamilyService(
        familyRepository: familyRepo,
        memberRepository: memberRepo,
        invitationRepository: InMemoryFamilyInvitationRepository(),
        sharedAccountRepository: InMemorySharedAccountRepository(),
      );
    });

    test('createFamily creates a family and adds owner member', () async {
      const userId = 'user-123';
      const name = 'Test Family';
      const description = 'Test Description';
      const icon = '🏠';
      const color = '#FF0000';

      final familyId = await service.createFamily(
        userId: userId,
        name: name,
        description: description,
        icon: icon,
        color: color,
      );

      // Verify Family Created
      final family = await familyRepo.getFamilyById(familyId);
      expect(family, isNotNull);
      expect(family!.name, equals(name));
      expect(family.description, equals(description));
      expect(family.icon, equals(icon));
      expect(family.color, equals(color));
      expect(family.ownerId, equals(userId));

      // Verify Member Added
      final members = await memberRepo.getMembersForFamily(familyId);
      expect(members.length, equals(1));
      final owner = members.first;
      expect(owner.userId, equals(userId));
      expect(owner.role, equals('owner'));
      expect(owner.familyId, equals(familyId));
    });
  });
}
