class GroupEntity {
  final String id;
  final String name;
  final String? description;
  final String? avatarUrl;
  final int? color;
  final String createdBy;
  final DateTime createdAt;
  final List<GroupMember> members;

  const GroupEntity({
    required this.id,
    required this.name,
    this.description,
    this.avatarUrl,
    this.color,
    required this.createdBy,
    required this.createdAt,
    this.members = const [],
  });
}

class GroupMember {
  final String userId;
  final String role;
  final DateTime joinedAt;

  const GroupMember({
    required this.userId,
    this.role = 'member',
    required this.joinedAt,
  });
}
