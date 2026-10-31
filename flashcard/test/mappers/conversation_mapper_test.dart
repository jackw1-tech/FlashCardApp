import 'package:flashcard/mappers/conversation_mapper.dart';
import 'package:flashcard/mappers/conversation_summary_mapper.dart';
import 'package:flashcard/model/entities/conversation.dart';
import 'package:flashcard/network/dto/conversation_dto.dart';
import 'package:flashcard/network/dto/conversation_summary_dto.dart';
import 'package:flutter_test/flutter_test.dart';

const json = {
  'id': 4,
  'title': 'oggi ripasso MCP',
  'status': 'waiting_confirmation',
  'items': [
    {'kind': 'user', 'text': 'oggi ripasso MCP'},
    {'kind': 'activity', 'text': "Ho preparato l'anteprima"},
    {
      'kind': 'deck_created',
      'text': 'MCP',
      'temporary_deck_id': 9,
      'total': 20,
    },
  ],
  'pending': {
    'action': 'Creare il mazzo provvisorio?',
    'deck': {
      'name': 'MCP',
      'total': 3,
      'by_note': [
        {'note': 'MCP', 'taken': 3},
        {'note': null, 'taken': 0},
      ],
      'adjustments': ['Chieste 20 card, ne esistono 3.'],
    },
  },
  'error': null,
};

void main() {
  const mapper = ConversationMapper();

  test('dal JSON del backend alla conversazione', () {
    final conversation = mapper.fromDTO(ConversationDTO.fromJson(json));

    expect(conversation.id, '4');
    expect(conversation.status, ConversationStatus.waitingConfirmation);
    expect(conversation.items.map((i) => i.kind), [
      ChatItemKind.user,
      ChatItemKind.activity,
      ChatItemKind.deckCreated,
    ]);
    expect(conversation.items.last.temporaryDeckId, '9');
    final deck = conversation.pending!.deck!;
    expect(deck.byNote.first, (note: 'MCP', taken: 3));
    expect(deck.byNote.last.note, 'Tutte le note');
    expect(deck.adjustments, ['Chieste 20 card, ne esistono 3.']);
  });

  test('andata e ritorno non perdono niente', () {
    final dto = ConversationDTO.fromJson(json);

    final again = mapper.toDTO(mapper.fromDTO(dto));

    expect(again.status, 'waiting_confirmation');
    expect(again.items.last.toJson(), dto.items.last.toJson());
    expect(again.pending!.deck!.total, 3);
  });

  test('una conversazione senza nulla in sospeso', () {
    final conversation = mapper.fromDTO(
      ConversationDTO.fromJson({
        ...json,
        'status': 'idle',
        'pending': null,
        'error': 'La Claude API non risponde.',
      }),
    );

    expect(conversation.pending, isNull);
    expect(conversation.error, 'La Claude API non risponde.');
  });

  test('il riassunto per l\'elenco delle chat', () {
    final summary = const ConversationSummaryMapper().fromDTO(
      ConversationSummaryDTO.fromJson({
        'id': 2,
        'title': 'Raft',
        'status': 'idle',
        'updated_at': '2026-10-26T10:00:00+00:00',
      }),
    );

    expect(summary.id, '2');
    expect(summary.status, ConversationStatus.idle);
    expect(summary.updatedAt, DateTime.utc(2026, 10, 26, 10));
  });
}
