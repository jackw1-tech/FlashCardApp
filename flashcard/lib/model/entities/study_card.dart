import 'package:flashcard/model/base_model.dart';
import 'package:flashcard/model/entities/review_outcome.dart';

class StudyCard implements BaseModel {
  @override
  final String id;
  final String deckName;
  final String noteTitle;
  final String front;
  final String back;

  final List<ReviewOutcome> recentOutcomes;

  const StudyCard({
    required this.id,
    required this.deckName,
    required this.noteTitle,
    required this.front,
    required this.back,
    this.recentOutcomes = const [],
  });

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'deckName': deckName,
    'noteTitle': noteTitle,
    'front': front,
    'back': back,
    'recentOutcomes': [for (final o in recentOutcomes) o.name],
  };

  @override
  StudyCard copyWith({
    String? id,
    String? deckName,
    String? noteTitle,
    String? front,
    String? back,
    List<ReviewOutcome>? recentOutcomes,
  }) => StudyCard(
    id: id ?? this.id,
    deckName: deckName ?? this.deckName,
    noteTitle: noteTitle ?? this.noteTitle,
    front: front ?? this.front,
    back: back ?? this.back,
    recentOutcomes: recentOutcomes ?? this.recentOutcomes,
  );
}
