import 'package:chat/chat.dart';
import 'package:sketchades/data/datasource/datasource_contract.dart';
import 'package:sketchades/models/chat.dart';
import 'package:sketchades/models/local_message.dart';
import 'package:sketchades/viewmodels/base_view_model.dart';

class ChatsViewModel extends BaseViewModel {
  IDataSource _dataSource;
  ChatsViewModel(this._dataSource) : super(_dataSource);

  Future<List<Chat>> getChats() async => await _dataSource.findAllChats();

  Future<void> receivedMessage(Message message) async {
    LocalMessage localMessage = LocalMessage(
      message.from,
      message,
      ReceiptStatus.delivered,
    );
    await addMessage(localMessage);
  }
}
