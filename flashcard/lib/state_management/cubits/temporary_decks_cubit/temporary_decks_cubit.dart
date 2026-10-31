import 'package:flashcard/model/app_failure.dart';
import 'package:flashcard/model/entities/temporary_deck.dart';
import 'package:flashcard/repositories/study_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'temporary_decks_cubit_state.dart';

class TemporaryDecksCubit extends Cubit<TemporaryDecksState> {
  final StudyRepository repository;

  TemporaryDecksCubit({required this.repository})
    : super(const FetchingTemporaryDecksState());

  Future<void> fetch() async {
    final shown = state;
    if (shown is! FetchedTemporaryDecksState) {
      emit(const FetchingTemporaryDecksState());
    }
    try {
      emit(FetchedTemporaryDecksState(await repository.temporaryDecks()));
    } on AppFailure catch (failure) {
      if (shown is! FetchedTemporaryDecksState) {
        emit(ErrorTemporaryDecksState(failure.message));
      }
    }
  }

  Future<void> delete(String id) async {
    final current = state;
    if (current is! FetchedTemporaryDecksState) return;
    emit(
      FetchedTemporaryDecksState([
        for (final deck in current.decks)
          if (deck.id != id) deck,
      ]),
    );
    try {
      await repository.deleteTemporaryDeck(id);
    } on AppFailure catch (failure) {
      emit(FetchedTemporaryDecksState(current.decks, notice: failure.message));
    }
  }

  void reset() => emit(const FetchingTemporaryDecksState());
}
