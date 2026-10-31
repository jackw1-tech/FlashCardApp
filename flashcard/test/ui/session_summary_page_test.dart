import 'package:flashcard/model/entities/review.dart';
import 'package:flashcard/model/entities/review_answer.dart';
import 'package:flashcard/model/entities/saved_session.dart';
import 'package:flashcard/model/entities/session_draft.dart';
import 'package:flashcard/model/entities/session_summary.dart';
import 'package:flashcard/model/entities/study_card.dart';
import 'package:flashcard/model/entities/study_stats.dart';
import 'package:flashcard/model/entities/temporary_deck.dart';
import 'package:flashcard/repositories/study_repository.dart';
import 'package:flashcard/theme/app_theme.dart';
import 'package:flashcard/ui/pages/session_summary_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeStudyRepository implements StudyRepository {
  @override
  Future<SavedSession> saveSession(SessionDraft draft) =>
      throw UnimplementedError();

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
  testWidgets('il prompt di salvataggio entra nello schermo mobile', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      RepositoryProvider<StudyRepository>.value(
        value: _FakeStudyRepository(),
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const SessionSummaryPage(
            deckName: 'DSS',
            summary: SessionSummary(
              knew: 1,
              didntKnow: 1,
              reviewIds: ['1', '2'],
            ),
            sessionLength: 10,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Salvare questa sessione?'), findsOneWidget);
    expect(find.text('Salva'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
