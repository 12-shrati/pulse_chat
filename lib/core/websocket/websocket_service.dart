import 'dart:async';
import 'dart:convert';
import 'package:pulse_chat/core/constant/server_config.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketService {
  WebSocketChannel? _channel;
  bool _isConnected = false;
  bool _disposed = false;
  String? _userId;
  final String _url;

  // Reconnection
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectDelay = 30;

  // Stream controllers for incoming events
  final StreamController<Map<String, dynamic>> _messageController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _groupMessageController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _typingController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _presenceController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _messageStatusController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<bool> _connectionStateController =
      StreamController<bool>.broadcast();
  final StreamController<List<Map<String, dynamic>>> _usersListController =
      StreamController<List<Map<String, dynamic>>>.broadcast();

  WebSocketService({String? url}) : _url = url ?? ServerConfig.wsUrl;

  bool get isConnected => _isConnected;

  // Event streams
  Stream<Map<String, dynamic>> get onMessage => _messageController.stream;
  Stream<Map<String, dynamic>> get onGroupMessage =>
      _groupMessageController.stream;
  Stream<Map<String, dynamic>> get onTyping => _typingController.stream;
  Stream<Map<String, dynamic>> get onPresence => _presenceController.stream;
  Stream<Map<String, dynamic>> get onMessageStatus =>
      _messageStatusController.stream;
  Stream<bool> get onConnectionState => _connectionStateController.stream;
  Stream<List<Map<String, dynamic>>> get onUsersList =>
      _usersListController.stream;

  Future<void> connect({required String userId}) async {
    _userId = userId;
    _disposed = false;
    await _doConnect();
  }

  Future<void> _doConnect() async {
    if (_disposed) return;

    try {
      _channel = WebSocketChannel.connect(Uri.parse(_url));
      await _channel!.ready;
      _isConnected = true;
      _reconnectAttempts = 0;
      _connectionStateController.add(true);

      // Register with server
      _send({'event': 'connect', 'userId': _userId});

      // Listen to incoming data
      _channel!.stream.listen(
        _handleIncoming,
        onError: (_) => _handleDisconnect(),
        onDone: _handleDisconnect,
      );
    } catch (_) {
      _isConnected = false;
      _connectionStateController.add(false);
      _scheduleReconnect();
    }
  }

  void _handleIncoming(dynamic raw) {
    try {
      final data = jsonDecode(raw as String) as Map<String, dynamic>;
      final event = data['event'] as String?;

      switch (event) {
        case 'message':
          _messageController.add(data);
          break;
        case 'group_message':
          _groupMessageController.add(data);
          break;
        case 'typing':
          _typingController.add(data);
          break;
        case 'presence':
        case 'online_users':
          _presenceController.add(data);
          break;
        case 'message_ack':
        case 'message_status':
          _messageStatusController.add(data);
          break;
        case 'users_list':
          final users =
              (data['users'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ??
              [];
          _usersListController.add(users);
          break;
      }
    } catch (_) {}
  }

  void _handleDisconnect() {
    _isConnected = false;
    _connectionStateController.add(false);
    _channel = null;
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_disposed) return;
    _reconnectTimer?.cancel();

    final delay = _reconnectAttempts < _maxReconnectDelay
        ? _reconnectAttempts + 1
        : _maxReconnectDelay;
    _reconnectAttempts++;

    _reconnectTimer = Timer(Duration(seconds: delay), _doConnect);
  }

  void _send(Map<String, dynamic> data) {
    if (!_isConnected || _channel == null) return;
    _channel!.sink.add(jsonEncode(data));
  }

  // --- Public send methods ---

  void sendMessage({
    required String receiverId,
    required String text,
    required String messageId,
  }) {
    _send({
      'event': 'message',
      'receiverId': receiverId,
      'text': text,
      'messageId': messageId,
    });
  }

  void sendGroupMessage({
    required String groupId,
    required String text,
    required String messageId,
    required List<String> memberIds,
  }) {
    _send({
      'event': 'group_message',
      'groupId': groupId,
      'text': text,
      'messageId': messageId,
      'memberIds': memberIds,
    });
  }

  void sendTyping({
    String? receiverId,
    String? groupId,
    List<String>? memberIds,
  }) {
    _send({
      'event': 'typing',
      'receiverId': ?receiverId,
      'groupId': ?groupId,
      'memberIds': ?memberIds,
    });
  }

  void sendMessageSeen({required String messageId, required String senderId}) {
    _send({
      'event': 'message_seen',
      'messageId': messageId,
      'senderId': senderId,
    });
  }

  void registerUser({
    required String id,
    required String name,
    required String email,
    String? avatarUrl,
  }) {
    _send({
      'event': 'register_user',
      'id': id,
      'name': name,
      'email': email,
      'avatarUrl': ?avatarUrl,
    });
  }

  void requestUsers() {
    _send({'event': 'get_users'});
  }

  void disconnect() {
    _disposed = true;
    _reconnectTimer?.cancel();
    _isConnected = false;
    _channel?.sink.close();
    _channel = null;
    _connectionStateController.add(false);
  }

  void dispose() {
    disconnect();
    _messageController.close();
    _groupMessageController.close();
    _typingController.close();
    _presenceController.close();
    _messageStatusController.close();
    _connectionStateController.close();
    _usersListController.close();
  }
}
