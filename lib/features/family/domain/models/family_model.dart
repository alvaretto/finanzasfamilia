/// Rol de miembro en la familia
enum FamilyRole {
  owner,
  admin,
  member,
  viewer;

  String get displayName {
    switch (this) {
      case FamilyRole.owner:
        return 'Propietario';
      case FamilyRole.admin:
        return 'Administrador';
      case FamilyRole.member:
        return 'Miembro';
      case FamilyRole.viewer:
        return 'Solo lectura';
    }
  }

  bool get canEdit => this == owner || this == admin || this == member;
  bool get canManageMembers => this == owner || this == admin;
  bool get canDelete => this == owner;
}

/// Modelo de familia
class FamilyModel {
  final String id;
  final String name;
  final String ownerId;
  final String? inviteCode;
  final DateTime createdAt;
  final List<FamilyMember> members;

  const FamilyModel({
    required this.id,
    required this.name,
    required this.ownerId,
    this.inviteCode,
    required this.createdAt,
    this.members = const [],
  });

  int get memberCount => members.length;

  FamilyMember? getMember(String userId) {
    try {
      return members.firstWhere((m) => m.userId == userId);
    } catch (_) {
      return null;
    }
  }

  bool isOwner(String userId) => ownerId == userId;

  FamilyModel copyWith({
    String? id,
    String? name,
    String? ownerId,
    String? inviteCode,
    DateTime? createdAt,
    List<FamilyMember>? members,
  }) {
    return FamilyModel(
      id: id ?? this.id,
      name: name ?? this.name,
      ownerId: ownerId ?? this.ownerId,
      inviteCode: inviteCode ?? this.inviteCode,
      createdAt: createdAt ?? this.createdAt,
      members: members ?? this.members,
    );
  }

  factory FamilyModel.fromJson(Map<String, dynamic> json) {
    final membersJson = json['family_members'] as List<dynamic>? ?? [];
    return FamilyModel(
      id: json['id'] as String,
      name: json['name'] as String,
      ownerId: json['owner_id'] as String,
      inviteCode: json['invite_code'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      members: membersJson
          .map((m) => FamilyMember.fromJson(m as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'owner_id': ownerId,
      'invite_code': inviteCode,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

/// Miembro de familia
class FamilyMember {
  final String id;
  final String familyId;
  final String userId;
  final FamilyRole role;
  final DateTime joinedAt;
  final String? displayName;
  final String? avatarUrl;

  const FamilyMember({
    required this.id,
    required this.familyId,
    required this.userId,
    required this.role,
    required this.joinedAt,
    this.displayName,
    this.avatarUrl,
  });

  FamilyMember copyWith({
    String? id,
    String? familyId,
    String? userId,
    FamilyRole? role,
    DateTime? joinedAt,
    String? displayName,
    String? avatarUrl,
  }) {
    return FamilyMember(
      id: id ?? this.id,
      familyId: familyId ?? this.familyId,
      userId: userId ?? this.userId,
      role: role ?? this.role,
      joinedAt: joinedAt ?? this.joinedAt,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }

  factory FamilyMember.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] as Map<String, dynamic>?;
    return FamilyMember(
      id: json['id'] as String,
      familyId: json['family_id'] as String,
      userId: json['user_id'] as String,
      role: FamilyRole.values.firstWhere(
        (r) => r.name == json['role'],
        orElse: () => FamilyRole.member,
      ),
      joinedAt: DateTime.parse(json['joined_at'] as String),
      displayName: profile?['display_name'] as String?,
      avatarUrl: profile?['avatar_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'family_id': familyId,
      'user_id': userId,
      'role': role.name,
      'joined_at': joinedAt.toIso8601String(),
    };
  }
}
