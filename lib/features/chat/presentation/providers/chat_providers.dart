import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulse_chat/core/database/database_provider.dart';
import 'package:pulse_chat/core/websocket/websocket_provider.dart';
import 'package:pulse_chat/features/chat/data/datasources/chat_local_datasource.dart';
import 'package:pulse_chat/features/chat/data/repositories/chat_repository_impl.dart';
import 'package:pulse_chat/features/chat/domain/repositories/chat_repository.dart';
import 'package:pulse_chat/features/chat/domain/usecases/chat_usecases.dart';
import 'package:pulse_chat/features/chat/presentation/controllers/chat_controller.dart';
import 'package:pulse_chat/features/chat/presentation/controllers/chat_state.dart';

final chatLocalDataSourceProvider = Provider<ChatLocalDataSource>((ref) {
  final db = ref.watch(databaseInstanceProvider);
  return ChatLocalDataSource(db);
});

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  final localDataSource = ref.watch(chatLocalDataSourceProvider);
  final socket = ref.watch(webSocketServiceProvider).valueOrNull;
  return ChatRepositoryImpl(localDataSource, socket);
});

final sendMessageUseCaseProvider = Provider<SendMessageUseCase>((ref) {
  return SendMessageUseCase(ref.watch(chatRepositoryProvider));
});

final getMessagesUseCaseProvider = Provider<GetMessagesUseCase>((ref) {
  return GetMessagesUseCase(ref.watch(chatRepositoryProvider));
});

final listenMessagesUseCaseProvider = Provider<ListenMessagesUseCase>((ref) {
  return ListenMessagesUseCase(ref.watch(chatRepositoryProvider));
});

final chatProvider = StateNotifierProvider<ChatController, ChatState>((ref) {
  return ChatController(
    sendMessageUseCase: ref.watch(sendMessageUseCaseProvider),
    getMessagesUseCase: ref.watch(getMessagesUseCaseProvider),
    listenMessagesUseCase: ref.watch(listenMessagesUseCaseProvider),
  );
});
