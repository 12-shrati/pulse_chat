import 'package:pulse_chat/features/group/data/datasources/group_local_datasource.dart';
import 'package:pulse_chat/features/group/data/models/group_model.dart';
import 'package:pulse_chat/features/group/domain/entities/group_entity.dart';
import 'package:pulse_chat/features/group/domain/repositories/group_repository.dart';

class GroupRepositoryImpl implements GroupRepository {
  final GroupLocalDataSource _localDataSource;

  GroupRepositoryImpl(this._localDataSource);

  @override
  Future<List<GroupEntity>> getGroups() async {
    final groups = await _localDataSource.getGroups();
    final result = <GroupEntity>[];
    for (final group in groups) {
      final members = await _localDataSource.getMembers(group.id);
      result.add(
        GroupModel(
          id: group.id,
          name: group.name,
          description: group.description,
          avatarUrl: group.avatarUrl,
          color: group.color,
          createdBy: group.createdBy,
          createdAt: group.createdAt,
          members: members,
        ),
      );
    }
    return result;
  }

  @override
  Future<GroupEntity?> getGroupById(String id) async {
    final group = await _localDataSource.getGroupById(id);
    if (group == null) return null;
    final members = await _localDataSource.getMembers(id);
    return GroupModel(
      id: group.id,
      name: group.name,
      description: group.description,
      avatarUrl: group.avatarUrl,
      color: group.color,
      createdBy: group.createdBy,
      createdAt: group.createdAt,
      members: members,
    );
  }

  @override
  Future<void> createGroup(GroupEntity group) {
    final model = GroupModel(
      id: group.id,
      name: group.name,
      description: group.description,
      avatarUrl: group.avatarUrl,
      color: group.color,
      createdBy: group.createdBy,
      createdAt: group.createdAt,
    );
    return _localDataSource.insertGroup(model);
  }

  @override
  Future<void> updateGroup(GroupEntity group) {
    final model = GroupModel(
      id: group.id,
      name: group.name,
      description: group.description,
      avatarUrl: group.avatarUrl,
      color: group.color,
      createdBy: group.createdBy,
      createdAt: group.createdAt,
    );
    return _localDataSource.insertGroup(model);
  }

  @override
  Future<void> deleteGroup(String id) => _localDataSource.deleteGroup(id);

  @override
  Future<void> addMember(String groupId, GroupMember member) {
    final model = GroupMemberModel(
      userId: member.userId,
      role: member.role,
      joinedAt: member.joinedAt,
    );
    return _localDataSource.addMember(groupId, model);
  }

  @override
  Future<void> removeMember(String groupId, String userId) =>
      _localDataSource.removeMember(groupId, userId);

  @override
  Future<List<GroupMember>> getMembers(String groupId) async {
    final members = await _localDataSource.getMembers(groupId);
    return members;
  }
}
