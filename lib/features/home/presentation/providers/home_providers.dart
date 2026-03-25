import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulse_chat/features/auth/domain/entities/user_entity.dart';
import 'package:pulse_chat/features/auth/domain/usecases/auth_usecases.dart';
import 'package:pulse_chat/features/auth/presentation/providers/auth_providers.dart';

final getAllUsersUseCaseProvider = Provider<GetAllUsersUseCase>((ref) {
  return GetAllUsersUseCase(ref.watch(authRepositoryProvider));
});

final getContactsUseCaseProvider = Provider<GetContactsUseCase>((ref) {
  return GetContactsUseCase(ref.watch(authRepositoryProvider));
});

final addContactUseCaseProvider = Provider<AddContactUseCase>((ref) {
  return AddContactUseCase(ref.watch(authRepositoryProvider));
});

final removeContactUseCaseProvider = Provider<RemoveContactUseCase>((ref) {
  return RemoveContactUseCase(ref.watch(authRepositoryProvider));
});

final searchUsersUseCaseProvider = Provider<SearchUsersUseCase>((ref) {
  return SearchUsersUseCase(ref.watch(authRepositoryProvider));
});

final allUsersProvider = FutureProvider<List<UserEntity>>((ref) async {
  final useCase = ref.watch(getAllUsersUseCaseProvider);
  return useCase();
});

final contactsProvider = FutureProvider<List<UserEntity>>((ref) async {
  final useCase = ref.watch(getContactsUseCaseProvider);
  return useCase();
});

final recentChatsProvider = StateProvider<List<UserEntity>>((ref) => []);
