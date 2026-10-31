import 'package:pine/pine.dart';

class CardDTO extends DTO {
  final int id;
  final String deckSlug;
  final String deckName;
  final String noteTitle;
  final String kind;
  final String front;
  final String back;

  final List<String> recentOutcomes;

  const CardDTO({
    required this.id,
    required this.deckSlug,
    required this.deckName,
    required this.noteTitle,
    required this.kind,
    required this.front,
    required this.back,
    this.recentOutcomes = const [],
  });

  factory CardDTO.fromJson(Map<String, dynamic> json) {
    final deck = json['deck'] as Map<String, dynamic>;
    return CardDTO(
      id: json['id'] as int,
      deckSlug: deck['slug'] as String,
      deckName: deck['name'] as String,
      noteTitle: json['note_title'] as String,
      kind: json['kind'] as String,
      front: json['front'] as String,
      back: json['back'] as String,
      recentOutcomes: [
        for (final outcome in json['recent_outcomes'] as List<dynamic>? ?? [])
          outcome as String,
      ],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'deck': {'slug': deckSlug, 'name': deckName},
    'note_title': noteTitle,
    'kind': kind,
    'front': front,
    'back': back,
    'recent_outcomes': recentOutcomes,
  };
}
