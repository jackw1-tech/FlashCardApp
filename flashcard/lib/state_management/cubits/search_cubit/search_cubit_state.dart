part of 'search_cubit.dart';

sealed class SearchState {
  const SearchState();
}

class IdleSearchState extends SearchState {
  const IdleSearchState();
}

class SearchingSearchState extends SearchState {
  final String query;

  const SearchingSearchState(this.query);
}

class ResultsSearchState extends SearchState {
  final String query;
  final List<StudyCard> results;

  const ResultsSearchState(this.query, this.results);
}

class ErrorSearchState extends SearchState {
  final String message;

  const ErrorSearchState(this.message);
}
