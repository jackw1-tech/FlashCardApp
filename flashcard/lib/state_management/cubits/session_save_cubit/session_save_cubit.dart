import 'package:flashcard/model/app_failure.dart';
import 'package:flashcard/model/entities/saved_session.dart';
import 'package:flashcard/model/entities/session_draft.dart';
import 'package:flashcard/repositories/study_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'session_save_cubit_state.dart';

class SessionSaveCubit extends Cubit<SessionSaveState> {
  final StudyRepository repository;
  final SessionDraft draft;

  SessionSaveCubit({required this.repository, required this.draft})
    : super(const AskingSessionSaveState());

  Future<void> save() async {
    if (state is SavingSessionSaveState || state is SavedSessionSaveState) {
      return;
    }
    emit(const SavingSessionSaveState());
    try {
      emit(SavedSessionSaveState(await repository.saveSession(draft)));
    } on AppFailure catch (failure) {
      emit(ErrorSessionSaveState(failure.message));
    }
  }

  void skip() {
    if (state is AskingSessionSaveState || state is ErrorSessionSaveState) {
      emit(const SkippedSessionSaveState());
    }
  }
}
