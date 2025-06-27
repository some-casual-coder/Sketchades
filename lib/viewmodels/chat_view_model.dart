import 'package:chat/chat.dart';
import 'package:sketchades/data/datasource/datasource_contract.dart';
import 'package:sketchades/models/local_message.dart';
import 'package:sketchades/viewmodels/base_view_model.dart';

class ChatViewModel extends BaseViewModel {
  IDataSource _dataSource;
  String _chatId = '';
  int otherMessages = 0;
  ChatViewModel(this._dataSource) : super(_dataSource);

  Future<List<LocalMessage>> getMessages(String chatId) async {
    final messages = await _dataSource.findMessages(chatId);
    if (messages.isNotEmpty) {
      _chatId = chatId;
    }
    return messages;
  }

  Future<void> sentMessage(Message message) async {
    LocalMessage localMessage = LocalMessage(
      message.to,
      message,
      ReceiptStatus.sent,
    );
    if (_chatId.isNotEmpty) return await _dataSource.addMessage(localMessage);
    _chatId = localMessage.chatId!;
    await addMessage(localMessage);
  }

  Future<void> receivedMessage(Message message) async {
    LocalMessage localMessage = LocalMessage(
      message.from,
      message,
      ReceiptStatus.delivered,
    );
    if (localMessage.chatId != _chatId) otherMessages++;
    await addMessage(localMessage);
  }
}
