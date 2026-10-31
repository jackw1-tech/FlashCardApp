import 'package:flashcard/model/app_failure.dart';
import 'package:flashcard/model/entities/review.dart';
import 'package:flashcard/model/entities/review_answer.dart';
import 'package:flashcard/model/entities/review_outcome.dart';
import 'package:flashcard/model/entities/study_card.dart';
import 'package:flashcard/model/entities/study_stats.dart';
import 'package:flashcard/model/entities/saved_session.dart';
import 'package:flashcard/model/entities/session_draft.dart';
import 'package:flashcard/model/entities/temporary_deck.dart';
import 'package:flashcard/other/constants/app_constants.dart';
import 'package:flashcard/repositories/study_repository.dart';
import 'package:flashcard/state_management/cubits/study_session_cubit/study_session_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

StudyCard card(String id, {String note = 'N'}) => StudyCard(
  id: id,
  deckName: 'D',
  noteTitle: note,
  front: 'Q$id',
  back: 'A$id',
);

class FakeStudyRepository implements StudyRepository {
  final List<StudyCard> cards;
  final List<ReviewAnswer> submitted = [];
  final Set<String> undone = {};
  final List<List<String>> excludeRequests = [];
  final List<String?> noteRequests = [];
  bool failNextReview = false;
  bool failNextUndo = false;

  FakeStudyRepository(this.cards);

  @override
  Future<SavedSession> saveSession(SessionDraft draft) =>
      throw UnimplementedError();

  @override
  Future<List<SavedSession>> savedSessions() => throw UnimplementedError();

  List<ReviewAnswer> get valid => [
    for (final (i, a) in submitted.indexed)
      if (!undone.contains('$i')) a,
  ];

  @override
  Future<StudyCard?> nextCard({
    String? deckSlug,
    String? noteTitle,
    String? temporaryDeckId,
    required List<String> excludeIds,
  }) async {
    excludeRequests.add(excludeIds);
    noteRequests.add(noteTitle);
    final candidates = cards.where(
      (c) =>
          !excludeIds.contains(c.id) &&
          (noteTitle == null || c.noteTitle == noteTitle),
    );
    final lastSeen = {for (final (i, a) in valid.indexed) a.cardId: i};
    final unseen = candidates.where((c) => !lastSeen.containsKey(c.id));
    if (unseen.isNotEmpty) return unseen.first;
    final seen = candidates.toList()
      ..sort((a, b) => lastSeen[a.id]!.compareTo(lastSeen[b.id]!));
    return seen.firstOrNull;
  }

  @override
  Future<Review> submitReview(ReviewAnswer answer) async {
    if (failNextReview) {
      failNextReview = false;
      throw const NetworkFailure();
    }
    submitted.add(answer);
    return Review(
      id: '${submitted.length - 1}',
      cardId: answer.cardId,
      outcome: answer.outcome,
      createdAt: DateTime(2026),
    );
  }

  @override
  Future<void> undoReview(String reviewId) async {
    if (failNextUndo) {
      failNextUndo = false;
      throw const NetworkFailure();
    }
    undone.add(reviewId);
  }

  @override
  StudyStats? cachedStats() => null;

  @override
  Future<StudyStats> fetchStats() => throw UnimplementedError();

  @override
  Future<List<TemporaryDeck>> temporaryDecks() async => const [];

  @override
  Future<void> deleteTemporaryDeck(String id) async {}
}

