import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulse_chat/core/constant/app_color.dart';
import 'package:pulse_chat/core/constant/app_icons.dart';
import 'package:pulse_chat/core/constant/string_constants.dart';
import 'package:pulse_chat/core/network/connectivity_service.dart';
import 'package:pulse_chat/core/websocket/websocket_provider.dart';
import 'package:pulse_chat/features/chat/presentation/providers/chat_providers.dart';
import 'package:pulse_chat/features/chat/presentation/widgets/chat_input_bar.dart';
import 'package:pulse_chat/features/chat/presentation/widgets/message_bubble.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String contactName;
  final String? contactId;
  final String? currentUserId;

  const ChatScreen({
    super.key,
    required this.contactName,
    this.contactId,
    this.currentUserId,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  bool _isTyping = false;
  Timer? _typingTimer;

  @override
  void initState() {
    super.initState();
    final chatCtrl = ref.read(chatProvider.notifier);
    chatCtrl.clearMessages();
    chatCtrl.setContext(
      userId: widget.currentUserId ?? 'me',
      receiverId: widget.contactId,
    );
    if (widget.contactId != null) {
      Future(() {
        if (mounted) chatCtrl.loadMessages(widget.contactId!);
      });
    }

    // Listen for typing events
    final ws = ref.read(webSocketServiceProvider);
    ws.onTyping.listen((data) {
      if (data['senderId'] == widget.contactId) {
        setState(() => _isTyping = true);
        _typingTimer?.cancel();
        _typingTimer = Timer(const Duration(seconds: 2), () {
          if (mounted) setState(() => _isTyping = false);
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _typingTimer?.cancel();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _onTextChanged(String text) {
    if (text.isNotEmpty && widget.contactId != null) {
      ref
          .read(webSocketServiceProvider)
          .sendTyping(receiverId: widget.contactId);
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.contactName, style: const TextStyle(fontSize: 16)),
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              child: _isTyping
                  ? const Text(
                      'typing...',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
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
            child: chatState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : chatState.messages.isEmpty
                ? const Center(
                    child: Text(
                      StringConstants.noMessagesYet,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.grey),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: chatState.messages.length,
                    itemBuilder: (context, index) {
                      // Reverse index for reverse ListView
                      final msgIndex = chatState.messages.length - 1 - index;
                      return MessageBubble(
                        message: chatState.messages[msgIndex],
                        animationIndex: index,
                      );
                    },
                  ),
          ),
          ChatInputBar(
            controller: _controller,
            onTextChanged: _onTextChanged,
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
