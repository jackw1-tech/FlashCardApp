import 'dart:convert';

import 'package:flashcard/model/entities/review.dart';
import 'package:flashcard/model/entities/review_answer.dart';
import 'package:flashcard/model/entities/saved_session.dart';
import 'package:flashcard/model/entities/session_draft.dart';
import 'package:flashcard/model/entities/study_card.dart';
import 'package:flashcard/model/entities/study_stats.dart';
import 'package:flashcard/model/entities/temporary_deck.dart';
import 'package:flashcard/network/dto/card_dto.dart';
import 'package:flashcard/network/dto/review_answer_dto.dart';
import 'package:flashcard/network/dto/review_dto.dart';
import 'package:flashcard/network/dto/saved_session_dto.dart';
import 'package:flashcard/network/dto/session_request_dto.dart';
import 'package:flashcard/network/dto/stats_dto.dart';
import 'package:flashcard/network/dto/temporary_deck_dto.dart';
import 'package:flashcard/network/service/local_store_service.dart';
import 'package:flashcard/network/service/study_service.dart';
import 'package:flashcard/other/constants/app_constants.dart';
import 'package:flashcard/repositories/impl/base_repository_impl.dart';
import 'package:flashcard/repositories/study_repository.dart';
import 'package:pine/pine.dart';

class StudyRepositoryImpl with BaseRepositoryImpl implements StudyRepository {
  final StudyService service;
  final DTOMapper<CardDTO, StudyCard> cardMapper;
  final DTOMapper<ReviewAnswerDTO, ReviewAnswer> answerMapper;
  final DTOMapper<ReviewDTO, Review> reviewMapper;
  final DTOMapper<StatsDTO, StudyStats> statsMapper;
  final DTOMapper<TemporaryDeckDTO, TemporaryDeck> temporaryDeckMapper;
  final DTOMapper<SessionRequestDTO, SessionDraft> sessionDraftMapper;
  final DTOMapper<SavedSessionDTO, SavedSession> savedSessionMapper;
  final LocalStoreService store;

  StudyRepositoryImpl({
    required this.store,
    required this.service,
    required this.cardMapper,
    required this.answerMapper,
    required this.reviewMapper,
    required this.statsMapper,
    required this.temporaryDeckMapper,
    required this.sessionDraftMapper,
    required this.savedSessionMapper,
  });

  @override
  Future<StudyCard?> nextCard({
    String? deckSlug,
    String? noteTitle,
    String? temporaryDeckId,
    required List<String> excludeIds,
  }) => guard(() async {
    final raw = await service.fetchNextCard(
      deckSlug: deckSlug,
      noteTitle: noteTitle,
      temporaryDeckId: temporaryDeckId,
      excludeIds: excludeIds,
    );
    final card = raw['card'] as Map<String, dynamic>?;
    return card == null ? null : cardMapper.fromDTO(CardDTO.fromJson(card));
  });

  @override
  Future<Review> submitReview(ReviewAnswer answer) => guard(() async {
    final raw = await service.postReview(answerMapper.toDTO(answer).toJson());
    return reviewMapper.fromDTO(ReviewDTO.fromJson(raw));
  });

  @override
  Future<void> undoReview(String reviewId) =>
      guard(() => service.undoReview(reviewId));

  @override
  StudyStats? cachedStats() {
    final raw = store.read(AppConstants.statsSnapshotKey);
    if (raw == null) return null;
    try {
      return statsMapper.fromDTO(
        StatsDTO.fromJson(jsonDecode(raw) as Map<String, dynamic>),
      );
    } on FormatException {
      return null;
    }
  }

  @override
  Future<StudyStats> fetchStats() => guard(() async {
    final raw = await service.fetchStats();
    final stats = statsMapper.fromDTO(StatsDTO.fromJson(raw));
    store.write(AppConstants.statsSnapshotKey, jsonEncode(raw));
    return stats;
  });

  @override
  Future<List<TemporaryDeck>> temporaryDecks() => guard(() async {
    final raw = await service.fetchTemporaryDecks();
    return [
      for (final row in raw['temporary_decks'] as List)
        temporaryDeckMapper.fromDTO(
          TemporaryDeckDTO.fromJson(row as Map<String, dynamic>),
        ),
    ];
  });

  @override
  Future<void> deleteTemporaryDeck(String id) =>
      guard(() => service.deleteTemporaryDeck(id));

  @override
  Future<SavedSession> saveSession(SessionDraft draft) => guard(() async {
    final raw = await service.postSession(
      sessionDraftMapper.toDTO(draft).toJson(),
    );
    return savedSessionMapper.fromDTO(SavedSessionDTO.fromJson(raw));
  });

  @override
  Future<List<SavedSession>> savedSessions() => guard(() async {
    final raw = await service.fetchSessions();
    return [
      for (final row in raw['sessions'] as List<dynamic>)
        savedSessionMapper.fromDTO(
          SavedSessionDTO.fromJson(row as Map<String, dynamic>),
        ),
    ];
  });
}
