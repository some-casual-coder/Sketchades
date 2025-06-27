import 'package:chat/chat.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:sketchades/data/datasource/datasource_contract.dart';
import 'package:sketchades/models/chat.dart';
import 'package:sketchades/viewmodels/chats_view_model.dart';

@GenerateNiceMocks([MockSpec<IDataSource>()])
import 'chats_view_model_test.mocks.dart';

void main() {
  late ChatsViewModel sut;
  late MockIDataSource mockDatasource;

  setUp(() {
    mockDatasource = MockIDataSource();
    sut = ChatsViewModel(mockDatasource);
  });

  final message = Message.fromJson({
    'from': '12',
    'to': '222',
    'contents': 'wubba',
    'timestamp': DateTime.parse("2025-06-27"),
    'id': '22',
  });

  test('retrieving initial chats returns an empty list', () async {
    when(mockDatasource.findAllChats()).thenAnswer((_) async => []);
    expect(await sut.getChats(), isEmpty);
  });

  test('returns list of chats', () async {
    final chat = Chat('123');
    when(mockDatasource.findAllChats()).thenAnswer((_) async => [chat]);
    final chats = await sut.getChats();
    expect(chats, isNotEmpty);
  });

  test('creates new chat when receiving message for the first time', () async {
    when(mockDatasource.findChat(any)).thenAnswer((_) async => null);
    await sut.receivedMessage(message);
    verify(mockDatasource.addChat(any)).called(1);
  });

  test('adds new message to existing chat', () async {
    final chat = Chat('123');
    when(mockDatasource.findChat(any)).thenAnswer((_) async => chat);
    await sut.receivedMessage(message);
    verifyNever(mockDatasource.addChat(any));
    verify(mockDatasource.addMessage(any)).called(1);
  });
}
