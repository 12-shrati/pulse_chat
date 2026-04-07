import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulse_chat/core/constant/app_color.dart';
import 'package:pulse_chat/core/constant/app_icons.dart';
import 'package:pulse_chat/core/constant/string_constants.dart';
import 'package:pulse_chat/features/auth/domain/entities/user_entity.dart';
import 'package:pulse_chat/features/chat/presentation/providers/chat_providers.dart';
import 'package:pulse_chat/features/chat/presentation/widgets/chat_input_bar.dart';
import 'package:pulse_chat/features/chat/presentation/widgets/message_bubble.dart';
import 'package:pulse_chat/features/group/domain/entities/group_entity.dart';
import 'package:pulse_chat/features/group/presentation/providers/group_providers.dart';
import 'package:pulse_chat/features/home/presentation/providers/home_providers.dart';

class GroupChatScreen extends ConsumerStatefulWidget {
  final String groupId;
  final String groupName;

  const GroupChatScreen({
    super.key,
    required this.groupId,
    required this.groupName,
  });

  @override
  ConsumerState<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends ConsumerState<GroupChatScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.groupName),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        actions: [
          IconButton(
            icon: const Icon(AppIcons.group),
            tooltip: StringConstants.viewMembers,
            onPressed: () => _showViewMembersSheet(context),
          ),
          IconButton(
            icon: const Icon(AppIcons.personAdd),
            tooltip: StringConstants.addMembers,
            onPressed: () => _showAddMembersSheet(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: chatState.messages.isEmpty
                ? const Center(
                    child: Text(
                      StringConstants.noGroupMessages,
                      style: TextStyle(color: AppColors.grey),
                    ),
                  )
                : ListView.builder(
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

  void _showAddMembersSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _AddMembersSheet(groupId: widget.groupId),
    );
  }

  void _showViewMembersSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _ViewMembersSheet(groupId: widget.groupId),
    );
  }
}

class _AddMembersSheet extends ConsumerStatefulWidget {
  final String groupId;

  const _AddMembersSheet({required this.groupId});

  @override
  ConsumerState<_AddMembersSheet> createState() => _AddMembersSheetState();
}

class _AddMembersSheetState extends ConsumerState<_AddMembersSheet> {
  final Set<String> _selectedIds = {};
  List<UserEntity> _allUsers = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    final users = await ref.read(getAllUsersUseCaseProvider).call();
    setState(() {
      _allUsers = users;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.grey300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Text(
              StringConstants.addMembers,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      controller: scrollController,
                      itemCount: _allUsers.length,
                      itemBuilder: (context, index) {
                        final user = _allUsers[index];
                        final isSelected = _selectedIds.contains(user.id);
                        return CheckboxListTile(
                          value: isSelected,
                          onChanged: (val) {
                            setState(() {
                              if (val == true) {
                                _selectedIds.add(user.id);
                              } else {
                                _selectedIds.remove(user.id);
                              }
                            });
                          },
                          title: Text(user.name),
                          subtitle: Text(user.email),
                          secondary: CircleAvatar(
                            backgroundColor: AppColors.primary,
                            child: Text(
                              user.name.isNotEmpty
                                  ? user.name[0].toUpperCase()
                                  : 'U',
                              style: const TextStyle(color: AppColors.white),
                            ),
                          ),
                          activeColor: AppColors.primary,
                        );
                      },
                    ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                ),
                onPressed: _selectedIds.isNotEmpty
                    ? () async {
                        await ref
                            .read(groupProvider.notifier)
                            .addMembersToGroup(
                              widget.groupId,
                              _selectedIds.toList(),
                            );
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '${_selectedIds.length} ${StringConstants.members} added',
                              ),
                            ),
                          );
                        }
                      }
                    : null,
                child: Text('${StringConstants.add} (${_selectedIds.length})'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ViewMembersSheet extends ConsumerStatefulWidget {
  final String groupId;

  const _ViewMembersSheet({required this.groupId});

  @override
  ConsumerState<_ViewMembersSheet> createState() => _ViewMembersSheetState();
}

class _ViewMembersSheetState extends ConsumerState<_ViewMembersSheet> {
  List<GroupMember> _members = [];
  List<UserEntity> _allUsers = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    final members = await ref
        .read(groupProvider.notifier)
        .getMembers(widget.groupId);
    final users = await ref.read(getAllUsersUseCaseProvider).call();
    setState(() {
      _members = members;
      _allUsers = users;
      _loading = false;
    });
  }

  String _userName(String userId) {
    final user = _allUsers.where((u) => u.id == userId).firstOrNull;
    return user?.name ?? userId;
  }

  String _userEmail(String userId) {
    final user = _allUsers.where((u) => u.id == userId).firstOrNull;
    return user?.email ?? '';
  }

  Future<void> _confirmRemove(GroupMember member) async {
    final name = _userName(member.userId);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(StringConstants.removeMember),
        content: Text('${StringConstants.confirmRemoveMember} $name?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(StringConstants.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text(StringConstants.removeMember),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await ref
          .read(groupProvider.notifier)
          .removeMember(widget.groupId, member.userId);
      setState(() {
        _members.removeWhere((m) => m.userId == member.userId);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(StringConstants.memberRemoved)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.grey300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              '${StringConstants.viewMembers} (${_loading ? '...' : _members.length})',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _members.isEmpty
                  ? const Center(
                      child: Text(
                        StringConstants.noMembers,
                        style: TextStyle(color: AppColors.grey),
                      ),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      itemCount: _members.length,
                      itemBuilder: (context, index) {
                        final member = _members[index];
                        final name = _userName(member.userId);
                        final email = _userEmail(member.userId);
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.primary,
                            child: Text(
                              name.isNotEmpty ? name[0].toUpperCase() : 'U',
                              style: const TextStyle(color: AppColors.white),
                            ),
                          ),
                          title: Text(name),
                          subtitle: Text(
                            email.isNotEmpty ? email : member.role,
                          ),
                          trailing: member.role == 'admin'
                              ? Chip(
                                  label: const Text('Admin'),
                                  backgroundColor: AppColors.primary.withValues(
                                    alpha: 0.1,
                                  ),
                                  labelStyle: const TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 12,
                                  ),
                                )
                              : IconButton(
                                  icon: const Icon(
                                    Icons.remove_circle_outline,
                                    color: AppColors.error,
                                  ),
                                  tooltip: StringConstants.removeMember,
                                  onPressed: () => _confirmRemove(member),
                                ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
