import 'package:flashcard/model/app_failure.dart';
import 'package:flashcard/model/entities/decks_overview.dart';
import 'package:flashcard/repositories/deck_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'decks_cubit_state.dart';

class DecksCubit extends Cubit<DecksState> {
  final DeckRepository repository;

  DecksCubit({required this.repository}) : super(const FetchingDecksState());

  Future<void> fetch() async {
    final shown = switch (state) {
      FetchedDecksState(:final overview) => overview,
      _ => repository.cachedOverview(),
    };
    emit(
      shown == null
          ? const FetchingDecksState()
          : FetchedDecksState(shown, refreshing: true),
    );
    try {
      emit(FetchedDecksState(await repository.fetchOverview()));
    } on AppFailure catch (failure) {
      emit(
        shown == null
            ? ErrorDecksState(failure.message)
            : FetchedDecksState(
                shown,
                notice: 'Dati non aggiornati. ${failure.message}',
              ),
      );
    }
  }

  void reset() => emit(const FetchingDecksState());

  Future<void> rename(String slug, String name) async {
    final current = state;
    if (current is! FetchedDecksState) return;
    try {
      final saved = await repository.renameDeck(slug: slug, name: name);
      emit(FetchedDecksState(current.overview.withDeckName(slug, saved)));
    } on AppFailure catch (failure) {
      emit(
        FetchedDecksState(
          current.overview,
          notice: 'Nome non salvato. ${failure.message}',
        ),
      );
    }
  }
}
