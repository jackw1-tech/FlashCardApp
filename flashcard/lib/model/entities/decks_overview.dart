import 'package:flashcard/model/entities/deck_summary.dart';

class DecksOverview {
  final int totalCards;
  final int unseenCards;
  final List<DeckSummary> decks;

  const DecksOverview({
    required this.totalCards,
    required this.unseenCards,
    required this.decks,
  });

  DecksOverview withDeckName(String slug, String name) => DecksOverview(
    totalCards: totalCards,
    unseenCards: unseenCards,
    decks: [for (final deck in decks) _withDeckName(deck, slug, name)],
  );

  static DeckSummary _withDeckName(
    DeckSummary deck,
    String slug,
    String name,
  ) => deck.copyWith(
    name: deck.id == slug ? name : deck.name,
    subdecks: [
      for (final child in deck.subdecks) _withDeckName(child, slug, name),
    ],
  );
}
