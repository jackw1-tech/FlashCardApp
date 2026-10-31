import 'package:flashcard/mappers/deck_summary_mapper.dart';
import 'package:flashcard/model/entities/decks_overview.dart';
import 'package:flashcard/network/dto/decks_overview_dto.dart';
import 'package:pine/pine.dart';

class DecksOverviewMapper extends DTOMapper<DecksOverviewDTO, DecksOverview> {
  final DeckSummaryMapper deckMapper;

  const DecksOverviewMapper({this.deckMapper = const DeckSummaryMapper()});

  @override
  DecksOverview fromDTO(DecksOverviewDTO dto) => DecksOverview(
    totalCards: dto.totalCards,
    unseenCards: dto.unseenCards,
    decks: deckMapper.fromDTOMany(dto.decks).toList(growable: false),
  );

  @override
  DecksOverviewDTO toDTO(DecksOverview model) => DecksOverviewDTO(
    totalCards: model.totalCards,
    unseenCards: model.unseenCards,
    decks: deckMapper.toDTOMany(model.decks).toList(growable: false),
  );
}
