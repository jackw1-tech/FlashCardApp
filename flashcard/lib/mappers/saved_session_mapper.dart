import 'package:flashcard/model/entities/saved_session.dart';
import 'package:flashcard/network/dto/saved_session_dto.dart';
import 'package:pine/pine.dart';

class SavedSessionMapper extends DTOMapper<SavedSessionDTO, SavedSession> {
  const SavedSessionMapper();

  @override
  SavedSession fromDTO(SavedSessionDTO dto) => SavedSession(
    id: '${dto.id}',
    startedAt: DateTime.parse(dto.startedAt),
    endedAt: DateTime.parse(dto.endedAt),
    knew: dto.knew,
    didntKnow: dto.didntKnow,
    deckName: dto.deckName,
    noteTitle: dto.noteTitle,
    temporaryDeckName: dto.temporaryDeckName,
  );

  @override
  SavedSessionDTO toDTO(SavedSession model) => SavedSessionDTO(
    id: int.parse(model.id),
    startedAt: model.startedAt.toIso8601String(),
    endedAt: model.endedAt.toIso8601String(),
    knew: model.knew,
    didntKnow: model.didntKnow,
    deckName: model.deckName,
    noteTitle: model.noteTitle,
    temporaryDeckName: model.temporaryDeckName,
  );
}
