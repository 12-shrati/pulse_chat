import 'dart:async';

import 'package:pulse_chat/core/websocket/websocket_service.dart';
import 'package:pulse_chat/features/chat/data/datasources/chat_local_datasource.dart';
import 'package:pulse_chat/features/chat/data/models/message_model.dart';
import 'package:pulse_chat/features/chat/domain/entities/message_entity.dart';
import 'package:pulse_chat/features/chat/domain/repositories/chat_repository.dart';

class ChatRepositoryImpl implements ChatRepository {
  final ChatLocalDataSource _localDataSource;
  final WebSocketService _webSocketService;
  final StreamController<MessageEntity> _incomingController =
      StreamController<MessageEntity>.broadcast();

  ChatRepositoryImpl(this._localDataSource, this._webSocketService) {
    _listenToWebSocket();
  }

  void _listenToWebSocket() {
    // Listen for direct messages
    _webSocketService.onMessage.listen((data) {
      final message = MessageModel(
        id: data['messageId'] as String,
        text: data['text'] as String,
        senderId: data['senderId'] as String,
        receiverId: data['receiverId'] as String?,
        isMe: false,
        status: MessageStatus.delivered,
        createdAt:
            DateTime.tryParse(data['timestamp'] as String? ?? '') ??
            DateTime.now(),
      );
      _localDataSource.insertMessage(message);
      _incomingController.add(message);
    });

    // Listen for group messages
    _webSocketService.onGroupMessage.listen((data) {
      final message = MessageModel(
        id: data['messageId'] as String,
        text: data['text'] as String,
        senderId: data['senderId'] as String,
        groupId: data['groupId'] as String?,
        isMe: false,
        status: MessageStatus.delivered,
        createdAt:
            DateTime.tryParse(data['timestamp'] as String? ?? '') ??
            DateTime.now(),
      );
      _localDataSource.insertMessage(message);
      _incomingController.add(message);
    });

    // Listen for message status updates (sent/delivered/seen)
    _webSocketService.onMessageStatus.listen((data) {
      final messageId = data['messageId'] as String?;
      final statusStr = data['status'] as String?;
      if (messageId != null && statusStr != null) {
        final status = MessageStatus.values.firstWhere(
          (e) => e.name == statusStr,
          orElse: () => MessageStatus.sent,
        );
        _localDataSource.updateMessageStatus(messageId, status.name);
        // Emit a status update event
        _incomingController.add(
          MessageEntity(
            id: messageId,
            text: '',
            senderId: '',
            isMe: true,
            status: status,
            createdAt: DateTime.now(),
          ),
        );
      }
    });
  }

  @override
  Future<List<MessageEntity>> getMessages(String conversationId) {
    return _localDataSource.getMessages(conversationId);
  }

  @override
  Future<void> sendMessage(MessageEntity message) async {
    final model = MessageModel(
      id: message.id,
      text: message.text,
      senderId: message.senderId,
      receiverId: message.receiverId,
      groupId: message.groupId,
      isMe: true,
      status: MessageStatus.sending,
      createdAt: message.createdAt,
    );
    await _localDataSource.insertMessage(model);

    if (message.groupId != null) {
      _webSocketService.sendGroupMessage(
        groupId: message.groupId!,
        text: message.text,
        messageId: message.id,
        memberIds: [],
      );
    } else if (message.receiverId != null) {
      _webSocketService.sendMessage(
        receiverId: message.receiverId!,
        text: message.text,
        messageId: message.id,
      );
    }
  }

  @override
  Future<void> saveMessage(MessageEntity message) async {
    final model = MessageModel(
      id: message.id,
      text: message.text,
      senderId: message.senderId,
      receiverId: message.receiverId,
      groupId: message.groupId,
      isMe: message.isMe,
      status: message.status,
      createdAt: message.createdAt,
    );
    await _localDataSource.insertMessage(model);
  }

  @override
  Future<void> updateMessageStatus(String id, MessageStatus status) {
    return _localDataSource.updateMessageStatus(id, status.name);
  }

  @override
  Stream<MessageEntity> get incomingMessages => _incomingController.stream;
}
