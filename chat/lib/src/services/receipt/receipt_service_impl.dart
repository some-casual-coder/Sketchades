import 'dart:async';

import 'package:chat/src/models/receipt.dart';
import 'package:chat/src/models/user.dart';
import 'package:chat/src/services/receipt/receipt_service_contract.dart';
import 'package:rethink_db_ns/rethink_db_ns.dart';

class ReceiptService implements IReceiptService {
  final Connection _connection;
  final RethinkDb r;
  final _controller =
      StreamController<
        Receipt
      >.broadcast(); //can be subscribed to by multiple clients
  StreamSubscription? _changefeed;
  ReceiptService(this.r, this._connection);

  @override
  dispose() {
    _changefeed?.cancel();
    _controller.close();
  }

  @override
  Stream<Receipt> receipts(User user) {
    _startReceivingReceipts(user);
    return _controller.stream;
  }

  @override
  Future<bool> send(Receipt receipt) async {
    var data = receipt.toJson();
    Map record = await r.table('receipts').insert(data).run(_connection);
    return record['inserted'] == 1;
  }

  _startReceivingReceipts(User user) {
    _changefeed = r
        .table('receipts')
        .filter({'recipient': user.id})
        .changes({'include_initial': true})
        .run(_connection)
        .asStream()
        .cast<Feed>()
        .listen((event) {
          event
              .forEach((feedData) {
                if (feedData['new_val'] == null) return;
                final receipt = _receiptFromFeed(feedData);
                _controller.sink.add(receipt);
              })
              .catchError((err) => print(err))
              .onError(
                (error, stackTrace) => print(error),
              ); // TODO use a logging framework
        });
  }

  Receipt _receiptFromFeed(feedData) {
    var data = feedData['new_val'];
    return Receipt.fromJson(data);
  }
}
