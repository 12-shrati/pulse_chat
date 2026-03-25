import 'dart:async';
import 'dart:convert';

import 'package:pulse_chat/core/websocket/websocket_service.dart';
import 'package:pulse_chat/features/chat/data/datasources/chat_local_datasource.dart';
import 'package:pulse_chat/features/chat/data/models/message_model.dart';
import 'package:pulse_chat/features/chat/domain/entities/message_entity.dart';
import 'package:pulse_chat/features/chat/domain/repositories/chat_repository.dart';

class ChatRepositoryImpl implements ChatRepository {
  final ChatLocalDataSource _localDataSource;
  final WebSocketService? _webSocketService;
  final StreamController<MessageEntity> _incomingController =
      StreamController<MessageEntity>.broadcast();

  ChatRepositoryImpl(this._localDataSource, this._webSocketService) {
    _listenToWebSocket();
  }

  void _listenToWebSocket() {
    _webSocketService?.stream.listen((event) {
      final data = jsonDecode(event);
      final message = MessageModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: data['message'] as String,
        senderId: 'remote',
        isMe: false,
        status: MessageStatus.delivered,
        createdAt: DateTime.now(),
      );
      _localDataSource.insertMessage(message);
      _incomingController.add(message);
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
    _webSocketService?.sendMessage(message.text);
    await updateMessageStatus(message.id, MessageStatus.sent);
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
