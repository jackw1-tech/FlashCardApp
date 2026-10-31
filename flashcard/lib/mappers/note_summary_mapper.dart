import 'package:flashcard/model/entities/note_summary.dart';
import 'package:flashcard/network/dto/note_summary_dto.dart';
import 'package:pine/pine.dart';

class NoteSummaryMapper extends DTOMapper<NoteSummaryDTO, NoteSummary> {
  const NoteSummaryMapper();

  @override
  NoteSummary fromDTO(NoteSummaryDTO dto) => NoteSummary(
    id: dto.title,
    totalCards: dto.totalCards,
    unseenCards: dto.unseenCards,
  );

  @override
  NoteSummaryDTO toDTO(NoteSummary model) => NoteSummaryDTO(
    title: model.id,
    totalCards: model.totalCards,
    unseenCards: model.unseenCards,
  );
}
