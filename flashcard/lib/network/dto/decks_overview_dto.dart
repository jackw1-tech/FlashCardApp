import 'package:flashcard/network/dto/deck_summary_dto.dart';
import 'package:pine/pine.dart';

class DecksOverviewDTO extends DTO {
  final int totalCards;
  final int unseenCards;
  final List<DeckSummaryDTO> decks;

  const DecksOverviewDTO({
    required this.totalCards,
    required this.unseenCards,
    required this.decks,
  });

  factory DecksOverviewDTO.fromJson(Map<String, dynamic> json) {
    final all = json['all'] as Map<String, dynamic>;
    return DecksOverviewDTO(
      totalCards: all['total_cards'] as int,
      unseenCards: all['unseen_cards'] as int,
      decks: (json['decks'] as List<dynamic>)
          .map((deck) => DeckSummaryDTO.fromJson(deck as Map<String, dynamic>))
          .toList(growable: false),
    );
  }

  Map<String, dynamic> toJson() => {
    'all': {'total_cards': totalCards, 'unseen_cards': unseenCards},
    'decks': decks.map((deck) => deck.toJson()).toList(growable: false),
  };
}
