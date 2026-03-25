import 'package:pulse_chat/features/group/data/models/group_model.dart';
import 'package:sqflite/sqflite.dart';

class GroupLocalDataSource {
  final Database _db;

  GroupLocalDataSource(this._db);

  Future<List<GroupModel>> getGroups() async {
    final results = await _db.query('groups', orderBy: 'created_at DESC');
    return results.map((e) => GroupModel.fromJson(e)).toList();
  }

  Future<GroupModel?> getGroupById(String id) async {
    final results = await _db.query(
      'groups',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return GroupModel.fromJson(results.first);
  }

  Future<void> insertGroup(GroupModel group) async {
    await _db.insert(
      'groups',
      group.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteGroup(String id) async {
    await _db.delete('groups', where: 'id = ?', whereArgs: [id]);
    await _db.delete('group_members', where: 'group_id = ?', whereArgs: [id]);
  }

  Future<void> addMember(String groupId, GroupMemberModel member) async {
    await _db.insert(
      'group_members',
      member.toJson(groupId),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> removeMember(String groupId, String userId) async {
    await _db.delete(
      'group_members',
      where: 'group_id = ? AND user_id = ?',
      whereArgs: [groupId, userId],
    );
  }

  Future<List<GroupMemberModel>> getMembers(String groupId) async {
    final results = await _db.query(
      'group_members',
      where: 'group_id = ?',
      whereArgs: [groupId],
    );
    return results.map((e) => GroupMemberModel.fromJson(e)).toList();
  }
}
