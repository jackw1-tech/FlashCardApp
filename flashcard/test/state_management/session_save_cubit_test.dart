import 'package:flashcard/model/app_failure.dart';
import 'package:flashcard/model/entities/review.dart';
import 'package:flashcard/model/entities/review_answer.dart';
import 'package:flashcard/model/entities/saved_session.dart';
import 'package:flashcard/model/entities/session_draft.dart';
import 'package:flashcard/model/entities/study_card.dart';
import 'package:flashcard/model/entities/study_stats.dart';
import 'package:flashcard/model/entities/temporary_deck.dart';
import 'package:flashcard/repositories/study_repository.dart';
import 'package:flashcard/state_management/cubits/session_save_cubit/session_save_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeStudyRepository implements StudyRepository {
  SessionDraft? received;
  bool fail = false;

  @override
  Future<SavedSession> saveSession(SessionDraft draft) async {
    received = draft;
    if (fail) throw const NetworkFailure();
    return SavedSession(
      id: '1',
      startedAt: DateTime(2026),
      endedAt: DateTime(2026, 1, 1, 0, 5),
      knew: 1,
      didntKnow: 1,
    );
  }

  @override
  Future<List<SavedSession>> savedSessions() => throw UnimplementedError();

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
  Future<Review> submitReview(ReviewAnswer answer) =>
      throw UnimplementedError();
  @override
  Future<List<TemporaryDeck>> temporaryDecks() => throw UnimplementedError();
  @override
  Future<void> undoReview(String reviewId) => throw UnimplementedError();
}

void main() {
  late FakeStudyRepository repository;
  late SessionDraft draft;
  late SessionSaveCubit cubit;

  setUp(() {
    repository = FakeStudyRepository();
    draft = SessionDraft.create(reviewIds: const ['10', '11']);
    cubit = SessionSaveCubit(repository: repository, draft: draft);
  });

  tearDown(() => cubit.close());

  test('salva la stessa bozza idempotente e mostra il successo', () async {
    await cubit.save();

    expect(repository.received, same(draft));
    expect(cubit.state, isA<SavedSessionSaveState>());
  });

  test('dopo un errore permette di riprovare con la stessa bozza', () async {
    repository.fail = true;
    await cubit.save();
    expect(cubit.state, isA<ErrorSessionSaveState>());

    repository.fail = false;
    await cubit.save();

    expect(repository.received, same(draft));
    expect(cubit.state, isA<SavedSessionSaveState>());
  });

  test('può non salvare anche dopo un errore', () async {
    repository.fail = true;
    await cubit.save();

    cubit.skip();

    expect(cubit.state, isA<SkippedSessionSaveState>());
  });
}
