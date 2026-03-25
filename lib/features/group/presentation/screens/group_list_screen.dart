import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pulse_chat/core/constant/app_color.dart';
import 'package:pulse_chat/core/constant/app_icons.dart';
import 'package:pulse_chat/core/constant/string_constants.dart';
import 'package:pulse_chat/features/auth/domain/entities/user_entity.dart';
import 'package:pulse_chat/features/group/presentation/providers/group_providers.dart';
import 'package:pulse_chat/features/group/presentation/widgets/group_tile.dart';
import 'package:pulse_chat/features/home/presentation/providers/home_providers.dart';

class GroupListScreen extends ConsumerStatefulWidget {
  const GroupListScreen({super.key});

  @override
  ConsumerState<GroupListScreen> createState() => _GroupListScreenState();
}

class _GroupListScreenState extends ConsumerState<GroupListScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(groupProvider.notifier).loadGroups());
  }

  @override
  Widget build(BuildContext context) {
    final groupState = ref.watch(groupProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(StringConstants.groups),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
      ),
      body: groupState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : groupState.groups.isEmpty
          ? const Center(
              child: Text(
                StringConstants.noGroupsYet,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.grey),
              ),
            )
          : ListView.separated(
              itemCount: groupState.groups.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final group = groupState.groups[index];
                return GroupTile(
                  group: group,
                  onTap: () =>
                      context.push('/group/${group.id}', extra: group.name),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () => _showCreateGroupSheet(context),
        child: const Icon(AppIcons.groupAdd, color: AppColors.white),
      ),
    );
  }

  void _showCreateGroupSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _CreateGroupSheet(
        onCreated: () {
          ref.read(groupProvider.notifier).loadGroups();
        },
      ),
    );
  }
}

class _CreateGroupSheet extends ConsumerStatefulWidget {
  final VoidCallback onCreated;

  const _CreateGroupSheet({required this.onCreated});

  @override
  ConsumerState<_CreateGroupSheet> createState() => _CreateGroupSheetState();
}

class _CreateGroupSheetState extends ConsumerState<_CreateGroupSheet> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final Set<String> _selectedMemberIds = {};
  int _selectedColorValue = AppColors.primary.toARGB32();
  List<UserEntity> _allUsers = [];
  bool _loading = true;

  static const List<Color> _colorOptions = [
    AppColors.primary,
    Color(0xFF00BCD4),
    Color(0xFF4CAF50),
    Color(0xFFFF9800),
    Color(0xFFE91E63),
    Color(0xFF9C27B0),
    Color(0xFF3F51B5),
    Color(0xFF009688),
  ];

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
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
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
              StringConstants.createGroup,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: StringConstants.groupName,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descController,
              decoration: InputDecoration(
                labelText: StringConstants.description,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              StringConstants.groupColor,
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _colorOptions.map((color) {
                final isSelected = _selectedColorValue == color.toARGB32();
                return GestureDetector(
                  onTap: () =>
                      setState(() => _selectedColorValue = color.toARGB32()),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(color: AppColors.black87, width: 3)
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(
                            Icons.check,
                            color: AppColors.white,
                            size: 18,
                          )
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Text(
              '${StringConstants.selectMembers} (${_selectedMemberIds.length} selected)',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _allUsers.isEmpty
                  ? Center(
                      child: Text(
                        StringConstants.noUsersYet,
                        style: TextStyle(color: AppColors.grey500),
                      ),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      itemCount: _allUsers.length,
                      itemBuilder: (context, index) {
                        final user = _allUsers[index];
                        final isSelected = _selectedMemberIds.contains(user.id);
                        return CheckboxListTile(
                          value: isSelected,
                          onChanged: (val) {
                            setState(() {
                              if (val == true) {
                                _selectedMemberIds.add(user.id);
                              } else {
                                _selectedMemberIds.remove(user.id);
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
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(StringConstants.cancel),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                    ),
                    onPressed:
                        _selectedMemberIds.length >= 2 &&
                            _nameController.text.trim().isNotEmpty
                        ? () {
                            ref
                                .read(groupProvider.notifier)
                                .createGroup(
                                  _nameController.text.trim(),
                                  _descController.text.trim(),
                                  _selectedMemberIds.toList(),
                                  color: _selectedColorValue,
                                );
                            widget.onCreated();
                            Navigator.pop(context);
                          }
                        : null,
                    child: const Text(StringConstants.create),
                  ),
                ),
              ],
            ),
            if (_selectedMemberIds.length < 2)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  StringConstants.selectAtLeast2,
                  style: TextStyle(color: AppColors.error, fontSize: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
