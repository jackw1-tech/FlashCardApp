import 'package:flashcard/model/base_model.dart';
import 'package:flashcard/model/entities/review_outcome.dart';
import 'package:uuid/uuid.dart';

class ReviewAnswer implements BaseModel {
  @override
  final String id;
  final String cardId;
  final ReviewOutcome outcome;

  const ReviewAnswer({
    required this.id,
    required this.cardId,
    required this.outcome,
  });

  ReviewAnswer.create({required this.cardId, required this.outcome})
    : id = const Uuid().v4();

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'cardId': cardId,
    'outcome': outcome.name,
  };

  @override
  ReviewAnswer copyWith({String? id, String? cardId, ReviewOutcome? outcome}) =>
      ReviewAnswer(
        id: id ?? this.id,
        cardId: cardId ?? this.cardId,
        outcome: outcome ?? this.outcome,
      );
}
