import 'package:flashcard/model/app_failure.dart';
import 'package:flashcard/model/entities/review.dart';
import 'package:flashcard/model/entities/review_answer.dart';
import 'package:flashcard/model/entities/saved_session.dart';
import 'package:flashcard/model/entities/session_draft.dart';
import 'package:flashcard/model/entities/study_card.dart';
import 'package:flashcard/model/entities/study_stats.dart';
import 'package:flashcard/model/entities/temporary_deck.dart';
import 'package:flashcard/repositories/study_repository.dart';
import 'package:flashcard/state_management/cubits/saved_sessions_cubit/saved_sessions_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeStudyRepository implements StudyRepository {
  AppFailure? failure;

  @override
  Future<List<SavedSession>> savedSessions() async {
    if (failure case final error?) throw error;
    return [
      SavedSession(
        id: '1',
        startedAt: DateTime(2026),
        endedAt: DateTime(2026, 1, 1, 0, 5),
        knew: 8,
        didntKnow: 2,
        deckName: 'DDIA',
      ),
    ];
  }

  @override
  StudyStats? cachedStats() => throw UnimplementedError();
  @override
  Future<void> deleteTemporaryDeck(String id) => throw UnimplementedError();
  @override
  Future<StudyStats> fetchStats() => throw UnimplementedError();
  @override
  Future<StudyCard?> nextCard({
    String? deckSlug,
    String? noteTitle,
    String? temporaryDeckId,
    required List<String> excludeIds,
  }) => throw UnimplementedError();
  @override
  Future<SavedSession> saveSession(SessionDraft draft) =>
      throw UnimplementedError();
  @override
  Future<Review> submitReview(ReviewAnswer answer) =>
      throw UnimplementedError();
  @override
  Future<List<TemporaryDeck>> temporaryDecks() => throw UnimplementedError();
  @override
  Future<void> undoReview(String reviewId) => throw UnimplementedError();
}

void main() {
  late FakeStudyRepository repository;
  late SavedSessionsCubit cubit;

  setUp(() {
    repository = FakeStudyRepository();
    cubit = SavedSessionsCubit(repository: repository);
  });

  tearDown(() => cubit.close());

  test('carica lo storico delle sessioni', () async {
    await cubit.fetch();

    final state = cubit.state as FetchedSavedSessionsState;
    expect(
      (state.sessions.single.deckName, state.sessions.single.total),
      ('DDIA', 10),
    );
  });

  test('espone un errore recuperabile', () async {
    repository.failure = const NetworkFailure();

    await cubit.fetch();

    expect(cubit.state, isA<ErrorSavedSessionsState>());
  });
}
