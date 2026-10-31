import 'package:pine/pine.dart';

class DeckSummaryDTO extends DTO {
  final String slug;
  final String name;
  final int totalCards;
  final int unseenCards;
  final List<DeckSummaryDTO> subdecks;

  const DeckSummaryDTO({
    required this.slug,
    required this.name,
    required this.totalCards,
    required this.unseenCards,
    this.subdecks = const [],
  });

  factory DeckSummaryDTO.fromJson(Map<String, dynamic> json) => DeckSummaryDTO(
    slug: json['slug'] as String,
    name: json['name'] as String,
    totalCards: json['total_cards'] as int,
    unseenCards: json['unseen_cards'] as int,
    subdecks: [
      for (final deck in json['subdecks'] as List<dynamic>? ?? const [])
        DeckSummaryDTO.fromJson(deck as Map<String, dynamic>),
    ],
  );

  Map<String, dynamic> toJson() => {
    'slug': slug,
    'name': name,
    'total_cards': totalCards,
    'unseen_cards': unseenCards,
    'subdecks': [for (final deck in subdecks) deck.toJson()],
  };
}
