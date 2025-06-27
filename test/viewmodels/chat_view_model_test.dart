import 'package:chat/chat.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:sketchades/data/datasource/datasource_contract.dart';
import 'package:sketchades/models/chat.dart';
import 'package:sketchades/models/local_message.dart';
import 'package:sketchades/viewmodels/chat_view_model.dart';

@GenerateNiceMocks([MockSpec<IDataSource>()])
import 'chats_view_model_test.mocks.dart';

void main() {
  late ChatViewModel sut;
  late MockIDataSource mockDatasource;

  setUp(() {
    mockDatasource = MockIDataSource();
    sut = ChatViewModel(mockDatasource);
  });

  final message = Message.fromJson({
    'from': '12',
    'to': '222',
    'contents': 'wubba',
    'timestamp': DateTime.parse("2025-06-27"),
    'id': '22',
  });

  test('initial messages returns an empty list', () async {
    when(mockDatasource.findMessages(any)).thenAnswer((_) async => []);
    expect(await sut.getMessages('123'), isEmpty);
  });

  test('returns a list of messages from local storage', () async {
    final chat = Chat('13');
    final localMessage = LocalMessage(
      chat.id,
      message,
      ReceiptStatus.delivered,
    );
    when(
      mockDatasource.findMessages(chat.id),
    ).thenAnswer((_) async => [localMessage]);
    final messages = await sut.getMessages(chat.id!);
    expect(messages, isNotEmpty);
    expect(messages.first.chatId, '13');
  });

  test('creates a new chat when sending first message', () async {
    when(mockDatasource.findChat(any)).thenAnswer((_) async => null);
    await sut.sentMessage(message);
    verify(mockDatasource.addChat(any)).called(1);
  });

  test('adds new sent message to the chat', () async {
    final chat = Chat('123');
    final localMessage = LocalMessage(chat.id, message, ReceiptStatus.sent);
    when(
      mockDatasource.findMessages(chat.id),
    ).thenAnswer((_) async => [localMessage]);
    await sut.getMessages(chat.id!);
    await sut.sentMessage(message);

    verifyNever(mockDatasource.addChat(any));
    verify(mockDatasource.addMessage(any)).called(1);
  });

  test('adds new received message to the chat', () async {
    final chat = Chat('12'); //must match msg from
    final localMessage = LocalMessage(
      chat.id,
      message,
      ReceiptStatus.delivered,
    );
    when(
      mockDatasource.findMessages(chat.id),
    ).thenAnswer((_) async => [localMessage]);
    when(mockDatasource.findChat(chat.id)).thenAnswer((_) async => chat);

    await sut.getMessages(chat.id!);
    await sut.receivedMessage(message);

    verifyNever(mockDatasource.addChat(any));
    verify(mockDatasource.addMessage(any)).called(1);
  });

  test('creates new chat when msg received is not part of this chat', () async {
    final chat = Chat('124');
    final localMessage = LocalMessage(
      chat.id,
      message,
      ReceiptStatus.delivered,
    );
    when(
      mockDatasource.findMessages(chat.id),
    ).thenAnswer((_) async => [localMessage]);
    when(mockDatasource.findChat(chat.id)).thenAnswer((_) async => null);

    await sut.getMessages(chat.id!);
    await sut.receivedMessage(message);

    verify(mockDatasource.addChat(any)).called(1);
    verify(mockDatasource.addMessage(any)).called(1);
    expect(sut.otherMessages, 1);
  });
}
