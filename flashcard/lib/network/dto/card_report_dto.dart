import 'package:flashcard/network/dto/card_dto.dart';
import 'package:pine/pine.dart';

class CardReportDTO extends DTO {
  final int id;
  final String reason;
  final String comment;
  final String createdAt;
  final CardDTO card;

  const CardReportDTO({
    required this.id,
    required this.reason,
    required this.comment,
    required this.createdAt,
    required this.card,
  });

  factory CardReportDTO.fromJson(Map<String, dynamic> json) => CardReportDTO(
    id: json['id'] as int,
    reason: json['reason'] as String,
    comment: json['comment'] as String,
    createdAt: json['created_at'] as String,
    card: CardDTO.fromJson(json['card'] as Map<String, dynamic>),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'reason': reason,
    'comment': comment,
    'created_at': createdAt,
    'card': card.toJson(),
  };
}
