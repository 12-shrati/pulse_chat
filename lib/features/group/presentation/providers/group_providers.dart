import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulse_chat/core/database/database_provider.dart';
import 'package:pulse_chat/features/group/data/datasources/group_local_datasource.dart';
import 'package:pulse_chat/features/group/data/repositories/group_repository_impl.dart';
import 'package:pulse_chat/features/group/domain/repositories/group_repository.dart';
import 'package:pulse_chat/features/group/domain/usecases/group_usecases.dart';
import 'package:pulse_chat/features/group/presentation/controllers/group_controller.dart';
import 'package:pulse_chat/features/group/presentation/controllers/group_state.dart';

final groupLocalDataSourceProvider = Provider<GroupLocalDataSource>((ref) {
  final db = ref.watch(databaseInstanceProvider);
  return GroupLocalDataSource(db);
});

final groupRepositoryProvider = Provider<GroupRepository>((ref) {
  return GroupRepositoryImpl(ref.watch(groupLocalDataSourceProvider));
});

final getGroupsUseCaseProvider = Provider<GetGroupsUseCase>((ref) {
  return GetGroupsUseCase(ref.watch(groupRepositoryProvider));
});

final createGroupUseCaseProvider = Provider<CreateGroupUseCase>((ref) {
  return CreateGroupUseCase(ref.watch(groupRepositoryProvider));
});

final addMemberUseCaseProvider = Provider<AddMemberUseCase>((ref) {
  return AddMemberUseCase(ref.watch(groupRepositoryProvider));
});

final removeMemberUseCaseProvider = Provider<RemoveMemberUseCase>((ref) {
  return RemoveMemberUseCase(ref.watch(groupRepositoryProvider));
});

final getMembersUseCaseProvider = Provider<GetMembersUseCase>((ref) {
  return GetMembersUseCase(ref.watch(groupRepositoryProvider));
});

final groupProvider = StateNotifierProvider<GroupController, GroupState>((ref) {
  return GroupController(
    getGroupsUseCase: ref.watch(getGroupsUseCaseProvider),
    createGroupUseCase: ref.watch(createGroupUseCaseProvider),
    addMemberUseCase: ref.watch(addMemberUseCaseProvider),
    removeMemberUseCase: ref.watch(removeMemberUseCaseProvider),
    getMembersUseCase: ref.watch(getMembersUseCaseProvider),
  );
});
