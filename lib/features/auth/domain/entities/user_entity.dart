class UserEntity {
  final String id;
  final String name;
  final String email;
  final String? avatarUrl;
  final bool isOnline;
  final DateTime? lastSeen;

  const UserEntity({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
    this.isOnline = false,
    this.lastSeen,
  });
}

class ContactEntity {
  final String userId;
  final String contactId;
  final DateTime addedAt;

  const ContactEntity({
    required this.userId,
    required this.contactId,
    required this.addedAt,
  });
}
