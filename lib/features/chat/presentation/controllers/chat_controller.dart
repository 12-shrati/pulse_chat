import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulse_chat/features/chat/domain/entities/message_entity.dart';
import 'package:pulse_chat/features/chat/domain/usecases/chat_usecases.dart';
import 'package:pulse_chat/features/chat/presentation/controllers/chat_state.dart';

class ChatController extends StateNotifier<ChatState> {
  final SendMessageUseCase _sendMessageUseCase;
  final GetMessagesUseCase _getMessagesUseCase;
  final ListenMessagesUseCase _listenMessagesUseCase;

  ChatController({
    required SendMessageUseCase sendMessageUseCase,
    required GetMessagesUseCase getMessagesUseCase,
    required ListenMessagesUseCase listenMessagesUseCase,
  }) : _sendMessageUseCase = sendMessageUseCase,
       _getMessagesUseCase = getMessagesUseCase,
       _listenMessagesUseCase = listenMessagesUseCase,
       super(const ChatState()) {
    _listenIncoming();
  }

  void _listenIncoming() {
    _listenMessagesUseCase().listen((message) {
      state = state.copyWith(messages: [...state.messages, message]);
    });
  }

  Future<void> loadMessages(String conversationId) async {
    state = state.copyWith(isLoading: true);
    try {
      final messages = await _getMessagesUseCase(conversationId);
      state = state.copyWith(messages: messages, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> sendMessage(String text) async {
    final message = MessageEntity(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      senderId: 'me',
      isMe: true,
      status: MessageStatus.sending,
      createdAt: DateTime.now(),
    );

    state = state.copyWith(messages: [...state.messages, message]);

    try {
      await _sendMessageUseCase(message);
      final updated = state.messages.map((m) {
        if (m.id == message.id) {
          return MessageEntity(
            id: m.id,
            text: m.text,
            senderId: m.senderId,
            receiverId: m.receiverId,
            groupId: m.groupId,
            isMe: m.isMe,
            status: MessageStatus.sent,
            createdAt: m.createdAt,
          );
        }
        return m;
      }).toList();
      state = state.copyWith(messages: updated);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}
