import 'package:flashcard/network/service/impl/base_service_impl.dart';
import 'package:flashcard/network/service/study_service.dart';
import 'package:flashcard/other/constants/api_constants.dart';

class StudyServiceImpl extends BaseServiceImpl implements StudyService {
  StudyServiceImpl({
    required super.client,
    required super.baseUrl,
    super.prefetch,
  });

  @override
  Future<Map<String, dynamic>> fetchNextCard({
    String? deckSlug,
    String? noteTitle,
    String? temporaryDeckId,
    required List<String> excludeIds,
  }) => getJson(
    ApiConstants.nextCardPath,
    query: {
      'deck': ?deckSlug,
      'note': ?noteTitle,
      'temporary_deck': ?temporaryDeckId,
      if (excludeIds.isNotEmpty) 'exclude': excludeIds.join(','),
    },
  );

  @override
  Future<Map<String, dynamic>> postReview(Map<String, dynamic> body) =>
      postJson(ApiConstants.reviewsPath, body);

  @override
  Future<Map<String, dynamic>> undoReview(String reviewId) =>
      postJson(ApiConstants.undoReviewPath(reviewId), const {});

  @override
  Future<Map<String, dynamic>> fetchStats() =>
      getJsonPrefetched('stats', ApiConstants.statsPath);

  @override
  Future<Map<String, dynamic>> fetchTemporaryDecks() =>
      getJson(ApiConstants.temporaryDecksPath);

  @override
  Future<void> deleteTemporaryDeck(String id) =>
      delete(ApiConstants.temporaryDeckPath(id));

  @override
  Future<Map<String, dynamic>> postSession(Map<String, dynamic> body) =>
      postJson(ApiConstants.sessionsPath, body);

  @override
  Future<Map<String, dynamic>> fetchSessions() =>
      getJson(ApiConstants.sessionsPath);
}
