import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulse_chat/core/websocket/websocket_service.dart';

final webSocketServiceProvider = FutureProvider<WebSocketService>((ref) async {
  final service = WebSocketService();
  await service.connect();

  ref.onDispose(() {
    service.disconnect();
  });

  return service;
});
