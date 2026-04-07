import 'package:pulse_chat/features/group/domain/entities/group_entity.dart';
import 'package:pulse_chat/features/group/domain/repositories/group_repository.dart';

class GetGroupsUseCase {
  final GroupRepository _repository;

  GetGroupsUseCase(this._repository);

  Future<List<GroupEntity>> call() {
    return _repository.getGroups();
  }
}

class CreateGroupUseCase {
  final GroupRepository _repository;

  CreateGroupUseCase(this._repository);

  Future<void> call(GroupEntity group) {
    return _repository.createGroup(group);
  }
}

class AddMemberUseCase {
  final GroupRepository _repository;

  AddMemberUseCase(this._repository);

  Future<void> call(String groupId, GroupMember member) {
    return _repository.addMember(groupId, member);
  }
}

class RemoveMemberUseCase {
  final GroupRepository _repository;

  RemoveMemberUseCase(this._repository);

  Future<void> call(String groupId, String userId) {
    return _repository.removeMember(groupId, userId);
  }
}

class GetMembersUseCase {
  final GroupRepository _repository;

  GetMembersUseCase(this._repository);

  Future<List<GroupMember>> call(String groupId) {
    return _repository.getMembers(groupId);
  }
}
