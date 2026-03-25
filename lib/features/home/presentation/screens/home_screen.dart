import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pulse_chat/core/constant/app_color.dart';
import 'package:pulse_chat/core/constant/app_icons.dart';
import 'package:pulse_chat/core/constant/string_constants.dart';
import 'package:pulse_chat/core/network/connectivity_service.dart';
import 'package:pulse_chat/features/auth/presentation/providers/auth_providers.dart';
import 'package:pulse_chat/features/auth/domain/entities/user_entity.dart';
import 'package:pulse_chat/features/group/domain/entities/group_entity.dart';
import 'package:pulse_chat/features/group/presentation/providers/group_providers.dart';
import 'package:pulse_chat/features/home/presentation/providers/home_providers.dart';

enum HomeFilter { all, contacts, groups }

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  HomeFilter _selectedFilter = HomeFilter.all;
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(groupProvider.notifier).loadGroups();
    });
  }

  @override
  Widget build(BuildContext context) {
    final connectivity = ref.watch(connectivityStreamProvider);
    final contactsAsync = ref.watch(contactsProvider);
    final groupState = ref.watch(groupProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(StringConstants.appName),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        actions: [
          if (_selectedFilter == HomeFilter.contacts ||
              _selectedFilter == HomeFilter.all)
            IconButton(
              icon: const Icon(AppIcons.personAdd),
              onPressed: () => _showFindUsersSheet(context),
              tooltip: StringConstants.findUsers,
            ),
          connectivity.when(
            data: (isConnected) => Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Icon(
                isConnected ? AppIcons.wifi : AppIcons.wifiOff,
                color: isConnected ? AppColors.online : AppColors.offline,
              ),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const Padding(
              padding: EdgeInsets.only(right: 4),
              child: Icon(AppIcons.wifiOff, color: AppColors.error),
            ),
          ),
          IconButton(
            icon: const Icon(AppIcons.logout),
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: HomeFilter.values.map((filter) {
                final isSelected = _selectedFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(_filterLabel(filter)),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _selectedFilter = filter),
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: isSelected ? AppColors.white : AppColors.grey600,
                    ),
                    checkmarkColor: AppColors.white,
                    backgroundColor: AppColors.grey100,
                  ),
                );
              }).toList(),
            ),
          ),
          if (_hasDataForCurrentFilter(contactsAsync, groupState.groups))
            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: _selectedFilter == HomeFilter.contacts
                      ? StringConstants.searchContacts
                      : _selectedFilter == HomeFilter.groups
                      ? StringConstants.searchGroups
                      : StringConstants.searchAll,
                  prefixIcon: const Icon(AppIcons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: AppColors.grey100,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                ),
                onChanged: (val) =>
                    setState(() => _searchQuery = val.trim().toLowerCase()),
              ),
            ),
          const Divider(height: 1),
          Expanded(child: _buildContent(contactsAsync, groupState.groups)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () => _showCreateGroupDialog(context),
        child: const Icon(AppIcons.groupAdd, color: AppColors.white),
      ),
    );
  }

  String _filterLabel(HomeFilter filter) {
    switch (filter) {
      case HomeFilter.all:
        return StringConstants.all;
      case HomeFilter.contacts:
        return StringConstants.contacts;
      case HomeFilter.groups:
        return StringConstants.groups;
    }
  }

  bool _hasDataForCurrentFilter(
    AsyncValue<List<UserEntity>> contactsAsync,
    List<GroupEntity> groups,
  ) {
    final contacts = contactsAsync.valueOrNull ?? [];
    switch (_selectedFilter) {
      case HomeFilter.contacts:
        return contacts.isNotEmpty;
      case HomeFilter.groups:
        return groups.isNotEmpty;
      case HomeFilter.all:
        final recentChats = ref.read(recentChatsProvider);
        return contacts.isNotEmpty ||
            groups.isNotEmpty ||
            recentChats.isNotEmpty;
    }
  }

  Widget _buildContent(
    AsyncValue<List<UserEntity>> contactsAsync,
    List<GroupEntity> groups,
  ) {
    if (contactsAsync is AsyncLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final allContacts = contactsAsync.valueOrNull ?? [];
    final contactIds = allContacts.map((c) => c.id).toSet();
    final recentChats = ref.watch(recentChatsProvider);
    // Unsaved recent chats = chatted users not yet in contacts
    final unsavedChats = recentChats
        .where((u) => !contactIds.contains(u.id))
        .toList();

    final contacts = _searchQuery.isEmpty
        ? allContacts
        : allContacts
              .where(
                (u) =>
                    u.name.toLowerCase().contains(_searchQuery) ||
                    u.email.toLowerCase().contains(_searchQuery),
              )
              .toList();
    final filteredUnsaved = _searchQuery.isEmpty
        ? unsavedChats
        : unsavedChats
              .where(
                (u) =>
                    u.name.toLowerCase().contains(_searchQuery) ||
                    u.email.toLowerCase().contains(_searchQuery),
              )
              .toList();
    final filteredGroups = _searchQuery.isEmpty
        ? groups
        : groups
              .where(
                (g) =>
                    g.name.toLowerCase().contains(_searchQuery) ||
                    (g.description ?? '').toLowerCase().contains(_searchQuery),
              )
              .toList();

    final List<Widget> items = [];

    if (_selectedFilter == HomeFilter.all ||
        _selectedFilter == HomeFilter.contacts) {
      for (final user in contacts) {
        items.add(
          _ContactTile(user: user, onRemove: () => _confirmRemoveContact(user)),
        );
      }
    }

    // Show unsaved recent chats only in All tab
    if (_selectedFilter == HomeFilter.all) {
      for (final user in filteredUnsaved) {
        items.add(
          _UnsavedChatTile(
            user: user,
            onSave: () => _confirmAddUnsavedContact(user),
          ),
        );
      }
    }

    if (_selectedFilter == HomeFilter.all ||
        _selectedFilter == HomeFilter.groups) {
      for (final group in filteredGroups) {
        items.add(_GroupTile(group: group));
      }
    }

    if (items.isEmpty) {
      // Show search-no-match message only when there IS underlying data
      final hasContactData =
          (_selectedFilter == HomeFilter.all ||
              _selectedFilter == HomeFilter.contacts) &&
          (allContacts.isNotEmpty || unsavedChats.isNotEmpty);
      final hasGroupData =
          (_selectedFilter == HomeFilter.all ||
              _selectedFilter == HomeFilter.groups) &&
          groups.isNotEmpty;
      final isSearchMiss =
          _searchQuery.isNotEmpty && (hasContactData || hasGroupData);

      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSearchMiss
                  ? AppIcons.search
                  : _selectedFilter == HomeFilter.groups
                  ? AppIcons.group
                  : _selectedFilter == HomeFilter.contacts
                  ? AppIcons.person
                  : AppIcons.message,
              size: 64,
              color: AppColors.grey300,
            ),
            const SizedBox(height: 16),
            Text(
              isSearchMiss
                  ? StringConstants.noMatchFound
                  : _selectedFilter == HomeFilter.groups
                  ? StringConstants.noGroupsYet
                  : _selectedFilter == HomeFilter.contacts
                  ? StringConstants.noUsersYet
                  : StringConstants.noItemsFound,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: AppColors.grey500),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, index) => items[index],
    );
  }

  void _showFindUsersSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _FindUsersSheet(
        onContactAdded: () => ref.invalidate(contactsProvider),
      ),
    );
  }

  void _confirmRemoveContact(UserEntity user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(StringConstants.removeFromContacts),
        content: Text(
          '${StringConstants.confirmRemoveContact}\n\n${user.name}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(StringConstants.no),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(removeContactUseCaseProvider).call(user.id);
              ref.invalidate(contactsProvider);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(StringConstants.removedFromContacts),
                  ),
                );
              }
            },
            child: const Text(StringConstants.yes),
          ),
        ],
      ),
    );
  }

  void _confirmAddUnsavedContact(UserEntity user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(StringConstants.addToContacts),
        content: Text('${StringConstants.confirmAddContact}\n\n${user.name}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(StringConstants.no),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(addContactUseCaseProvider).call(user.id);
              // Remove from recent chats since now saved
              final chats = ref.read(recentChatsProvider);
              ref.read(recentChatsProvider.notifier).state = chats
                  .where((u) => u.id != user.id)
                  .toList();
              ref.invalidate(contactsProvider);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(StringConstants.savedToContacts),
                  ),
                );
              }
            },
            child: const Text(StringConstants.yes),
          ),
        ],
      ),
    );
  }

  void _showCreateGroupDialog(BuildContext context) {
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

// --- Find Users Bottom Sheet ---
class _FindUsersSheet extends ConsumerStatefulWidget {
  final VoidCallback onContactAdded;

  const _FindUsersSheet({required this.onContactAdded});

  @override
  ConsumerState<_FindUsersSheet> createState() => _FindUsersSheetState();
}

class _FindUsersSheetState extends ConsumerState<_FindUsersSheet> {
  final _searchController = TextEditingController();
  List<UserEntity> _allUsers = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    final users = await ref.read(getAllUsersUseCaseProvider).call();
    setState(() {
      _allUsers = users;
      _loading = false;
    });
  }

  List<UserEntity> get _filteredUsers {
    final contacts = ref.read(contactsProvider).valueOrNull ?? [];
    final contactIds = contacts.map((c) => c.id).toSet();
    final nonContacts = _allUsers
        .where((u) => !contactIds.contains(u.id))
        .toList();
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return nonContacts;
    return nonContacts
        .where(
          (u) =>
              u.name.toLowerCase().contains(query) ||
              u.email.toLowerCase().contains(query),
        )
        .toList();
  }

  void _confirmAddContact(BuildContext context, UserEntity user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(StringConstants.addToContacts),
        content: Text('${StringConstants.confirmAddContact}\n\n${user.name}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(StringConstants.no),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(addContactUseCaseProvider).call(user.id);
              widget.onContactAdded();
              setState(() {}); // refresh list to hide added user
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(StringConstants.savedToContacts),
                  ),
                );
              }
            },
            child: const Text(StringConstants.yes),
          ),
        ],
      ),
    );
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
              StringConstants.findUsers,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: StringConstants.searchUsers2,
                prefixIcon: const Icon(AppIcons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: AppColors.grey100,
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredUsers.isEmpty
                  ? Center(
                      child: Text(
                        _searchController.text.isEmpty
                            ? StringConstants.noUsersFound
                            : StringConstants.noMatchFound,
                        style: TextStyle(color: AppColors.grey500),
                      ),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      itemCount: _filteredUsers.length,
                      itemBuilder: (context, index) {
                        final user = _filteredUsers[index];
                        return _SearchUserTile(
                          user: user,
                          onAdd: () => _confirmAddContact(context, user),
                          onChat: () {
                            // Track as recent chat without saving as contact
                            final recentChats = ref.read(
                              recentChatsProvider.notifier,
                            );
                            final current = ref.read(recentChatsProvider);
                            if (!current.any((u) => u.id == user.id)) {
                              recentChats.state = [...current, user];
                            }
                            Navigator.pop(context);
                            context.push('/chat', extra: user.name);
                          },
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

class _SearchUserTile extends StatelessWidget {
  final UserEntity user;
  final VoidCallback onAdd;
  final VoidCallback onChat;

  const _SearchUserTile({
    required this.user,
    required this.onAdd,
    required this.onChat,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppColors.primary,
        backgroundImage: user.avatarUrl != null
            ? NetworkImage(user.avatarUrl!)
            : null,
        child: user.avatarUrl == null
            ? Text(
                user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                style: const TextStyle(color: AppColors.white),
              )
            : null,
      ),
      title: Text(user.name),
      subtitle: Text(user.email, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(AppIcons.personAdd, color: AppColors.primary),
            onPressed: onAdd,
            tooltip: StringConstants.addToContacts,
          ),
          IconButton(
            icon: const Icon(AppIcons.message, color: AppColors.primary),
            onPressed: onChat,
            tooltip: StringConstants.chat,
          ),
        ],
      ),
    );
  }
}

// --- Contact tile ---
class _ContactTile extends StatelessWidget {
  final UserEntity user;
  final VoidCallback onRemove;

  const _ContactTile({required this.user, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Stack(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.primary,
            backgroundImage: user.avatarUrl != null
                ? NetworkImage(user.avatarUrl!)
                : null,
            child: user.avatarUrl == null
                ? Text(
                    user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                    style: const TextStyle(color: AppColors.white),
                  )
                : null,
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: user.isOnline ? AppColors.online : AppColors.grey300,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.white, width: 2),
              ),
            ),
          ),
        ],
      ),
      title: Text(user.name),
      subtitle: Text(user.email, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: PopupMenuButton<String>(
        onSelected: (value) {
          if (value == 'remove') onRemove();
        },
        itemBuilder: (_) => [
          const PopupMenuItem(
            value: 'remove',
            child: Text(StringConstants.removeFromContacts),
          ),
        ],
      ),
      onTap: () => context.push('/chat', extra: user.name),
    );
  }
}

