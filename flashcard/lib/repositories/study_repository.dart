import 'package:flashcard/model/entities/review.dart';
import 'package:flashcard/model/entities/review_answer.dart';
import 'package:flashcard/model/entities/saved_session.dart';
import 'package:flashcard/model/entities/session_draft.dart';
import 'package:flashcard/model/entities/study_card.dart';
import 'package:flashcard/model/entities/study_stats.dart';
import 'package:flashcard/model/entities/temporary_deck.dart';
import 'package:flashcard/repositories/base_repository.dart';

abstract class StudyRepository extends BaseRepository<StudyCard> {
  Future<StudyCard?> nextCard({
    String? deckSlug,
    String? noteTitle,
    String? temporaryDeckId,
    required List<String> excludeIds,
  });

  Future<Review> submitReview(ReviewAnswer answer);

  Future<void> undoReview(String reviewId);

  StudyStats? cachedStats();

  Future<StudyStats> fetchStats();

  Future<List<TemporaryDeck>> temporaryDecks();

  Future<void> deleteTemporaryDeck(String id);

  Future<SavedSession> saveSession(SessionDraft draft);

  Future<List<SavedSession>> savedSessions();
}
