import 'package:chat/src/models/typing_event.dart';
import 'package:chat/src/models/user.dart';
import 'package:chat/src/services/typing/typing_notification_service_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rethink_db_ns/rethink_db_ns.dart';

import 'helper.dart';

void main() {
  RethinkDb r = RethinkDb();
  late Connection connection;
  late TypingNotificationService sut;

  setUp(() async {
    connection = await r.connect();
    await createDB(r, connection);
    sut = TypingNotificationService(r, connection);
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
    'last_seen': DateTime.now(),
  });

  final user2 = User.fromJson({
    'id': '98',
    'username': 'nene',
    'photo_url': 'url',
    'active': true,
    'last_seen': DateTime.now(),
  });

  test('sends typing notification successfully', () async {
    TypingEvent typingEvent = TypingEvent(
      from: user1.id,
      to: user2.id,
      event: Typing.start,
    );
    final res = await sut.send(event: typingEvent, to: user2);
    expect(res, true);
  });

  test('subscribes and receives typing events', () async {
    sut
        .subscribe(user1, [user2.id!])
        .listen(
          expectAsync1((event) {
            expect(event.from, user2.id);
          }, count: 2),
        );
    TypingEvent typingEvent = TypingEvent(
      from: user2.id,
      to: user1.id,
      event: Typing.start,
    );
    TypingEvent typingEvent2 = TypingEvent(
      from: user2.id,
      to: user1.id,
      event: Typing.stop,
    );

    await sut.send(event: typingEvent, to: user1);
    await sut.send(event: typingEvent2, to: user1);
  });
}
