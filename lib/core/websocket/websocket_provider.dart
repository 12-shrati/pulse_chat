import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulse_chat/core/websocket/websocket_service.dart';

final webSocketServiceProvider = Provider<WebSocketService>((ref) {
  final service = WebSocketService();
  ref.onDispose(() => service.dispose());
  return service;
});
