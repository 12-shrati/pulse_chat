import 'package:pulse_chat/features/chat/data/models/message_model.dart';
import 'package:sqflite/sqflite.dart';

class ChatLocalDataSource {
  final Database _db;

  ChatLocalDataSource(this._db);

  Future<List<MessageModel>> getMessages(String conversationId) async {
    final results = await _db.query(
      'messages',
      where: '(receiver_id = ? AND group_id IS NULL) OR (sender_id = ? AND group_id IS NULL)',
      whereArgs: [conversationId, conversationId],
      orderBy: 'created_at ASC',
    );
    return results.map((e) => MessageModel.fromJson(e)).toList();
  }

  Future<void> insertMessage(MessageModel message) async {
    await _db.insert(
      'messages',
      message.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateMessageStatus(String id, String status) async {
    await _db.update(
      'messages',
      {'status': status},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
