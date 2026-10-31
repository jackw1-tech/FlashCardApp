part of 'notes_cubit.dart';

sealed class NotesState {
  const NotesState();
}

class FetchingNotesState extends NotesState {
  const FetchingNotesState();
}

class FetchedNotesState extends NotesState {
  final List<NoteSummary> notes;

  const FetchedNotesState(this.notes);
}

class ErrorNotesState extends NotesState {
  final String message;

  const ErrorNotesState(this.message);
}
