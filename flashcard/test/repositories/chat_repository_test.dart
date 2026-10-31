import 'package:flashcard/mappers/conversation_mapper.dart';
import 'package:flashcard/mappers/conversation_summary_mapper.dart';
import 'package:flashcard/model/app_failure.dart';
import 'package:flashcard/network/api_exception.dart';
import 'package:flashcard/network/service/chat_service.dart';
import 'package:flashcard/repositories/impl/chat_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> conversation({String status = 'idle'}) => {
  'id': 1,
  'title': 't',
  'status': status,
  'items': [
    {'kind': 'assistant', 'text': 'Ciao'},
  ],
  'pending': null,
  'error': null,
};

class FakeChatService implements ChatService {
  final sent = <(String, String)>[];
  final confirmations = <bool>[];
  bool failSend = false;

  @override
  Future<Map<String, dynamic>> fetchConversations() async => {
    'conversations': [
      {
        'id': 1,
        'title': 't',
        'status': 'idle',
        'updated_at': '2026-10-26T10:00:00+00:00',
      },
    ],
  };

  @override
  Future<Map<String, dynamic>> createConversation() async => conversation();

  @override
  Future<Map<String, dynamic>> fetchConversation(String id) async =>
      conversation();

  @override
  Future<Map<String, dynamic>> sendMessage(String id, String text) async {
    if (failSend) throw const ApiException(409, 'occupata');
    sent.add((id, text));
    return conversation(status: 'waiting_confirmation');
  }

  @override
  Future<Map<String, dynamic>> confirm(
    String id, {
    required bool approve,
  }) async {
    confirmations.add(approve);
    return conversation();
  }

  @override
  Future<void> deleteConversation(String id) async {}
}

void main() {
  late FakeChatService service;
  late ChatRepositoryImpl repository;

  setUp(() {
    service = FakeChatService();
    repository = ChatRepositoryImpl(
      service: service,
      mapper: const ConversationMapper(),
      summaryMapper: const ConversationSummaryMapper(),
    );
  });

  test('restituisce modelli di dominio', () async {
    final summaries = await repository.conversations();
    final sent = await repository.send('1', 'ciao');

    expect(summaries.single.id, '1');
    expect(sent.items.single.text, 'Ciao');
    expect(service.sent, [('1', 'ciao')]);
  });

  test('la conferma passa la scelta al backend', () async {
    await repository.confirm('1', approve: false);

    expect(service.confirmations, [false]);
  });

  test('un errore HTTP diventa un AppFailure', () async {
    service.failSend = true;

    expect(repository.send('1', 'ciao'), throwsA(isA<ServerFailure>()));
  });
}
