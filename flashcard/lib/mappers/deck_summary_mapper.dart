import 'package:flashcard/model/entities/deck_summary.dart';
import 'package:flashcard/network/dto/deck_summary_dto.dart';
import 'package:pine/pine.dart';

class DeckSummaryMapper extends DTOMapper<DeckSummaryDTO, DeckSummary> {
  const DeckSummaryMapper();

  @override
  DeckSummary fromDTO(DeckSummaryDTO dto) => DeckSummary(
    id: dto.slug,
    name: dto.name,
    totalCards: dto.totalCards,
    unseenCards: dto.unseenCards,
    subdecks: [for (final deck in dto.subdecks) fromDTO(deck)],
  );

  @override
  DeckSummaryDTO toDTO(DeckSummary model) => DeckSummaryDTO(
    slug: model.id,
    name: model.name,
    totalCards: model.totalCards,
    unseenCards: model.unseenCards,
    subdecks: [for (final deck in model.subdecks) toDTO(deck)],
  );
}
