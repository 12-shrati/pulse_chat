import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:pulse_chat/core/constant/server_config.dart';

class ApiService {
  final String _baseUrl;

  ApiService({String? baseUrl})
    : _baseUrl = baseUrl ?? ServerConfig.httpBaseUrl;

  /// Register a user on the server.
  Future<bool> registerUser({
    required String id,
    required String name,
    required String email,
    String? avatarUrl,
    String? passwordHash,
  }) async {
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 5);
      final request = await client.postUrl(Uri.parse('$_baseUrl/register'));
      request.headers.contentType = ContentType.json;
      request.write(
        jsonEncode({
          'id': id,
          'name': name,
          'email': email,
          'avatarUrl': ?avatarUrl,
          'passwordHash': ?passwordHash,
        }),
      );
      final response = await request.close();
      client.close();
      debugPrint('[ApiService] registerUser($name) -> ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('[ApiService] registerUser FAILED: $e');
      return false;
    }
  }

  /// Fetch all registered users from the server.
  Future<List<Map<String, dynamic>>> fetchUsers() async {
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 5);
      final request = await client.getUrl(Uri.parse('$_baseUrl/users'));
      final response = await request.close();
      if (response.statusCode == 200) {
        final body = await response.transform(utf8.decoder).join();
        final list = jsonDecode(body) as List<dynamic>;
        client.close();
        debugPrint('[ApiService] fetchUsers -> ${list.length} users');
        return list.cast<Map<String, dynamic>>();
      }
      client.close();
      debugPrint('[ApiService] fetchUsers -> status ${response.statusCode}');
      return [];
    } catch (e) {
      debugPrint('[ApiService] fetchUsers FAILED: $e');
      return [];
    }
  }

  /// Login a user via the server.
  /// Returns user data map on success, null on failure.
  Future<Map<String, dynamic>?> loginUser({
    required String email,
    required String passwordHash,
  }) async {
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 5);
      final request = await client.postUrl(Uri.parse('$_baseUrl/login'));
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode({'email': email, 'passwordHash': passwordHash}));
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      client.close();
      debugPrint('[ApiService] loginUser($email) -> ${response.statusCode}');
      if (response.statusCode == 200) {
        return jsonDecode(body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      debugPrint('[ApiService] loginUser FAILED: $e');
      return null;
    }
  }
}
