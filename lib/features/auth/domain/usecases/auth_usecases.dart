import 'package:pulse_chat/features/auth/domain/entities/user_entity.dart';
import 'package:pulse_chat/features/auth/domain/repositories/auth_repository.dart';

class LoginUseCase {
  final AuthRepository _repository;

  LoginUseCase(this._repository);

  Future<UserEntity?> call(String email, String password) {
    return _repository.login(email, password);
  }
}

class RegisterUseCase {
  final AuthRepository _repository;

  RegisterUseCase(this._repository);

  Future<UserEntity?> call(String name, String email, String password) {
    return _repository.register(name, email, password);
  }
}

class LogoutUseCase {
  final AuthRepository _repository;

  LogoutUseCase(this._repository);

  Future<void> call() {
    return _repository.logout();
  }
}

class GetCurrentUserUseCase {
  final AuthRepository _repository;

  GetCurrentUserUseCase(this._repository);

  Future<UserEntity?> call() {
    return _repository.getCurrentUser();
  }
}

class GetAllUsersUseCase {
  final AuthRepository _repository;

  GetAllUsersUseCase(this._repository);

  Future<List<UserEntity>> call() {
    return _repository.getAllUsers();
  }
}

class SearchUsersUseCase {
  final AuthRepository _repository;

  SearchUsersUseCase(this._repository);

  Future<List<UserEntity>> call(String query) {
    return _repository.searchUsers(query);
  }
}

class AddContactUseCase {
  final AuthRepository _repository;

  AddContactUseCase(this._repository);

  Future<void> call(String contactId) {
    return _repository.addContact(contactId);
  }
}

class RemoveContactUseCase {
  final AuthRepository _repository;

  RemoveContactUseCase(this._repository);

  Future<void> call(String contactId) {
    return _repository.removeContact(contactId);
  }
}

class GetContactsUseCase {
  final AuthRepository _repository;

  GetContactsUseCase(this._repository);

  Future<List<UserEntity>> call() {
    return _repository.getContacts();
  }
}

class IsContactUseCase {
  final AuthRepository _repository;

  IsContactUseCase(this._repository);

  Future<bool> call(String contactId) {
    return _repository.isContact(contactId);
  }
}
