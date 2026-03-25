enum MessageStatus { sending, sent, delivered, seen }

class MessageEntity {
  final String id;
  final String text;
  final String senderId;
  final String? receiverId;
  final String? groupId;
  final bool isMe;
  final MessageStatus status;
  final DateTime createdAt;

  const MessageEntity({
    required this.id,
    required this.text,
    required this.senderId,
    this.receiverId,
    this.groupId,
    required this.isMe,
    required this.status,
    required this.createdAt,
  });
}
