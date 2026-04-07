import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:pulse_chat/core/network/api_service.dart';
import 'package:pulse_chat/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:pulse_chat/features/auth/data/models/user_model.dart';
import 'package:pulse_chat/features/auth/domain/entities/user_entity.dart';
import 'package:pulse_chat/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthLocalDataSource _localDataSource;
  final ApiService _apiService;
  static const _sessionDays = 7;
  String? _currentUserId;

  AuthRepositoryImpl(this._localDataSource, this._apiService);

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    return base64Encode(bytes);
  }

  @override
  Future<UserEntity?> login(String email, String password) async {
    final hash = _hashPassword(password);

    // Try local database first
    final existingUser = await _localDataSource.getUserByEmail(email);
    if (existingUser != null) {
      if (existingUser.passwordHash != hash) return null;
      _currentUserId = existingUser.id;
      await _localDataSource.saveSession(
        existingUser.id,
        DateTime.now().add(const Duration(days: _sessionDays)),
      );
      // Ensure this user is registered on the server
      await _apiService.registerUser(
        id: existingUser.id,
        name: existingUser.name,
        email: existingUser.email,
        avatarUrl: existingUser.avatarUrl,
        passwordHash: hash,
      );
      return existingUser;
    }

    // User not found locally — try server login (supports cross-device auth)
    final serverUser = await _apiService.loginUser(
      email: email,
      passwordHash: hash,
    );
    if (serverUser == null) return null;

    // Save the user locally so future logins work offline
    final user = UserModel(
      id: serverUser['id'] as String,
      name: serverUser['name'] as String,
      email: serverUser['email'] as String,
      passwordHash: hash,
      avatarUrl: serverUser['avatarUrl'] as String?,
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

    // Register user on the server via HTTP so other devices can discover them
    final serverOk = await _apiService.registerUser(
      id: user.id,
      name: user.name,
      email: user.email,
      avatarUrl: user.avatarUrl,
      passwordHash: user.passwordHash,
    );
    if (!serverOk) {
      debugPrint(
        '[AuthRepo] WARNING: Server registration failed – login after reinstall may not work',
      );
    }

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

  /// Fetches all users from the server via HTTP and saves them locally.
  /// Returns the merged list of all users.
  @override
  Future<List<UserEntity>> syncUsersFromServer() async {
    debugPrint('[AuthRepo] syncUsersFromServer called');
    final serverUsers = await _apiService.fetchUsers();
    debugPrint('[AuthRepo] got ${serverUsers.length} users from server');

    // Save server users locally (skip password_hash since we don't have it)
    for (final userData in serverUsers) {
      final id = userData['id'] as String? ?? '';
      if (id.isEmpty) continue;
      // Don't overwrite existing local users (they may have password_hash)
      final existing = await _localDataSource.getUser(id);
      if (existing == null) {
        final user = UserModel(
          id: id,
          name: userData['name'] as String? ?? '',
          email: userData['email'] as String? ?? '',
          passwordHash: '',
          avatarUrl: userData['avatarUrl'] as String?,
        );
        await _localDataSource.saveUser(user);
      }
    }

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

  @override
  Future<void> deleteUser(String userId) async {
    await _localDataSource.deleteUser(userId);
  }
}
