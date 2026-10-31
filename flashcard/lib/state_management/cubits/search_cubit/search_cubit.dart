import 'dart:async';

import 'package:flashcard/model/app_failure.dart';
import 'package:flashcard/model/entities/study_card.dart';
import 'package:flashcard/other/constants/app_constants.dart';
import 'package:flashcard/repositories/card_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'search_cubit_state.dart';

class SearchCubit extends Cubit<SearchState> {
  final CardRepository repository;
  final Duration debounce;

  Timer? _timer;
  String _query = '';

  SearchCubit({
    required this.repository,
    this.debounce = AppConstants.searchDebounce,
  }) : super(const IdleSearchState());

  void queryChanged(String query) {
    _timer?.cancel();
    _query = query.trim();
    if (_query.length < AppConstants.searchMinLength) {
      emit(const IdleSearchState());
      return;
    }
    _timer = Timer(debounce, () => search(_query));
  }

  Future<void> search(String query) async {
    emit(SearchingSearchState(query));
    try {
      final results = await repository.search(query);
      if (query == _query && !isClosed) {
        emit(ResultsSearchState(query, results));
      }
    } on AppFailure catch (failure) {
      if (query == _query && !isClosed) {
        emit(ErrorSearchState(failure.message));
      }
    }
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
