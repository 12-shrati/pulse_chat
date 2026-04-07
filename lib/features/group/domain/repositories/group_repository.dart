import 'package:pulse_chat/features/group/domain/entities/group_entity.dart';

abstract class GroupRepository {
  Future<List<GroupEntity>> getGroups();
  Future<GroupEntity?> getGroupById(String id);
  Future<void> createGroup(GroupEntity group);
  Future<void> updateGroup(GroupEntity group);
  Future<void> deleteGroup(String id);
  Future<void> addMember(String groupId, GroupMember member);
  Future<void> removeMember(String groupId, String userId);
  Future<List<GroupMember>> getMembers(String groupId);
}
