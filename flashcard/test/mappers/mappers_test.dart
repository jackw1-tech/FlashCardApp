import 'package:flashcard/mappers/decks_overview_mapper.dart';
import 'package:flashcard/mappers/review_answer_mapper.dart';
import 'package:flashcard/mappers/review_mapper.dart';
import 'package:flashcard/mappers/card_report_mapper.dart';
import 'package:flashcard/mappers/report_draft_mapper.dart';
import 'package:flashcard/mappers/study_card_mapper.dart';
import 'package:flashcard/mappers/study_stats_mapper.dart';
import 'package:flashcard/model/entities/report_draft.dart';
import 'package:flashcard/model/entities/report_reason.dart';
import 'package:flashcard/network/dto/card_report_dto.dart';
import 'package:flashcard/network/dto/stats_dto.dart';
import 'package:flashcard/model/entities/review_answer.dart';
import 'package:flashcard/model/entities/review_outcome.dart';
import 'package:flashcard/network/dto/card_dto.dart';
import 'package:flashcard/network/dto/decks_overview_dto.dart';
import 'package:flashcard/network/dto/review_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('la lista Mazzi del backend diventa un DecksOverview', () {
    final dto = DecksOverviewDTO.fromJson({
      'all': {'total_cards': 3, 'unseen_cards': 2},
      'decks': [
        {
          'slug': 'ddia',
          'name': 'DDIA',
          'total_cards': 3,
          'unseen_cards': 2,
          'subdecks': [
            {
              'slug': 'ddia/replicazione',
              'name': 'replicazione',
              'total_cards': 3,
              'unseen_cards': 2,
              'subdecks': [],
            },
          ],
        },
      ],
    });

    final overview = const DecksOverviewMapper().fromDTO(dto);

    expect((overview.totalCards, overview.unseenCards), (3, 2));
    expect(overview.decks.single.id, 'ddia');
    expect(overview.decks.single.name, 'DDIA');
    expect(overview.decks.single.subdecks.single.id, 'ddia/replicazione');
  });

  test('una card del backend diventa una StudyCard con id testuale', () {
    final dto = CardDTO.fromJson({
      'id': 42,
      'deck': {'slug': 'scala', 'name': 'Scala'},
      'note_title': 'Liste',
      'kind': 'basic',
      'front': 'Cosa fa `x :: xs`?',
      'back': 'Prepend',
    });

    final card = const StudyCardMapper().fromDTO(dto);

    expect(card.id, '42');
    expect(
      (card.deckName, card.noteTitle, card.front, card.back),
      ('Scala', 'Liste', 'Cosa fa `x :: xs`?', 'Prepend'),
    );
  });

  test(
    'la risposta diventa il corpo della richiesta con l\'esito in formato API',
    () {
      final answer = ReviewAnswer.create(
        cardId: '7',
        outcome: ReviewOutcome.didntKnow,
      );

      expect(const ReviewAnswerMapper().toDTO(answer).toJson(), {
        'card_id': 7,
        'outcome': 'didnt_know',
      });
    },
  );

  test('la Review del backend diventa una Review di dominio', () {
    final dto = ReviewDTO.fromJson({
      'id': 1,
      'card_id': 7,
      'outcome': 'knew',
      'created_at': '2026-10-21T10:00:00Z',
    });

    final review = const ReviewMapper().fromDTO(dto);

    expect(
      (review.id, review.cardId, review.outcome),
      ('1', '7', ReviewOutcome.knew),
    );
    expect(review.createdAt, DateTime.utc(2026, 10, 21, 10));
  });

  test('gli ultimi esiti della card diventano esiti di dominio, e mancano nella ricerca', () {
    final withHistory = CardDTO.fromJson({
      'id': 1,
      'deck': {'slug': 's', 'name': 'S'},
      'note_title': 'N',
      'kind': 'basic',
      'front': 'Q',
      'back': 'A',
      'recent_outcomes': ['didnt_know', 'knew'],
    });
    final withoutHistory = CardDTO.fromJson({
      'id': 2,
      'deck': {'slug': 's', 'name': 'S'},
      'note_title': 'N',
      'kind': 'basic',
      'front': 'Q',
      'back': 'A',
    });

    expect(const StudyCardMapper().fromDTO(withHistory).recentOutcomes, [
      ReviewOutcome.didntKnow,
      ReviewOutcome.knew,
    ]);
    expect(
      const StudyCardMapper().fromDTO(withoutHistory).recentOutcomes,
      isEmpty,
    );
  });

  test('le statistiche del backend diventano StudyStats', () {
    final dto = StatsDTO.fromJson({
      'today': '2026-10-22',
      'today_reviews': 12,
      'streak_days': 3,
      'decks': [
        {
          'slug': 'x',
          'name': 'X',
          'reviews': 4,
          'knew_ratio': 0.75,
          'last_studied_at': '2026-10-22T10:00:00Z',
        },
        {
          'slug': 'y',
          'name': 'Y',
          'reviews': 0,
          'knew_ratio': null,
          'last_studied_at': null,
        },
      ],
    });

    final stats = const StudyStatsMapper().fromDTO(dto);

    expect(
      (stats.today, stats.todayReviews, stats.streakDays),
      (DateTime(2026, 10, 22), 12, 3),
    );
    expect(
      (stats.decks.first.knewRatio, stats.decks.first.lastStudiedAt!.isUtc),
      (0.75, false),
    );
    expect(
      (stats.decks.last.knewRatio, stats.decks.last.lastStudiedAt),
      (null, null),
    );
  });

  test('una segnalazione va e torna dal formato API', () {
    final draft = ReportDraft.create(
      cardId: '7',
      reason: ReportReason.badFormat,
      comment: '  LaTeX rotto  ',
    );
    expect(const ReportDraftMapper().toDTO(draft).toJson(), {
      'reason': 'bad_format',
      'comment': 'LaTeX rotto',
    });

    final report = const CardReportMapper().fromDTO(
      CardReportDTO.fromJson({
        'id': 3,
        'reason': 'wrong_answer',
        'comment': '',
        'created_at': '2026-10-22T10:00:00Z',
        'card': {
          'id': 7,
          'deck': {'slug': 's', 'name': 'S'},
          'note_title': 'N',
          'kind': 'basic',
          'front': 'Q',
          'back': 'A',
        },
      }),
    );
    expect(
      (report.id, report.reason, report.card.id),
      ('3', ReportReason.wrongAnswer, '7'),
    );
  });
}
