import 'package:flutter/material.dart';
import 'package:pulse_chat/core/constant/app_color.dart';
import 'package:pulse_chat/core/constant/app_icons.dart';
import 'package:pulse_chat/features/chat/domain/entities/message_entity.dart';

class MessageBubble extends StatefulWidget {
  final MessageEntity message;
  final int animationIndex;

  const MessageBubble({
    super.key,
    required this.message,
    this.animationIndex = 0,
  });

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    final slideBegin = widget.message.isMe
        ? const Offset(0.3, 0)
        : const Offset(-0.3, 0);

    _slideAnimation = Tween<Offset>(begin: slideBegin, end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
        );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));

    // Stagger animation for new messages
    Future.delayed(
      Duration(milliseconds: (widget.animationIndex * 50).clamp(0, 200)),
      () {
        if (mounted) _animController.forward();
      },
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Align(
          alignment: widget.message.isMe
              ? Alignment.centerRight
              : Alignment.centerLeft,
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: widget.message.isMe
                  ? AppColors.primary
                  : AppColors.grey200,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(widget.message.isMe ? 16 : 4),
                bottomRight: Radius.circular(widget.message.isMe ? 4 : 16),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.message.text,
                  style: TextStyle(
                    color: widget.message.isMe
                        ? AppColors.white
                        : AppColors.black87,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatTime(widget.message.createdAt),
                      style: TextStyle(
                        fontSize: 10,
                        color: widget.message.isMe
                            ? AppColors.white70
                            : AppColors.grey600,
                      ),
                    ),
                    if (widget.message.isMe) ...[
                      const SizedBox(width: 4),
                      _StatusIcon(status: widget.message.status),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}

class _StatusIcon extends StatelessWidget {
  final MessageStatus status;

  const _StatusIcon({required this.status});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: Icon(
        _statusIcon(status),
        key: ValueKey(status),
        size: 14,
        color: status == MessageStatus.seen
            ? const Color(0xFF4FC3F7)
            : AppColors.white70,
      ),
    );
  }

  IconData _statusIcon(MessageStatus status) {
    switch (status) {
      case MessageStatus.sending:
        return AppIcons.sending;
      case MessageStatus.sent:
        return AppIcons.sent;
      case MessageStatus.delivered:
        return AppIcons.delivered;
      case MessageStatus.seen:
        return AppIcons.delivered;
    }
  }
}
