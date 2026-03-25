import 'package:pulse_chat/features/chat/domain/entities/message_entity.dart';

abstract class ChatRepository {
  Future<List<MessageEntity>> getMessages(String conversationId);
  Future<void> sendMessage(MessageEntity message);
  Future<void> saveMessage(MessageEntity message);
  Future<void> updateMessageStatus(String id, MessageStatus status);
  Stream<MessageEntity> get incomingMessages;
}
