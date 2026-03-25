import 'package:pulse_chat/features/auth/domain/entities/user_entity.dart';

abstract class AuthRepository {
  Future<UserEntity?> login(String email, String password);
  Future<UserEntity?> register(String name, String email, String password);
  Future<void> logout();
  Future<UserEntity?> getCurrentUser();
  Future<String?> getCurrentUserId();
  Future<bool> isLoggedIn();
  Future<List<UserEntity>> getAllUsers();
  Future<List<UserEntity>> searchUsers(String query);
  Future<UserEntity?> restoreSession();
  Future<void> addContact(String contactId);
  Future<void> removeContact(String contactId);
  Future<List<UserEntity>> getContacts();
  Future<bool> isContact(String contactId);
}
