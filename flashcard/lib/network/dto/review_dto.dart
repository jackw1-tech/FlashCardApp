import 'package:pine/pine.dart';

class ReviewDTO extends DTO {
  final int id;
  final int cardId;
  final String outcome;
  final String createdAt;

  const ReviewDTO({
    required this.id,
    required this.cardId,
    required this.outcome,
    required this.createdAt,
  });

  factory ReviewDTO.fromJson(Map<String, dynamic> json) => ReviewDTO(
    id: json['id'] as int,
    cardId: json['card_id'] as int,
    outcome: json['outcome'] as String,
    createdAt: json['created_at'] as String,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'card_id': cardId,
    'outcome': outcome,
    'created_at': createdAt,
  };
}
