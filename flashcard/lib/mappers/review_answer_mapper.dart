import 'package:flashcard/mappers/review_outcome_wire.dart';
import 'package:flashcard/model/entities/review_answer.dart';
import 'package:flashcard/network/dto/review_answer_dto.dart';
import 'package:pine/pine.dart';

class ReviewAnswerMapper extends DTOMapper<ReviewAnswerDTO, ReviewAnswer> {
  const ReviewAnswerMapper();

  @override
  ReviewAnswer fromDTO(ReviewAnswerDTO dto) => ReviewAnswer.create(
    cardId: '${dto.cardId}',
    outcome: outcomeFromWire(dto.outcome),
  );

  @override
  ReviewAnswerDTO toDTO(ReviewAnswer model) => ReviewAnswerDTO(
    cardId: int.parse(model.cardId),
    outcome: outcomeToWire(model.outcome),
  );
}
