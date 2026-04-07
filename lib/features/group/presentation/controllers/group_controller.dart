import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulse_chat/features/group/domain/entities/group_entity.dart';
import 'package:pulse_chat/features/group/domain/usecases/group_usecases.dart';
import 'package:pulse_chat/features/group/presentation/controllers/group_state.dart';

class GroupController extends StateNotifier<GroupState> {
  final GetGroupsUseCase _getGroupsUseCase;
  final CreateGroupUseCase _createGroupUseCase;
  final AddMemberUseCase _addMemberUseCase;
  final RemoveMemberUseCase _removeMemberUseCase;
  final GetMembersUseCase _getMembersUseCase;

  GroupController({
    required GetGroupsUseCase getGroupsUseCase,
    required CreateGroupUseCase createGroupUseCase,
    required AddMemberUseCase addMemberUseCase,
    required RemoveMemberUseCase removeMemberUseCase,
    required GetMembersUseCase getMembersUseCase,
  }) : _getGroupsUseCase = getGroupsUseCase,
       _createGroupUseCase = createGroupUseCase,
       _addMemberUseCase = addMemberUseCase,
       _removeMemberUseCase = removeMemberUseCase,
       _getMembersUseCase = getMembersUseCase,
       super(const GroupState());

  Future<void> loadGroups() async {
    state = state.copyWith(isLoading: true);
    try {
      final groups = await _getGroupsUseCase();
      state = state.copyWith(groups: groups, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> createGroup(
    String name,
    String description,
    List<String> memberIds, {
    int? color,
    String? avatarUrl,
  }) async {
    try {
      final groupId = DateTime.now().millisecondsSinceEpoch.toString();
      final group = GroupEntity(
        id: groupId,
        name: name,
        description: description,
        color: color,
        avatarUrl: avatarUrl,
        createdBy: 'me',
        createdAt: DateTime.now(),
      );
      await _createGroupUseCase(group);

      final members = <GroupMember>[];
      for (final userId in memberIds) {
        final member = GroupMember(userId: userId, joinedAt: DateTime.now());
        await _addMemberUseCase(groupId, member);
        members.add(member);
      }

      final groupWithMembers = GroupEntity(
        id: groupId,
        name: name,
        description: description,
        color: color,
        avatarUrl: avatarUrl,
        createdBy: 'me',
        createdAt: group.createdAt,
        members: members,
      );
      state = state.copyWith(groups: [...state.groups, groupWithMembers]);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> addMembersToGroup(String groupId, List<String> userIds) async {
    try {
      for (final userId in userIds) {
        final member = GroupMember(userId: userId, joinedAt: DateTime.now());
        await _addMemberUseCase(groupId, member);
      }
      await loadGroups();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<List<GroupMember>> getMembers(String groupId) async {
    try {
      return await _getMembersUseCase(groupId);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return [];
    }
  }

  Future<void> removeMember(String groupId, String userId) async {
    try {
      await _removeMemberUseCase(groupId, userId);
      await loadGroups();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}
