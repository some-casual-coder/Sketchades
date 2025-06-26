import 'dart:async';

import 'package:chat/src/models/message.dart';
import 'package:chat/src/models/user.dart';
import 'package:chat/src/services/encryption/encryption_contract.dart';
import 'package:chat/src/services/message/message_service_contract.dart';
import 'package:rethink_db_ns/rethink_db_ns.dart';

class MessageService implements IMessageService {
  final Connection _connection;
  final RethinkDb r;
  final IEncryption _encryption;
  final _controller =
      StreamController<
        Message
      >.broadcast(); //can be subscribed to by multiple clients
  StreamSubscription? _changefeed;
  MessageService(this.r, this._connection, this._encryption);

  @override
  dispose() {
    _changefeed?.cancel();
    _controller.close();
  }

  @override
  Stream<Message> messages({required User activeUser}) {
    //create a stream only if someone has subscribed to it to avoid memory being used up too much
    _startReceivingMessages(activeUser);
    return _controller.stream;
  }

  @override
  Future<bool> send(Message message) async {
    var data = message.toJson();
    data['contents'] = _encryption.encrypt(message.contents);
    Map record = await r.table('messages').insert(data).run(_connection);
    return record['inserted'] == 1;
  }

  _startReceivingMessages(User user) {
    //changefeed is a stream of data or events that happen on that table
    //include_initial so that if just subscribing to change feed you get messages that are waiting for you and don't have to wait for new messages/changes to get them
    _changefeed = r
        .table('messages')
        .filter({'to': user.id})
        .changes({'include_initial': true})
        .run(_connection)
        .asStream()
        .cast<Feed>()
        .listen((event) {
          event
              .forEach((feedData) {
                if (feedData['new_val'] == null) return;
                final message = _messageFromFeed(feedData);
                _controller.sink.add(message);
                //store msgs locally on device,so once delivered delete it from the db
                _removeDeliveredMessage(message);
              })
              .catchError((err) => print(err))
              .onError(
                (error, stackTrace) => print(error),
              ); // TODO use a logging framework
        });
  }

  Message _messageFromFeed(feedData) {
    var data = feedData['new_val'];
    data['contents'] = _encryption.decrypt(data['contents']);
    return Message.fromJson(data);
  }

  _removeDeliveredMessage(Message message) {
    r
        .table('messages')
        .get(message.id)
        .delete({'return_changes': false})
        .run(_connection);
  }
}
