import 'dart:math' as math;

import 'package:flashcard/model/app_failure.dart';
import 'package:flashcard/model/entities/review_answer.dart';
import 'package:flashcard/model/entities/review_outcome.dart';
import 'package:flashcard/model/entities/session_summary.dart';
import 'package:flashcard/model/entities/study_card.dart';
import 'package:flashcard/other/constants/app_constants.dart';
import 'package:flashcard/repositories/study_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'study_session_cubit_state.dart';

class _Answered {
  final StudyCard card;
  final String reviewId;
  final ReviewOutcome outcome;

  const _Answered(this.card, this.reviewId, this.outcome);
}

class StudySessionCubit extends Cubit<StudySessionState> {
  final StudyRepository repository;

  final String? deckSlug;

  final String? noteTitle;

  final String? temporaryDeckId;
  final List<StudyCard>? fixedCards;
  final int length;

  final List<_Answered> _answered = [];

  StudySessionCubit({
    required this.repository,
    this.deckSlug,
    this.noteTitle,
    this.temporaryDeckId,
    this.fixedCards,
    int length = AppConstants.sessionLength,
  }) : length = fixedCards?.length ?? length,
       super(const LoadingStudySessionState());

  List<String> get _seenIds => [for (final a in _answered) a.card.id];

  List<String> get _recentSeenIds {
    final seen = _seenIds;
    return List.unmodifiable(
      seen.skip(math.max(0, seen.length - AppConstants.maxExcludedIds)),
    );
  }

  SessionSummary get summary => SessionSummary(
    knew: _answered.where((a) => a.outcome == ReviewOutcome.knew).length,
    didntKnow: _answered
        .where((a) => a.outcome == ReviewOutcome.didntKnow)
        .length,
    missed: [
      for (final a in _answered)
        if (a.outcome == ReviewOutcome.didntKnow) a.card,
    ],
    reviewIds: [for (final a in _answered) a.reviewId],
  );

  bool get _canUndo => _answered.isNotEmpty;

  Future<void> loadNext() async {
    emit(const LoadingStudySessionState());
    try {
      final card = await _nextCard();
      emit(card == null ? FinishedStudySessionState(summary) : _showing(card));
    } on AppFailure catch (failure) {
      emit(ErrorStudySessionState(failure.message));
    }
  }

  Future<StudyCard?> _nextCard() async {
    final fixed = fixedCards;
    if (fixed != null) {
      final seen = _seenIds.toSet();
      return fixed.where((card) => !seen.contains(card.id)).firstOrNull;
    }
    return repository.nextCard(
      deckSlug: deckSlug,
      noteTitle: noteTitle,
      temporaryDeckId: temporaryDeckId,
      excludeIds: _recentSeenIds,
    );
  }

  ShowingCardStudySessionState _showing(StudyCard card) =>
      ShowingCardStudySessionState(
        card: card,
        position: _answered.length + 1,
        length: length,
        summary: summary,
        canUndo: _canUndo,
      );

  void reveal() {
    if (state case final ShowingCardStudySessionState showing
        when !showing.revealed) {
      emit(showing.copyWith(revealed: true));
    }
  }

  Future<void> answer(ReviewOutcome outcome) async {
    final current = state;
    if (current is! ShowingCardStudySessionState ||
        !current.revealed ||
        current.submitting) {
      return;
    }

    emit(current.copyWith(submitting: true, clearError: true));
    final String reviewId;
    try {
      final review = await repository.submitReview(
        ReviewAnswer.create(cardId: current.card.id, outcome: outcome),
      );
      reviewId = review.id;
    } on AppFailure catch (failure) {
      emit(
        current.copyWith(
          submitting: false,
          error: failure.message,
          failedOutcome: outcome,
        ),
      );
      return;
    }

    _answered.add(_Answered(current.card, reviewId, outcome));
    if (_answered.length >= length) {
      emit(FinishedStudySessionState(summary));
    } else {
      await loadNext();
    }
  }

  Future<void> undo() async {
    final current = state;
    if (current is! ShowingCardStudySessionState ||
        current.submitting ||
        !_canUndo) {
      return;
    }

    emit(current.copyWith(submitting: true, clearError: true));
    final last = _answered.last;
    try {
      await repository.undoReview(last.reviewId);
    } on AppFailure catch (failure) {
      emit(
        current.copyWith(
          submitting: false,
          notice: 'Annullamento non riuscito. ${failure.message}',
        ),
      );
      return;
    }
    _answered.removeLast();
    emit(_showing(last.card));
  }

  void finish() => emit(FinishedStudySessionState(summary));
}
