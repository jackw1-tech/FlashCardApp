import 'package:flashcard/mappers/conversation_wire.dart';
import 'package:flashcard/model/entities/conversation.dart';
import 'package:flashcard/network/dto/conversation_dto.dart';
import 'package:pine/pine.dart';

class ConversationMapper extends DTOMapper<ConversationDTO, Conversation> {
  const ConversationMapper();

  @override
  Conversation fromDTO(ConversationDTO dto) => Conversation(
    id: '${dto.id}',
    title: dto.title,
    status: statusFromWire(dto.status),
    items: [
      for (final item in dto.items)
        ChatItem(
          kind: kindFromWire(item.kind),
          text: item.text,
          temporaryDeckId: item.temporaryDeckId?.toString(),
          total: item.total,
        ),
    ],
    pending: switch (dto.pending) {
      null => null,
      final pending => PendingConfirmation(
        action: pending.action,
        deck: switch (pending.deck) {
          null => null,
          final deck => PendingDeck(
            name: deck.name,
            total: deck.total,
            byNote: deck.byNote,
            adjustments: deck.adjustments,
          ),
        },
      ),
    },
    error: dto.error,
  );

  @override
  ConversationDTO toDTO(Conversation model) => ConversationDTO(
    id: int.parse(model.id),
    title: model.title,
    status: statusToWire(model.status),
    items: [
      for (final item in model.items)
        ChatItemDTO(
          kind: kindToWire(item.kind),
          text: item.text,
          temporaryDeckId: switch (item.temporaryDeckId) {
            null => null,
            final id => int.parse(id),
          },
          total: item.total,
        ),
    ],
    pending: switch (model.pending) {
      null => null,
      final pending => PendingDTO(
        action: pending.action,
        deck: switch (pending.deck) {
          null => null,
          final deck => PendingDeckDTO(
            name: deck.name,
            total: deck.total,
            byNote: deck.byNote,
            adjustments: deck.adjustments,
          ),
        },
      ),
    },
    error: model.error,
  );
}
