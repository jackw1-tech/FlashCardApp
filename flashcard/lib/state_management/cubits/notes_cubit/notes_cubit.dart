import 'package:flashcard/model/app_failure.dart';
import 'package:flashcard/model/entities/note_summary.dart';
import 'package:flashcard/repositories/deck_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'notes_cubit_state.dart';

class NotesCubit extends Cubit<NotesState> {
  final DeckRepository repository;
  final String deckSlug;

  NotesCubit({required this.repository, required this.deckSlug})
    : super(const FetchingNotesState());

  Future<void> fetch() async {
    emit(const FetchingNotesState());
    try {
      emit(FetchedNotesState(await repository.fetchNotes(deckSlug)));
    } on AppFailure catch (failure) {
      emit(ErrorNotesState(failure.message));
    }
  }
}
