part of 'saved_sessions_cubit.dart';

sealed class SavedSessionsState {
  const SavedSessionsState();
}

class FetchingSavedSessionsState extends SavedSessionsState {
  const FetchingSavedSessionsState();
}

class FetchedSavedSessionsState extends SavedSessionsState {
  final List<SavedSession> sessions;

  const FetchedSavedSessionsState(this.sessions);
}

class ErrorSavedSessionsState extends SavedSessionsState {
  final String message;

  const ErrorSavedSessionsState(this.message);
}
