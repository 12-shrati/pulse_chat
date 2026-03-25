import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulse_chat/core/constant/app_color.dart';
import 'package:pulse_chat/core/constant/app_icons.dart';
import 'package:pulse_chat/core/constant/string_constants.dart';
import 'package:pulse_chat/core/network/connectivity_service.dart';
import 'package:pulse_chat/features/chat/presentation/providers/chat_providers.dart';
import 'package:pulse_chat/features/chat/presentation/widgets/chat_input_bar.dart';
import 'package:pulse_chat/features/chat/presentation/widgets/message_bubble.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String contactName;

  const ChatScreen({super.key, required this.contactName});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);
    final connectivity = ref.watch(connectivityStreamProvider);

    ref.listen(chatProvider, (previous, next) {
      if ((previous?.messages.length ?? 0) < next.messages.length) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.contactName),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        actions: [
          connectivity.when(
            data: (isConnected) => Icon(
              isConnected ? AppIcons.wifi : AppIcons.wifiOff,
              color: isConnected ? AppColors.online : AppColors.offline,
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, _) =>
                const Icon(AppIcons.wifiOff, color: AppColors.error),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: chatState.messages.isEmpty
                ? const Center(
                    child: Text(
                      StringConstants.noMessagesYet,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.grey),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: chatState.messages.length,
                    itemBuilder: (context, index) {
                      return MessageBubble(message: chatState.messages[index]);
                    },
                  ),
          ),
          ChatInputBar(
            controller: _controller,
            onSend: () {
              ref
                  .read(chatProvider.notifier)
                  .sendMessage(_controller.text.trim());
              _controller.clear();
            },
          ),
        ],
      ),
    );
  }
}
