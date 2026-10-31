import 'package:flashcard/model/base_model.dart';
import 'package:flashcard/model/entities/review_outcome.dart';

class Review implements BaseModel {
  @override
  final String id;
  final String cardId;
  final ReviewOutcome outcome;
  final DateTime createdAt;

  const Review({
    required this.id,
    required this.cardId,
    required this.outcome,
    required this.createdAt,
  });

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'cardId': cardId,
    'outcome': outcome.name,
    'createdAt': createdAt.toIso8601String(),
  };

  @override
  Review copyWith({
    String? id,
    String? cardId,
    ReviewOutcome? outcome,
    DateTime? createdAt,
  }) => Review(
    id: id ?? this.id,
    cardId: cardId ?? this.cardId,
    outcome: outcome ?? this.outcome,
    createdAt: createdAt ?? this.createdAt,
  );
}
