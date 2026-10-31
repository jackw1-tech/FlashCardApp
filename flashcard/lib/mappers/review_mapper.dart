import 'package:flashcard/mappers/review_outcome_wire.dart';
import 'package:flashcard/model/entities/review.dart';
import 'package:flashcard/network/dto/review_dto.dart';
import 'package:pine/pine.dart';

class ReviewMapper extends DTOMapper<ReviewDTO, Review> {
  const ReviewMapper();

  @override
  Review fromDTO(ReviewDTO dto) => Review(
    id: '${dto.id}',
    cardId: '${dto.cardId}',
    outcome: outcomeFromWire(dto.outcome),
    createdAt: DateTime.parse(dto.createdAt),
  );

  @override
  ReviewDTO toDTO(Review model) => ReviewDTO(
    id: int.parse(model.id),
    cardId: int.parse(model.cardId),
    outcome: outcomeToWire(model.outcome),
    createdAt: model.createdAt.toIso8601String(),
  );
}
