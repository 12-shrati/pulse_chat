import 'package:pulse_chat/features/chat/domain/message_entity.dart';

class MessageModel extends Message {
   MessageModel({
    required super.id,
    required super.text,
    required super.isMe,
    required super.time,
    required super.status,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] as String,
      text: json['text'] as String,
      isMe: json['isMe'] as bool,
      time: DateTime.parse(json['time'] as String),
      status: MessageStatus.values.firstWhere((e) => e.name == json['status']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'isMe': isMe,
      'time': time.toIso8601String(),
      'status': status,
    };
  }
}
