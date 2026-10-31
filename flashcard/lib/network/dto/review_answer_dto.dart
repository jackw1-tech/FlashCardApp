import 'package:pine/pine.dart';

class ReviewAnswerDTO extends DTO {
  final int cardId;
  final String outcome;

  const ReviewAnswerDTO({required this.cardId, required this.outcome});

  factory ReviewAnswerDTO.fromJson(Map<String, dynamic> json) =>
      ReviewAnswerDTO(
        cardId: json['card_id'] as int,
        outcome: json['outcome'] as String,
      );

  Map<String, dynamic> toJson() => {'card_id': cardId, 'outcome': outcome};
}
