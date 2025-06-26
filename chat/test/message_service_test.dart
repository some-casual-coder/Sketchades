import 'package:chat/src/models/message.dart';
import 'package:chat/src/models/user.dart';
import 'package:chat/src/services/encryption/encryption_service.dart';
import 'package:chat/src/services/message/message_service_impl.dart';
import 'package:encrypt/encrypt.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rethink_db_ns/rethink_db_ns.dart';

import 'helper.dart';

void main() {
  RethinkDb r = RethinkDb();
  late Connection connection;
  late MessageService sut;

  setUp(() async {
    connection = await r.connect(host: '127.0.0.1', port: 28015);
    final encryption = EncryptionService(Encrypter(AES(Key.fromLength(32))));
    await createDB(r, connection);
    sut = MessageService(r, connection, encryption);
  });

  tearDown(() async {
    sut.dispose();
    await cleanDB(r, connection);
  });

  final user1 = User.fromJson({
    'id': '21',
    'username': 'nana',
    'photo_url': 'url',
    'active': true,
    'last_seen': DateTime.now().toIso8601String(),
  });

  final user2 = User.fromJson({
    'id': '98',
    'username': 'nene',
    'photo_url': 'url',
    'active': true,
    'last_seen': DateTime.now().toIso8601String(),
  });

  test('sent msg successfully', () async {
    Message message = Message(
      from: user1.id,
      to: '2323',
      timestamp: DateTime.now(),
      contents: 'wubba lubba dab dab',
    );
    final res = await sut.send(message);
    expect(res, true);
  });

  test('successfully subscribe and receive messages', () async {
    final contents = "dab dab dao";
    sut
        .messages(activeUser: user2)
        .listen(
          expectAsync1((message) {
            expect(message.to, user2.id);
            expect(message.id, isNotEmpty);
            expect(message.contents, contents);
          }, count: 2),
        );
    Message message = Message(
      from: user1.id,
      to: user2.id,
      timestamp: DateTime.now(),
      contents: contents,
    );

    Message message2 = Message(
      from: user1.id,
      to: user2.id,
      timestamp: DateTime.now(),
      contents: contents,
    );

    await sut.send(message);
    await sut.send(message2);
  });

  test('successfully subscribe to and receive new messages', () async {
    Message message = Message(
      from: user1.id,
      to: user2.id,
      timestamp: DateTime.now(),
      contents: "wubba lubba dab dab",
    );

    Message message2 = Message(
      from: user1.id,
      to: user2.id,
      timestamp: DateTime.now(),
      contents: "dab dab dao",
    );

    await sut.send(message);
    await sut
        .send(message2)
        .whenComplete(
          () => sut
              .messages(activeUser: user2)
              .listen(
                expectAsync1((message) {
                  expect(message.to, user2.id);
                }, count: 2),
              ),
        );
  });
}
