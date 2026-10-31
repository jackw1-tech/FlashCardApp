import 'package:pine/pine.dart';

class SessionRequestDTO extends DTO {
  final String clientId;
  final List<int> reviewIds;
  final String? deck;
  final String? note;
  final int? temporaryDeck;

  const SessionRequestDTO({
    required this.clientId,
    required this.reviewIds,
    this.deck,
    this.note,
    this.temporaryDeck,
  });

  factory SessionRequestDTO.fromJson(Map<String, dynamic> json) =>
      SessionRequestDTO(
        clientId: json['client_id'] as String,
        reviewIds: [for (final id in json['review_ids'] as List) id as int],
        deck: json['deck'] as String?,
        note: json['note'] as String?,
        temporaryDeck: json['temporary_deck'] as int?,
      );

  Map<String, dynamic> toJson() => {
    'client_id': clientId,
    'review_ids': reviewIds,
    'deck': ?deck,
    'note': ?note,
    'temporary_deck': ?temporaryDeck,
  };
}
