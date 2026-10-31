import 'package:flashcard/model/entities/session_draft.dart';
import 'package:flashcard/network/dto/session_request_dto.dart';
import 'package:pine/pine.dart';

class SessionDraftMapper extends DTOMapper<SessionRequestDTO, SessionDraft> {
  const SessionDraftMapper();

  @override
  SessionDraft fromDTO(SessionRequestDTO dto) => SessionDraft(
    id: dto.clientId,
    reviewIds: [for (final id in dto.reviewIds) '$id'],
    deckSlug: dto.deck,
    noteTitle: dto.note,
    temporaryDeckId: dto.temporaryDeck?.toString(),
  );

  @override
  SessionRequestDTO toDTO(SessionDraft model) => SessionRequestDTO(
    clientId: model.id,
    reviewIds: [for (final id in model.reviewIds) int.parse(id)],
    deck: model.deckSlug,
    note: model.noteTitle,
    temporaryDeck: switch (model.temporaryDeckId) {
      null => null,
      final id => int.parse(id),
    },
  );
}
