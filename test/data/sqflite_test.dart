import 'package:chat/chat.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:sketchades/data/datasource/sqflite_datasource.dart';
import 'package:sketchades/models/chat.dart';
import 'package:sketchades/models/local_message.dart';
import 'package:sqflite/sqflite.dart';

@GenerateNiceMocks([MockSpec<Database>(), MockSpec<Batch>()])
import 'sqflite_test.mocks.dart'; //'dart run build_runner build' to generate this file

void main() {
  late SqfliteDatasource sut;
  late MockDatabase database;
  late MockBatch batch;

  setUp(() {
    database = MockDatabase();
    batch = MockBatch();
    sut = SqfliteDatasource(database);
  });

  final message = Message.fromJson({
    'from': '12',
    'to': '222',
    'contents': 'wubba',
    'timestamp': DateTime.parse("2025-06-27"),
    'id': '22',
  });

  test('inserts chat to database', () async {
    final chat = Chat('123');

    when(
      database.insert(
        'chats',
        chat.toMap(),
        conflictAlgorithm: anyNamed('conflictAlgorithm'),
      ),
    ).thenAnswer((_) async => 1);

    await sut.addChat(chat);

    verify(
      database.insert(
        'chats',
        chat.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      ),
    ).called(1);
  });

  test('should perform message insert to database', () async {
    final localMessage = LocalMessage('123', message, ReceiptStatus.sent);

    when(
      database.insert(
        'messages',
        localMessage.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      ),
    ).thenAnswer((_) async => 1);

    await sut.addMessage(localMessage);

    verify(
      database.insert(
        'messages',
        localMessage.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      ),
    ).called(1);
  });

  test('performs a database query and returns message', () async {
    final messagesMap = [
      {
        'chat_id': '11',
        'id': '22',
        'from': '2',
        'to': '1',
        'contents': 'sup',
        'receipt_status': 'sent',
        'timestamp': DateTime.parse('2025-06-27'),
      },
    ];

    when(
      database.query(
        'messages',
        where: anyNamed('where'),
        whereArgs: anyNamed('whereArgs'),
      ),
    ).thenAnswer(
      (_) async => messagesMap,
    ); //whenever we query the db return this record as a record is found in the db

    var messages = await sut.findMessages('11');

    expect(messages.length, 1);
    expect(messages.first.chatId, '11');
    verify(
      database.query(
        'messages',
        where: anyNamed('where'),
        whereArgs: anyNamed('whereArgs'),
      ),
    ).called(1); //verify the call to the query method was called only once
  });

  test('performs update on messages', () async {
    final localMessage = LocalMessage('12', message, ReceiptStatus.sent);
    when(
      database.update(
        'messages',
        localMessage.toMap(),
        where: anyNamed('where'),
        whereArgs: anyNamed('whereArgs'),
        conflictAlgorithm: ConflictAlgorithm.replace,
      ),
    ).thenAnswer((_) async => 1);

    await sut.updateMessage(localMessage);

    verify(
      database.update(
        'messages',
        localMessage.toMap(),
        where: anyNamed('where'),
        whereArgs: anyNamed('whereArgs'),
        conflictAlgorithm: ConflictAlgorithm.replace,
      ),
    ).called(1);
  });

  test('performs batch delete of chat', () async {
    final chatId = 'ma-12';
    when(database.batch()).thenReturn(batch);

    await sut.deleteChat(chatId);

    verifyInOrder([
      database.batch(),
      batch.delete('messages', where: anyNamed('where'), whereArgs: [chatId]),
      batch.delete('chats', where: anyNamed('where'), whereArgs: [chatId]),
      batch.commit(noResult: true),
    ]);
  });
}
