import 'package:pulse_chat/features/chat/domain/entities/message_entity.dart';

class MessageModel extends MessageEntity {
  const MessageModel({
    required super.id,
    required super.text,
    required super.senderId,
    super.receiverId,
    super.groupId,
    required super.isMe,
    required super.status,
    required super.createdAt,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] as String,
      text: json['text'] as String,
      senderId: json['sender_id'] as String,
      receiverId: json['receiver_id'] as String?,
      groupId: json['group_id'] as String?,
      isMe: (json['is_me'] as int) == 1,
      status: MessageStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => MessageStatus.sending,
      ),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'group_id': groupId,
      'is_me': isMe ? 1 : 0,
      'status': status.name,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
