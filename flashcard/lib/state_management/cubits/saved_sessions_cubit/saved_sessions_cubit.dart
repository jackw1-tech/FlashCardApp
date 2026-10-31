import 'package:flashcard/model/app_failure.dart';
import 'package:flashcard/model/entities/saved_session.dart';
import 'package:flashcard/repositories/study_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'saved_sessions_cubit_state.dart';

class SavedSessionsCubit extends Cubit<SavedSessionsState> {
  final StudyRepository repository;

  SavedSessionsCubit({required this.repository})
    : super(const FetchingSavedSessionsState());

  Future<void> fetch() async {
    emit(const FetchingSavedSessionsState());
    try {
      emit(FetchedSavedSessionsState(await repository.savedSessions()));
    } on AppFailure catch (failure) {
      emit(ErrorSavedSessionsState(failure.message));
    }
  }
}
