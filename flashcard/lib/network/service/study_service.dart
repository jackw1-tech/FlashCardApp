import 'package:flashcard/network/service/base_service.dart';

abstract class StudyService extends BaseService {
  Future<Map<String, dynamic>> fetchNextCard({
    String? deckSlug,
    String? noteTitle,
    String? temporaryDeckId,
    required List<String> excludeIds,
  });

  Future<Map<String, dynamic>> postReview(Map<String, dynamic> body);

  Future<Map<String, dynamic>> undoReview(String reviewId);

  Future<Map<String, dynamic>> fetchStats();

  Future<Map<String, dynamic>> fetchTemporaryDecks();

  Future<void> deleteTemporaryDeck(String id);

  Future<Map<String, dynamic>> postSession(Map<String, dynamic> body);

  Future<Map<String, dynamic>> fetchSessions();
}
