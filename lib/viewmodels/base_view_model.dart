import 'package:flutter/foundation.dart';
import 'package:sketchades/data/datasource/datasource_contract.dart';
import 'package:sketchades/models/chat.dart';
import 'package:sketchades/models/local_message.dart';

abstract class BaseViewModel {
  final IDataSource _dataSource;
  BaseViewModel(this._dataSource);

  @protected
  Future<void> addMessage(LocalMessage message) async {
    if (!await _isExistingChat(message.chatId!)) {
      await _createNewChat(message.chatId!);
    }
    await _dataSource.addMessage(message);
  }

  Future<bool> _isExistingChat(String chatId) async {
    return await _dataSource.findChat(chatId) != null;
  }

  Future<void> _createNewChat(String chatId) async {
    final chat = Chat(chatId);
    await _dataSource.addChat(chat);
  }
}
