import 'package:flashcard/model/entities/study_stats.dart';
import 'package:flashcard/network/dto/stats_dto.dart';
import 'package:pine/pine.dart';

class StudyStatsMapper extends DTOMapper<StatsDTO, StudyStats> {
  const StudyStatsMapper();

  @override
  StudyStats fromDTO(StatsDTO dto) => StudyStats(
    today: DateTime.parse(dto.today),
    todayReviews: dto.todayReviews,
    streakDays: dto.streakDays,
    decks: [
      for (final deck in dto.decks)
        DeckStats(
          id: deck.slug,
          name: deck.name,
          reviews: deck.reviews,
          knewRatio: deck.knewRatio,
          lastStudiedAt: deck.lastStudiedAt == null
              ? null
              : DateTime.parse(deck.lastStudiedAt!).toLocal(),
        ),
    ],
  );

  @override
  StatsDTO toDTO(StudyStats model) => StatsDTO(
    today: model.today.toIso8601String().substring(0, 10),
    todayReviews: model.todayReviews,
    streakDays: model.streakDays,
    decks: [
      for (final deck in model.decks)
        DeckStatsDTO(
          slug: deck.id,
          name: deck.name,
          reviews: deck.reviews,
          knewRatio: deck.knewRatio,
          lastStudiedAt: deck.lastStudiedAt?.toUtc().toIso8601String(),
        ),
    ],
  );
}
