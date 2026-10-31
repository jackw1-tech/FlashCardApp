import 'package:flashcard/model/app_failure.dart';
import 'package:flashcard/model/entities/review.dart';
import 'package:flashcard/model/entities/review_answer.dart';
import 'package:flashcard/model/entities/study_card.dart';
import 'package:flashcard/model/entities/study_stats.dart';
import 'package:flashcard/model/entities/saved_session.dart';
import 'package:flashcard/model/entities/session_draft.dart';
import 'package:flashcard/model/entities/temporary_deck.dart';
import 'package:flashcard/repositories/study_repository.dart';
import 'package:flashcard/state_management/cubits/temporary_decks_cubit/temporary_decks_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

TemporaryDeck deck(String id) => TemporaryDeck(
  id: id,
  name: 'Mazzo $id',
  createdAt: DateTime(2026, 10, 26, 10),
  expiresAt: DateTime(2026, 10, 27),
  total: 10,
  done: 2,
  missed: 1,
);

class FakeStudyRepository implements StudyRepository {
  List<TemporaryDeck> decks = [deck('1'), deck('2')];
  AppFailure? failure;
  final deleted = <String>[];

  @override
  Future<SavedSession> saveSession(SessionDraft draft) =>
      throw UnimplementedError();

  @override
  Future<List<SavedSession>> savedSessions() => throw UnimplementedError();

  @override
  Future<List<TemporaryDeck>> temporaryDecks() async {
    if (failure case final f?) throw f;
    return decks;
  }

  @override
  Future<void> deleteTemporaryDeck(String id) async {
    if (failure case final f?) throw f;
    deleted.add(id);
  }

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
  Future<void> undoReview(String reviewId) => throw UnimplementedError();

  @override
  StudyStats? cachedStats() => null;

  @override
  Future<StudyStats> fetchStats() => throw UnimplementedError();
}

void main() {
  late FakeStudyRepository repository;
  late TemporaryDecksCubit cubit;

  setUp(() {
    repository = FakeStudyRepository();
    cubit = TemporaryDecksCubit(repository: repository);
  });

  tearDown(() => cubit.close());

  test('carica i mazzi provvisori', () async {
    await cubit.fetch();

    expect((cubit.state as FetchedTemporaryDecksState).decks.map((d) => d.id), [
      '1',
      '2',
    ]);
  });

  test('se l\'aggiornamento fallisce resta l\'elenco già mostrato', () async {
    await cubit.fetch();
    repository.failure = const NetworkFailure();

    await cubit.fetch();

    expect((cubit.state as FetchedTemporaryDecksState).decks, hasLength(2));
  });

  test('eliminare toglie subito il mazzo dall\'elenco', () async {
    await cubit.fetch();

    await cubit.delete('1');

    expect(repository.deleted, ['1']);
    expect((cubit.state as FetchedTemporaryDecksState).decks.map((d) => d.id), [
      '2',
    ]);
  });

  test(
    'se il server non elimina il mazzo, torna nell\'elenco con un avviso',
    () async {
      await cubit.fetch();
      repository.failure = const NetworkFailure();

      await cubit.delete('1');

      final state = cubit.state as FetchedTemporaryDecksState;
      expect(state.decks, hasLength(2));
      expect(state.notice, const NetworkFailure().message);
    },
  );
}
