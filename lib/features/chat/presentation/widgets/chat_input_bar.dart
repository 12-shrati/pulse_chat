import 'package:flutter/material.dart';
import 'package:pulse_chat/core/constant/app_color.dart';
import 'package:pulse_chat/core/constant/app_icons.dart';
import 'package:pulse_chat/core/constant/string_constants.dart';

class ChatInputBar extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final ValueChanged<String>? onTextChanged;
  final VoidCallback? onEmojiTap;
  final VoidCallback? onImageTap;

  const ChatInputBar({
    super.key,
    required this.controller,
    required this.onSend,
    this.onTextChanged,
    this.onEmojiTap,
    this.onImageTap,
  });

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar>
    with SingleTickerProviderStateMixin {
  bool _hasText = false;
  late final AnimationController _sendButtonController;
  late final Animation<double> _sendButtonScale;

  @override
  void initState() {
    super.initState();
    _sendButtonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _sendButtonScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _sendButtonController, curve: Curves.easeOutBack),
    );
    widget.controller.addListener(_onTextUpdate);
  }

  void _onTextUpdate() {
    final hasText = widget.controller.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
      if (hasText) {
        _sendButtonController.forward();
      } else {
        _sendButtonController.reverse();
      }
    }
    widget.onTextChanged?.call(widget.controller.text);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextUpdate);
    _sendButtonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.grey200,
            offset: const Offset(0, -1),
            blurRadius: 4,
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Emoji button
            IconButton(
              icon: const Icon(Icons.emoji_emotions_outlined),
              color: AppColors.grey600,
              onPressed: widget.onEmojiTap,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              padding: EdgeInsets.zero,
            ),
            // Text input
            Expanded(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 120),
                child: TextField(
                  controller: widget.controller,
                  maxLines: null,
                  decoration: InputDecoration(
                    hintText: StringConstants.typeAMessage,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: AppColors.grey100,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    // Image picker inside text field
                    suffixIcon: IconButton(
                      icon: const Icon(AppIcons.image),
                      color: AppColors.grey600,
                      onPressed: widget.onImageTap,
                    ),
                  ),
                  textInputAction: TextInputAction.newline,
                ),
              ),
            ),
            const SizedBox(width: 6),
            // Send button with scale animation
            ScaleTransition(
              scale: _sendButtonScale,
              child: CircleAvatar(
                backgroundColor: AppColors.primary,
                radius: 22,
                child: IconButton(
                  icon: const Icon(
                    AppIcons.send,
                    color: AppColors.white,
                    size: 20,
                  ),
                  onPressed: _handleSend,
                  padding: EdgeInsets.zero,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleSend() {
    if (widget.controller.text.trim().isEmpty) return;
    widget.onSend();
  }
}
