import 'package:flashcard/model/base_model.dart';

class DeckStats implements BaseModel {
  @override
  final String id;
  final String name;
  final int reviews;

  final double? knewRatio;
  final DateTime? lastStudiedAt;

  const DeckStats({
    required this.id,
    required this.name,
    required this.reviews,
    this.knewRatio,
    this.lastStudiedAt,
  });

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'reviews': reviews,
    'knewRatio': knewRatio,
    'lastStudiedAt': lastStudiedAt?.toIso8601String(),
  };

  @override
  DeckStats copyWith({String? id, String? name, int? reviews}) => DeckStats(
    id: id ?? this.id,
    name: name ?? this.name,
    reviews: reviews ?? this.reviews,
    knewRatio: knewRatio,
    lastStudiedAt: lastStudiedAt,
  );
}

class StudyStats {
  final DateTime today;
  final int todayReviews;
  final int streakDays;
  final List<DeckStats> decks;

  const StudyStats({
    required this.today,
    required this.todayReviews,
    required this.streakDays,
    required this.decks,
  });
}
