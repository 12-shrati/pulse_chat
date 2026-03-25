import 'package:pulse_chat/features/auth/domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  final String passwordHash;

  const UserModel({
    required super.id,
    required super.name,
    required super.email,
    this.passwordHash = '',
    super.avatarUrl,
    super.isOnline,
    super.lastSeen,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String? ?? '',
      passwordHash: json['password_hash'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String?,
      isOnline: (json['is_online'] as int?) == 1,
      lastSeen: json['last_seen'] != null
          ? DateTime.parse(json['last_seen'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'password_hash': passwordHash,
      'avatar_url': avatarUrl,
      'is_online': isOnline ? 1 : 0,
      'last_seen': lastSeen?.toIso8601String(),
    };
  }
}
