import 'package:flashcard/mappers/review_answer_mapper.dart';
import 'package:flashcard/mappers/review_mapper.dart';
import 'package:flashcard/mappers/study_card_mapper.dart';
import 'package:flashcard/mappers/study_stats_mapper.dart';
import 'package:flashcard/mappers/temporary_deck_mapper.dart';
import 'package:flashcard/mappers/saved_session_mapper.dart';
import 'package:flashcard/mappers/session_draft_mapper.dart';
import 'package:flashcard/model/entities/review_answer.dart';
import 'package:flashcard/model/entities/review_outcome.dart';
import 'package:flashcard/network/service/study_service.dart';
import 'package:flashcard/repositories/impl/study_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_local_store.dart';

class FakeStudyService implements StudyService {
  Map<String, dynamic>? lastReview;
  final deletedDecks = <String>[];

  @override
  Future<Map<String, dynamic>> fetchTemporaryDecks() async => {
    'temporary_decks': [
      {
        'id': 3,
        'name': 'Fencing token',
        'created_at': '2026-10-26T10:00:00+00:00',
        'expires_at': '2026-10-26T23:00:00+00:00',
        'total': 9,
        'done': 4,
        'missed': 1,
      },
    ],
  };

  @override
  Future<Map<String, dynamic>> fetchSessions() async => {
    'sessions': [
      {
        'id': 9,
        'deck': {'slug': 'ddia', 'name': 'DDIA'},
        'note_title': 'Replica',
        'temporary_deck': null,
        'started_at': '2026-10-26T10:00:00Z',
        'ended_at': '2026-10-26T10:05:00Z',
        'knew': 8,
        'didnt_know': 2,
      },
    ],
  };

  @override
  Future<void> deleteTemporaryDeck(String id) async => deletedDecks.add(id);

  @override
  Future<Map<String, dynamic>> postSession(Map<String, dynamic> body) async => {
    'id': 1,
    'started_at': '2026-01-01T10:00:00Z',
    'ended_at': '2026-01-01T10:05:00Z',
    'knew': 1,
    'didnt_know': 0,
  };
  Map<String, dynamic> nextCard = {'card': null};
  String? undone;

  @override
  Future<Map<String, dynamic>> fetchNextCard({
    String? deckSlug,
    String? noteTitle,
    String? temporaryDeckId,
    required List<String> excludeIds,
  }) async => nextCard;

  @override
  Future<Map<String, dynamic>> postReview(Map<String, dynamic> body) async {
    lastReview = body;
    return {
      'id': 7,
      'card_id': body['card_id'],
      'outcome': body['outcome'],
      'created_at': '2026-01-01T10:00:00Z',
    };
  }

  @override
  Future<Map<String, dynamic>> undoReview(String reviewId) async {
    undone = reviewId;
    return {};
  }

  @override
  Future<Map<String, dynamic>> fetchStats() async => {
    'today': '2026-01-01',
    'today_reviews': 4,
    'streak_days': 2,
    'decks': [],
  };
}

void main() {
  late FakeStudyService service;
  late StudyRepositoryImpl repository;

  setUp(() {
    service = FakeStudyService();
    repository = StudyRepositoryImpl(
      service: service,
      cardMapper: const StudyCardMapper(),
      answerMapper: const ReviewAnswerMapper(),
      reviewMapper: const ReviewMapper(),
      statsMapper: const StudyStatsMapper(),
      temporaryDeckMapper: const TemporaryDeckMapper(),
      sessionDraftMapper: const SessionDraftMapper(),
      savedSessionMapper: const SavedSessionMapper(),
      store: FakeLocalStore(),
    );
  });

  test('senza card da proporre restituisce null', () async {
    expect(await repository.nextCard(excludeIds: const []), isNull);
  });

  test('le sessioni salvate mantengono contesto e conteggi', () async {
    final sessions = await repository.savedSessions();

    expect(sessions.single.id, '9');
    expect(sessions.single.deckName, 'DDIA');
    expect(sessions.single.noteTitle, 'Replica');
    expect(sessions.single.total, 10);
  });

  test('la card del backend esce come StudyCard', () async {
    service.nextCard = {
      'card': {
        'id': 42,
        'deck': {'slug': 'scala', 'name': 'Scala'},
        'note_title': 'Liste',
        'kind': 'basic',
        'front': 'Q',
        'back': 'A',
      },
    };

    final card = await repository.nextCard(excludeIds: const []);

    expect((card!.id, card.deckName, card.front), ('42', 'Scala', 'Q'));
  });

  test(
    'la risposta parte con il valore dell\'API e torna come Review',
    () async {
      final review = await repository.submitReview(
        ReviewAnswer.create(cardId: '42', outcome: ReviewOutcome.didntKnow),
      );

      expect(service.lastReview, {'card_id': 42, 'outcome': 'didnt_know'});
      expect((review.id, review.cardId), ('7', '42'));
      expect(review.outcome, ReviewOutcome.didntKnow);
    },
  );

  test('annulla una Review e legge le statistiche', () async {
    await repository.undoReview('7');
    final stats = await repository.fetchStats();

    expect(service.undone, '7');
    expect((stats.todayReviews, stats.streakDays), (4, 2));
  });

  test('i mazzi provvisori arrivano come modelli di dominio', () async {
    final [deck] = await repository.temporaryDecks();

    expect(deck.id, '3');
    expect(deck.remaining, 5);
    expect(deck.expiresAt, DateTime.utc(2026, 10, 26, 23));
  });

  test('eliminare un mazzo provvisorio passa l\'id al backend', () async {
    await repository.deleteTemporaryDeck('3');

    expect(service.deletedDecks, ['3']);
  });
}
