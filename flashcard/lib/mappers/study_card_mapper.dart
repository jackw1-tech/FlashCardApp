import 'package:flashcard/mappers/review_outcome_wire.dart';
import 'package:flashcard/model/entities/study_card.dart';
import 'package:flashcard/network/dto/card_dto.dart';
import 'package:pine/pine.dart';

class StudyCardMapper extends DTOMapper<CardDTO, StudyCard> {
  const StudyCardMapper();

  @override
  StudyCard fromDTO(CardDTO dto) => StudyCard(
    id: '${dto.id}',
    deckName: dto.deckName,
    noteTitle: dto.noteTitle,
    front: dto.front,
    back: dto.back,
    recentOutcomes: [for (final o in dto.recentOutcomes) outcomeFromWire(o)],
  );

  @override
  CardDTO toDTO(StudyCard model) => CardDTO(
    id: int.parse(model.id),
    deckSlug: '',
    deckName: model.deckName,
    noteTitle: model.noteTitle,
    kind: '',
    front: model.front,
    back: model.back,
    recentOutcomes: [for (final o in model.recentOutcomes) outcomeToWire(o)],
  );
}