void main() {
  late FakeStudyRepository repository;
  late StudySessionCubit cubit;

  setUp(() {
    repository = FakeStudyRepository([card('1'), card('2'), card('3')]);
    cubit = StudySessionCubit(repository: repository, length: 2);
  });

  tearDown(() => cubit.close());

  ShowingCardStudySessionState showing() =>
      cubit.state as ShowingCardStudySessionState;

  Future<void> revealAndAnswer(ReviewOutcome outcome) async {
    cubit.reveal();
    await cubit.answer(outcome);
  }

  test('mostra la prima card nascondendo la risposta', () async {
    await cubit.loadNext();

    expect(
      (
        showing().card.id,
        showing().position,
        showing().revealed,
        showing().canUndo,
      ),
      ('1', 1, false, false),
    );
  });

  test('non accetta una risposta prima di aver girato la card', () async {
    await cubit.loadNext();

    await cubit.answer(ReviewOutcome.knew);

    expect(repository.submitted, isEmpty);
  });

  test('dopo una risposta confermata chiede la card successiva escludendo quelle viste', () async {
    await cubit.loadNext();

    await revealAndAnswer(ReviewOutcome.knew);

    expect(showing().card.id, '2');
    expect(showing().canUndo, isTrue);
    expect(repository.excludeRequests.last, ['1']);
  });

  test(
    'se la Review fallisce resta sulla card con l\'errore e non passa avanti',
    () async {
      await cubit.loadNext();
      repository.failNextReview = true;

      await revealAndAnswer(ReviewOutcome.didntKnow);

      expect(showing().card.id, '1');
      expect(showing().error, isNotNull);
      expect(showing().failedOutcome, ReviewOutcome.didntKnow);

      await cubit.answer(showing().failedOutcome!);
      expect(showing().card.id, '2');
      expect(repository.submitted.single.outcome, ReviewOutcome.didntKnow);
    },
  );

  test('finisce dopo il numero di card della Sessione con il riepilogo e le sbagliate', () async {
    await cubit.loadNext();

    await revealAndAnswer(ReviewOutcome.knew);
    await revealAndAnswer(ReviewOutcome.didntKnow);

    final summary = (cubit.state as FinishedStudySessionState).summary;
    expect((summary.knew, summary.didntKnow), (1, 1));
    expect(summary.missed.map((c) => c.id), ['2']);
    expect(summary.reviewIds, ['0', '1']);
  });

  test('finisce prima se il backend non ha altre card', () async {
    repository = FakeStudyRepository([card('1')]);
    cubit = StudySessionCubit(repository: repository, length: 20);
    await cubit.loadNext();

    await revealAndAnswer(ReviewOutcome.knew);

    final summary = (cubit.state as FinishedStudySessionState).summary;
    expect((summary.knew, summary.didntKnow), (1, 0));
  });

  test('la chiusura anticipata tiene solo le risposte confermate', () async {
    await cubit.loadNext();
    await revealAndAnswer(ReviewOutcome.knew);

    cubit.finish();

    final summary = (cubit.state as FinishedStudySessionState).summary;
    expect((summary.knew, summary.didntKnow), (1, 0));
  });

  test('manda al backend solo gli ultimi ID visti, per non allungare troppo l\'URL', () async {
    repository = FakeStudyRepository([
      for (var i = 1; i <= 70; i++) card('$i'),
    ]);
    cubit = StudySessionCubit(repository: repository, length: 60);
    await cubit.loadNext();

    for (var i = 0; i < 55; i++) {
      await revealAndAnswer(ReviewOutcome.knew);
    }

    final lastExclude = repository.excludeRequests.last;
    expect(lastExclude, hasLength(AppConstants.maxExcludedIds));
    expect((lastExclude.first, lastExclude.last), ('6', '55'));
    expect(showing().position, 56);
  });

  group('annulla', () {
    test('ripropone la card appena risposta, nascosta, e toglie la risposta dai conteggi', () async {
      cubit = StudySessionCubit(repository: repository, length: 3);
      await cubit.loadNext();
      await revealAndAnswer(ReviewOutcome.didntKnow);

      await cubit.undo();

      expect(
        (showing().card.id, showing().position, showing().revealed),
        ('1', 1, false),
      );
      expect((showing().summary.knew, showing().summary.didntKnow), (0, 0));
      expect(showing().canUndo, isFalse);
      expect(repository.undone, {'0'});
    });

    test('dopo l\'annullamento si può rispondere di nuovo', () async {
      cubit = StudySessionCubit(repository: repository, length: 3);
      await cubit.loadNext();
      await revealAndAnswer(ReviewOutcome.didntKnow);
      await cubit.undo();

      await revealAndAnswer(ReviewOutcome.knew);

      expect((showing().summary.knew, showing().summary.didntKnow), (1, 0));
      expect(showing().position, 2);
    });

    test(
      'se l\'annullamento fallisce resta tutto com\'era con un avviso',
      () async {
        cubit = StudySessionCubit(repository: repository, length: 3);
        await cubit.loadNext();
        await revealAndAnswer(ReviewOutcome.knew);
        repository.failNextUndo = true;

        await cubit.undo();

        expect((showing().card.id, showing().position), ('2', 2));
        expect(showing().notice, contains('Annullamento non riuscito'));
        expect(showing().summary.knew, 1);
      },
    );
  });

  test(
    'con una lista fissa ripassa solo quelle card, senza chiederne al backend',
    () async {
      cubit = StudySessionCubit(
        repository: repository,
        fixedCards: [card('3'), card('1')],
      );
      await cubit.loadNext();

      expect((showing().card.id, showing().length), ('3', 2));
      await revealAndAnswer(ReviewOutcome.knew);
      expect(showing().card.id, '1');
      await revealAndAnswer(ReviewOutcome.knew);

      expect(cubit.state, isA<FinishedStudySessionState>());
      expect(repository.excludeRequests, isEmpty);
      expect(repository.submitted.map((a) => a.cardId), ['3', '1']);
    },
  );

  test('il filtro per nota arriva al backend', () async {
    repository = FakeStudyRepository([
      card('1', note: 'A'),
      card('2', note: 'B'),
    ]);
    cubit = StudySessionCubit(repository: repository, noteTitle: 'B');

    await cubit.loadNext();

    expect(showing().card.id, '2');
    expect(repository.noteRequests.single, 'B');
  });
}
