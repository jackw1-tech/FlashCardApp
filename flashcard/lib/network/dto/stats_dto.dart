import 'package:pine/pine.dart';

class DeckStatsDTO extends DTO {
  final String slug;
  final String name;
  final int reviews;
  final double? knewRatio;
  final String? lastStudiedAt;

  const DeckStatsDTO({
    required this.slug,
    required this.name,
    required this.reviews,
    this.knewRatio,
    this.lastStudiedAt,
  });

  factory DeckStatsDTO.fromJson(Map<String, dynamic> json) => DeckStatsDTO(
    slug: json['slug'] as String,
    name: json['name'] as String,
    reviews: json['reviews'] as int,
    knewRatio: (json['knew_ratio'] as num?)?.toDouble(),
    lastStudiedAt: json['last_studied_at'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'slug': slug,
    'name': name,
    'reviews': reviews,
    'knew_ratio': knewRatio,
    'last_studied_at': lastStudiedAt,
  };
}

class StatsDTO extends DTO {
  final String today;
  final int todayReviews;
  final int streakDays;
  final List<DeckStatsDTO> decks;

  const StatsDTO({
    required this.today,
    required this.todayReviews,
    required this.streakDays,
    required this.decks,
  });

  factory StatsDTO.fromJson(Map<String, dynamic> json) => StatsDTO(
    today: json['today'] as String,
    todayReviews: json['today_reviews'] as int,
    streakDays: json['streak_days'] as int,
    decks: [
      for (final deck in json['decks'] as List<dynamic>)
        DeckStatsDTO.fromJson(deck as Map<String, dynamic>),
    ],
  );

  Map<String, dynamic> toJson() => {
    'today': today,
    'today_reviews': todayReviews,
    'streak_days': streakDays,
    'decks': [for (final deck in decks) deck.toJson()],
  };
}
