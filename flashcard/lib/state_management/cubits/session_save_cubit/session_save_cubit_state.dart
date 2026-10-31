part of 'session_save_cubit.dart';

sealed class SessionSaveState {
  const SessionSaveState();
}

class AskingSessionSaveState extends SessionSaveState {
  const AskingSessionSaveState();
}

class SavingSessionSaveState extends SessionSaveState {
  const SavingSessionSaveState();
}

class SavedSessionSaveState extends SessionSaveState {
  final SavedSession session;

  const SavedSessionSaveState(this.session);
}

class SkippedSessionSaveState extends SessionSaveState {
  const SkippedSessionSaveState();
}

class ErrorSessionSaveState extends SessionSaveState {
  final String message;

  const ErrorSessionSaveState(this.message);
}
