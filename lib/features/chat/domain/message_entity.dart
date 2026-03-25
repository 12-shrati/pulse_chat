class Message {
  final String id;
  final String text;
  final bool isMe;
  final DateTime time;
  final MessageStatus status;

  Message({
    required this.id,
    required this.text,
    required this.isMe,
    required this.time,
    required this.status,
  });
}

enum MessageStatus {
  sending,
  sent,
  delivered,
  seen,
}