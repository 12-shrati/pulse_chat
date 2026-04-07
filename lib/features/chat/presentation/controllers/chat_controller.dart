import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulse_chat/features/chat/domain/entities/message_entity.dart';
import 'package:pulse_chat/features/chat/domain/usecases/chat_usecases.dart';
import 'package:pulse_chat/features/chat/presentation/controllers/chat_state.dart';

class ChatController extends StateNotifier<ChatState> {
  final SendMessageUseCase _sendMessageUseCase;
  final GetMessagesUseCase _getMessagesUseCase;
  final ListenMessagesUseCase _listenMessagesUseCase;
  StreamSubscription<MessageEntity>? _subscription;

  String? _currentUserId;
  String? _currentReceiverId;
  String? _currentGroupId;

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

  void setContext({
    required String userId,
    String? receiverId,
    String? groupId,
  }) {
    _currentUserId = userId;
    _currentReceiverId = receiverId;
    _currentGroupId = groupId;
  }

  void _listenIncoming() {
    _subscription = _listenMessagesUseCase().listen((message) {
      // Handle status update events (empty text = status update)
      if (message.text.isEmpty && message.isMe) {
        final updated = state.messages.map((m) {
          if (m.id == message.id) {
            return MessageEntity(
              id: m.id,
              text: m.text,
              senderId: m.senderId,
              receiverId: m.receiverId,
              groupId: m.groupId,
              isMe: m.isMe,
              status: message.status,
              createdAt: m.createdAt,
            );
          }
          return m;
        }).toList();
        state = state.copyWith(messages: updated);
        return;
      }

      // Filter: only add if message is for the current conversation
      final isForThisChat =
          (_currentGroupId != null && message.groupId == _currentGroupId) ||
          (_currentReceiverId != null &&
              (message.senderId == _currentReceiverId ||
                  message.receiverId == _currentReceiverId));

      if (isForThisChat) {
        state = state.copyWith(messages: [...state.messages, message]);
      }
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
    if (text.isEmpty) return;

    final message = MessageEntity(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      senderId: _currentUserId ?? 'me',
      receiverId: _currentReceiverId,
      groupId: _currentGroupId,
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

  void clearMessages() {
    state = const ChatState();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
