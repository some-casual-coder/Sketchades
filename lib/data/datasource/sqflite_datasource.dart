import 'package:sketchades/data/datasource/datasource_contract.dart';
import 'package:sketchades/models/chat.dart';
import 'package:sketchades/models/local_message.dart';
import 'package:sqflite/sqflite.dart';

class SqfliteDatasource implements IDataSource {
  final Database _db;
  const SqfliteDatasource(this._db);

  @override
  Future<void> addChat(Chat? chat) async {
    await _db.insert(
      'chats',
      chat!.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> addMessage(LocalMessage message) async {
    await _db.insert(
      'messages',
      message.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> deleteChat(String chatId) async {
    final batch = _db
        .batch(); //to help do all db operations in one call to the db. Perform the delete on the batch
    batch.delete('messages', where: 'chat_id = ?', whereArgs: [chatId]);
    batch.delete('chats', where: 'id = ?', whereArgs: [chatId]);
    await batch.commit(noResult: true);
  }

  @override
  Future<List<Chat>> findAllChats() {
    //for this it is best to do it in an asynchronous transaction so we use transaction
    return _db.transaction((txn) async {
      //run each query on the txn object instead of the db object to avoid deadlocks
      final chatsWithLatestMessage = await txn.rawQuery('''
        SELECT messages.* FROM 
        (SELECT chat_id, MAX(created_at) AS created_at FROM messages GROUP BY chat_id) 
        AS latest_messages 
        INNNER JOIN messages 
        on messages.chat_id = latest_messages.chat_id 
        AND 
        messages.created_at = latest_messages.created_at
      ''');
      final chatsWithUnreadMessages = await txn.rawQuery(
        '''
        SELECT chat_id, COUNT(*) as unread FROM messages WHERE receipt_status = ? GROUP BY chat_id
      ''',
        ['delivered'],
      );
      return chatsWithLatestMessage.map<Chat>((row) {
        final int? unread = int.tryParse(
          chatsWithUnreadMessages
              .firstWhere(
                (ele) => row['chat_id'] == ele['chat_id'],
                orElse: () => {'unread': 0},
              )['unread']
              .toString(),
        );
        final chat = Chat.fromMap(row);
        chat.unread = unread!;
        chat.mostRecent = LocalMessage.fromMap(row);
        return chat;
      }).toList();
    });
  }

  @override
  Future<Chat> findChat(String chatId) async {
    return await _db.transaction((txn) async {
      final listofChatMaps = await txn.query(
        'chats',
        where: 'id = ?',
        whereArgs: [chatId],
      );
      final unread = Sqflite.firstIntValue(
        await txn.rawQuery(
          'SELECT COUNT(*) FROM messages WHERE chat_id = ? AND receipts = ?',
          [chatId, 'delivered'],
        ),
      );
      final mostRecentMessage = await txn.query(
        'messages',
        where: 'chat_id = ?',
        whereArgs: [chatId],
        orderBy: 'created_at DESC',
        limit: 1,
      );
      final chat = Chat.fromMap(listofChatMaps.first);
      chat.unread = unread!;
      chat.mostRecent = LocalMessage.fromMap(mostRecentMessage.first);
      return chat;
    });
  }

  @override
  Future<List<LocalMessage>> findMessages(String chatId) async {
    final listOfMaps = await _db.query(
      'messages',
      where: 'chat_id = ?',
      whereArgs: [chatId],
    );
    return listOfMaps
        .map<LocalMessage>((map) => LocalMessage.fromMap(map))
        .toList();
  }

  @override
  Future<void> updateMessage(LocalMessage message) async {
    await _db.update(
      'messages',
      message.toMap(),
      where: 'id = ?',
      whereArgs: [message.message.id],
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
