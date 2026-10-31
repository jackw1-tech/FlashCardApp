part of 'decks_cubit.dart';

sealed class DecksState {
  const DecksState();
}

class FetchingDecksState extends DecksState {
  const FetchingDecksState();
}

class FetchedDecksState extends DecksState {
  final DecksOverview overview;

  final String? notice;

  final bool refreshing;

  const FetchedDecksState(
    this.overview, {
    this.notice,
    this.refreshing = false,
  });
}

class ErrorDecksState extends DecksState {
  final String message;

  const ErrorDecksState(this.message);
}
