import 'package:pulse_chat/features/group/domain/entities/group_entity.dart';

class GroupState {
  final List<GroupEntity> groups;
  final bool isLoading;
  final String? error;

  const GroupState({
    this.groups = const [],
    this.isLoading = false,
    this.error,
  });

  GroupState copyWith({
    List<GroupEntity>? groups,
    bool? isLoading,
    String? error,
  }) {
    return GroupState(
      groups: groups ?? this.groups,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}
