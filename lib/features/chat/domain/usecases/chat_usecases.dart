import 'package:pulse_chat/features/chat/domain/entities/message_entity.dart';
import 'package:pulse_chat/features/chat/domain/repositories/chat_repository.dart';

class SendMessageUseCase {
  final ChatRepository _repository;

  SendMessageUseCase(this._repository);

  Future<void> call(MessageEntity message) {
    return _repository.sendMessage(message);
  }
}

class GetMessagesUseCase {
  final ChatRepository _repository;

  GetMessagesUseCase(this._repository);

  Future<List<MessageEntity>> call(String conversationId) {
    return _repository.getMessages(conversationId);
  }
}

class ListenMessagesUseCase {
  final ChatRepository _repository;

  ListenMessagesUseCase(this._repository);

  Stream<MessageEntity> call() {
    return _repository.incomingMessages;
  }
}