// --- Unsaved chat tile (shown in All tab with save option) ---
class _UnsavedChatTile extends StatelessWidget {
  final UserEntity user;
  final VoidCallback onSave;

  const _UnsavedChatTile({required this.user, required this.onSave});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppColors.grey,
        backgroundImage: user.avatarUrl != null
            ? NetworkImage(user.avatarUrl!)
            : null,
        child: user.avatarUrl == null
            ? Text(
                user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                style: const TextStyle(color: AppColors.white),
              )
            : null,
      ),
      title: Text(user.name),
      subtitle: Text(user.email, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: IconButton(
        icon: const Icon(AppIcons.personAdd, color: AppColors.primary),
        tooltip: StringConstants.addToContacts,
        onPressed: onSave,
      ),
      onTap: () => context.push('/chat', extra: user.name),
    );
  }
}

// --- Create Group Bottom Sheet ---
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
            // Color picker
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
            // Members
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

// --- Group Tile ---
class _GroupTile extends StatelessWidget {
  final GroupEntity group;

  const _GroupTile({required this.group});

  @override
  Widget build(BuildContext context) {
    final groupColor = group.color != null
        ? Color(group.color!)
        : AppColors.primaryLight;
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: groupColor,
        backgroundImage: group.avatarUrl != null
            ? NetworkImage(group.avatarUrl!)
            : null,
        child: group.avatarUrl == null
            ? Text(
                group.name.isNotEmpty ? group.name[0].toUpperCase() : 'G',
                style: const TextStyle(color: AppColors.white),
              )
            : null,
      ),
      title: Text(group.name),
      subtitle: Text(
        group.description ?? StringConstants.noDescription,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(AppIcons.group, size: 16, color: AppColors.grey),
          const SizedBox(width: 4),
          Text(
            '${group.members.length}',
            style: TextStyle(color: AppColors.grey600, fontSize: 12),
          ),
        ],
      ),
      onTap: () => context.push('/group/${group.id}', extra: group.name),
    );
  }
}
