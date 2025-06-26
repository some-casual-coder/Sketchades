import 'package:chat/src/models/receipt.dart';
import 'package:chat/src/models/user.dart';
import 'package:chat/src/services/receipt/receipt_service_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rethink_db_ns/rethink_db_ns.dart';

import 'helper.dart';

void main() {
  RethinkDb r = RethinkDb();
  late Connection connection;
  late ReceiptService sut;

  setUp(() async {
    connection = await r.connect();
    await createDB(r, connection);
    sut = ReceiptService(r, connection);
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

  test('sent receipt successfully', () async {
    Receipt receipt = Receipt(
      recipient: '98',
      messageId: '2',
      status: ReceiptStatus.delivered,
      timestamp: DateTime.now(),
    );

    final res = await sut.send(receipt);
    expect(res, true);
  });

  test('successfully subscribe and receive receipts', () async {
    sut
        .receipts(user1)
        .listen(
          expectAsync1((receipt) {
            expect(receipt.recipient, user1.id);
          }, count: 2),
        );

    Receipt receipt = Receipt(
      recipient: user1.id,
      messageId: '1234',
      status: ReceiptStatus.delivered,
      timestamp: DateTime.now(),
    );

    Receipt anotherReceipt = Receipt(
      recipient: user1.id,
      messageId: '1234',
      status: ReceiptStatus.read,
      timestamp: DateTime.now(),
    );

    await sut.send(receipt);
    await sut.send(anotherReceipt);
  });
}

  // test('successfully subscribe and receive receipt', () async {
  //   sut
  //       .receipts(user1)
  //       .listen(
  //         expectAsync1((receipt) {
  //           expect(receipt.recipient, user1.id);
  //         }, count: 2),
  //       );

  //   Receipt receipt = Receipt(
  //     recipient: user1.id,
  //     messageId: '2',
  //     status: ReceiptStatus.delivered,
  //     timestamp: DateTime.now(),
  //   );
  //   Receipt receipt2 = Receipt(
  //     recipient: user1.id,
  //     messageId: '3',
  //     status: ReceiptStatus.read,
  //     timestamp: DateTime.now(),
  //   );

  //   await sut.send(receipt);
  //   await sut.send(receipt2);
  // });
