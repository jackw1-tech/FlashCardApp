part of 'temporary_decks_cubit.dart';

sealed class TemporaryDecksState {
  const TemporaryDecksState();
}

class FetchingTemporaryDecksState extends TemporaryDecksState {
  const FetchingTemporaryDecksState();
}

class FetchedTemporaryDecksState extends TemporaryDecksState {
  final List<TemporaryDeck> decks;

  final String? notice;

  const FetchedTemporaryDecksState(this.decks, {this.notice});
}

class ErrorTemporaryDecksState extends TemporaryDecksState {
  final String message;

  const ErrorTemporaryDecksState(this.message);
}
