import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketService {
  WebSocketChannel? _channel;
  bool _isConnected = false;
  final String _url;

  WebSocketService({String url = 'wss://echo.websocket.events'}) : _url = url;

  bool get isConnected => _isConnected;

  Future<void> connect() async {
    try {
      _channel = WebSocketChannel.connect(Uri.parse(_url));
      await _channel!.ready;
      _isConnected = true;
    } catch (e) {
      _isConnected = false;
      _channel = null;
      rethrow;
    }
  }

  void disconnect() {
    _isConnected = false;
    _channel?.sink.close();
    _channel = null;
  }

  void sendMessage(String message) {
    if (!_isConnected || _channel == null) return;
    _channel!.sink.add(
      jsonEncode({
        "message": message,
        "timestamp": DateTime.now().toIso8601String(),
      }),
    );
  }

  Stream get stream {
    if (_channel == null) return const Stream.empty();
    return _channel!.stream;
  }
}
