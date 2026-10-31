import 'dart:async';

import 'package:flashcard/model/app_failure.dart';
import 'package:flashcard/model/entities/conversation.dart';
import 'package:flashcard/model/entities/conversation_summary.dart';
import 'package:flashcard/repositories/chat_repository.dart';
import 'package:flashcard/state_management/cubits/chat_cubit/chat_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

Conversation reply(
  String id, {
  ConversationStatus status = ConversationStatus.idle,
  String? error,
}) => Conversation(
  id: id,
  title: 'oggi MCP',
  status: status,
  items: const [
    ChatItem(kind: ChatItemKind.user, text: 'oggi MCP'),
    ChatItem(kind: ChatItemKind.assistant, text: 'Ecco il mazzo'),
  ],
  error: error,
);

class FakeChatRepository implements ChatRepository {
  int created = 0;
  final confirmations = <bool>[];
  Completer<Conversation> turn = Completer();
  AppFailure? failure;

  @override
  Future<Conversation> create() async {
    created++;
    return reply('7');
  }

  @override
  Future<Conversation> send(String id, String text) {
    if (failure case final f?) return Future.error(f);
    return turn.future;
  }

  @override
  Future<Conversation> confirm(String id, {required bool approve}) async {
    confirmations.add(approve);
    return reply(id);
  }

  @override
  Future<Conversation> fetch(String id) async => reply(id);

  @override
  Future<List<ConversationSummary>> conversations() async => const [];

  @override
  Future<void> delete(String id) async {}
}

void main() {
  late FakeChatRepository repository;

  setUp(() => repository = FakeChatRepository());

  test(
    'una chat nuova si crea al primo messaggio, che si vede subito',
    () async {
      final cubit = ChatCubit(repository: repository)..load();
      final sending = cubit.send('oggi MCP');
      await Future<void>.delayed(Duration.zero);

      final working = cubit.state as ShowingChatState;
      expect(working.working, isTrue);
      expect(working.conversation.items.single.text, 'oggi MCP');

      repository.turn.complete(
        reply('7', status: ConversationStatus.waitingConfirmation),
      );
      await sending;

      final done = cubit.state as ShowingChatState;
      expect(done.working, isFalse);
      expect(done.conversation.status, ConversationStatus.waitingConfirmation);
      expect(repository.created, 1);
      expect(cubit.conversationId, '7');
      await cubit.close();
    },
  );

  test('mentre lavora non manda un secondo messaggio', () async {
    final cubit = ChatCubit(repository: repository)..load();
    final first = cubit.send('uno');
    await Future<void>.delayed(Duration.zero);
    await cubit.send('due');

    repository.turn.complete(reply('7'));
    await first;

    expect(repository.created, 1);
    await cubit.close();
  });

  test('un errore del turno arriva come avviso', () async {
    final cubit = ChatCubit(repository: repository, conversationId: '7');
    await cubit.load();
    repository.turn.complete(reply('7', error: 'La Claude API non risponde.'));

    await cubit.send('ciao');

    expect(
      (cubit.state as ShowingChatState).notice,
      'La Claude API non risponde.',
    );
    await cubit.close();
  });

  test('se la rete cade la chat torna com\'era, con un avviso', () async {
    final cubit = ChatCubit(repository: repository, conversationId: '7');
    await cubit.load();
    repository.failure = const NetworkFailure();

    await cubit.send('ciao');

    final state = cubit.state as ShowingChatState;
    expect(state.conversation.items.length, 2);
    expect(state.notice, const NetworkFailure().message);
    await cubit.close();
  });

  test('la conferma passa la scelta al repository', () async {
    final cubit = ChatCubit(repository: repository, conversationId: '7');
    await cubit.load();

    await cubit.confirm(approve: true);

    expect(repository.confirmations, [true]);
    await cubit.close();
  });
}
