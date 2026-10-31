part of 'study_session_cubit.dart';

sealed class StudySessionState {
  const StudySessionState();
}

class LoadingStudySessionState extends StudySessionState {
  const LoadingStudySessionState();
}

class ShowingCardStudySessionState extends StudySessionState {
  final StudyCard card;

  final int position;
  final int length;

  final SessionSummary summary;
  final bool revealed;
  final bool submitting;

  final bool canUndo;

  final String? error;

  final ReviewOutcome? failedOutcome;

  final String? notice;

  const ShowingCardStudySessionState({
    required this.card,
    required this.position,
    required this.length,
    required this.summary,
    this.revealed = false,
    this.submitting = false,
    this.canUndo = false,
    this.error,
    this.failedOutcome,
    this.notice,
  });

  ShowingCardStudySessionState copyWith({
    bool? revealed,
    bool? submitting,
    String? error,
    ReviewOutcome? failedOutcome,
    String? notice,
    bool clearError = false,
  }) => ShowingCardStudySessionState(
    card: card,
    position: position,
    length: length,
    summary: summary,
    canUndo: canUndo,
    revealed: revealed ?? this.revealed,
    submitting: submitting ?? this.submitting,
    error: clearError ? null : error ?? this.error,
    failedOutcome: clearError ? null : failedOutcome ?? this.failedOutcome,
    notice: notice,
  );
}

class ErrorStudySessionState extends StudySessionState {
  final String message;

  const ErrorStudySessionState(this.message);
}

class FinishedStudySessionState extends StudySessionState {
  final SessionSummary summary;

  const FinishedStudySessionState(this.summary);
}
