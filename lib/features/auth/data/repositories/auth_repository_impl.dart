import 'dart:convert';

import 'package:pulse_chat/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:pulse_chat/features/auth/data/models/user_model.dart';
import 'package:pulse_chat/features/auth/domain/entities/user_entity.dart';
import 'package:pulse_chat/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthLocalDataSource _localDataSource;
  static const _sessionDays = 7;
  String? _currentUserId;

  AuthRepositoryImpl(this._localDataSource);

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    return base64Encode(bytes);
  }

  @override
  Future<UserEntity?> login(String email, String password) async {
    final existingUser = await _localDataSource.getUserByEmail(email);
    if (existingUser == null) return null;
    final hash = _hashPassword(password);
    if (existingUser.passwordHash != hash) return null;
    _currentUserId = existingUser.id;
    await _localDataSource.saveSession(
      existingUser.id,
      DateTime.now().add(const Duration(days: _sessionDays)),
    );
    return existingUser;
  }

  @override
  Future<UserEntity?> register(
    String name,
    String email,
    String password,
  ) async {
    final exists = await _localDataSource.emailExists(email);
    if (exists) return null;
    final user = UserModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      email: email,
      passwordHash: _hashPassword(password),
      isOnline: true,
    );
    await _localDataSource.saveUser(user);
    _currentUserId = user.id;
    await _localDataSource.saveSession(
      user.id,
      DateTime.now().add(const Duration(days: _sessionDays)),
    );
    return user;
  }

  @override
  Future<void> logout() async {
    if (_currentUserId != null) {
      _currentUserId = null;
    }
    await _localDataSource.clearSession();
  }

  @override
  Future<UserEntity?> getCurrentUser() async {
    if (_currentUserId == null) return null;
    return _localDataSource.getUser(_currentUserId!);
  }

  @override
  Future<String?> getCurrentUserId() async {
    return _currentUserId;
  }

  @override
  Future<bool> isLoggedIn() async {
    return _currentUserId != null;
  }

  @override
  Future<List<UserEntity>> getAllUsers() async {
    return _localDataSource.getAllUsers();
  }

  @override
  Future<List<UserEntity>> searchUsers(String query) async {
    return _localDataSource.searchUsers(query);
  }

  @override
  Future<UserEntity?> restoreSession() async {
    final userId = await _localDataSource.getActiveSessionUserId();
    if (userId == null) return null;
    final user = await _localDataSource.getUser(userId);
    if (user != null) {
      _currentUserId = userId;
    }
    return user;
  }

  @override
  Future<void> addContact(String contactId) async {
    if (_currentUserId == null) return;
    await _localDataSource.addContact(_currentUserId!, contactId);
  }

  @override
  Future<void> removeContact(String contactId) async {
    if (_currentUserId == null) return;
    await _localDataSource.removeContact(_currentUserId!, contactId);
  }

  @override
  Future<List<UserEntity>> getContacts() async {
    if (_currentUserId == null) return [];
    return _localDataSource.getContacts(_currentUserId!);
  }

  @override
  Future<bool> isContact(String contactId) async {
    if (_currentUserId == null) return false;
    return _localDataSource.isContact(_currentUserId!, contactId);
  }
}
