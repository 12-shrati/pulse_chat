import 'package:pulse_chat/features/auth/data/models/user_model.dart';
import 'package:sqflite/sqflite.dart';

class AuthLocalDataSource {
  final Database _db;

  AuthLocalDataSource(this._db);

  Future<void> saveUser(UserModel user) async {
    await _db.insert(
      'users',
      user.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<UserModel?> getUser(String id) async {
    final results = await _db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return UserModel.fromJson(results.first);
  }

  Future<UserModel?> getUserByEmail(String email) async {
    final results = await _db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return UserModel.fromJson(results.first);
  }

  Future<bool> emailExists(String email) async {
    final results = await _db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
      limit: 1,
    );
    return results.isNotEmpty;
  }

  Future<void> deleteUser(String id) async {
    await _db.delete('users', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<UserModel>> getAllUsers() async {
    final results = await _db.query('users', orderBy: 'name ASC');
    return results.map((e) => UserModel.fromJson(e)).toList();
  }

  Future<List<UserModel>> searchUsers(String query) async {
    final results = await _db.query(
      'users',
      where: 'name LIKE ? OR email LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'name ASC',
    );
    return results.map((e) => UserModel.fromJson(e)).toList();
  }

  // Contacts
  Future<void> addContact(String userId, String contactId) async {
    await _db.insert('contacts', {
      'user_id': userId,
      'contact_id': contactId,
      'added_at': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<void> removeContact(String userId, String contactId) async {
    await _db.delete(
      'contacts',
      where: 'user_id = ? AND contact_id = ?',
      whereArgs: [userId, contactId],
    );
  }

  Future<List<UserModel>> getContacts(String userId) async {
    final results = await _db.rawQuery(
      '''
      SELECT u.* FROM users u
      INNER JOIN contacts c ON u.id = c.contact_id
      WHERE c.user_id = ?
      ORDER BY u.name ASC
    ''',
      [userId],
    );
    return results.map((e) => UserModel.fromJson(e)).toList();
  }

  Future<bool> isContact(String userId, String contactId) async {
    final results = await _db.query(
      'contacts',
      where: 'user_id = ? AND contact_id = ?',
      whereArgs: [userId, contactId],
      limit: 1,
    );
    return results.isNotEmpty;
  }

  // Sessions
  Future<void> saveSession(String userId, DateTime expiresAt) async {
    await _db.delete('sessions');
    await _db.insert('sessions', {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'user_id': userId,
      'login_at': DateTime.now().toIso8601String(),
      'expires_at': expiresAt.toIso8601String(),
    });
  }

  Future<String?> getActiveSessionUserId() async {
    final now = DateTime.now().toIso8601String();
    final results = await _db.query(
      'sessions',
      where: 'expires_at > ?',
      whereArgs: [now],
      orderBy: 'login_at DESC',
      limit: 1,
    );
    if (results.isEmpty) return null;
    return results.first['user_id'] as String;
  }

  Future<void> clearSession() async {
    await _db.delete('sessions');
  }
}
