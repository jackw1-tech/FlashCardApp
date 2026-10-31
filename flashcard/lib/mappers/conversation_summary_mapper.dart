import 'package:flashcard/mappers/conversation_wire.dart';
import 'package:flashcard/model/entities/conversation_summary.dart';
import 'package:flashcard/network/dto/conversation_summary_dto.dart';
import 'package:pine/pine.dart';

class ConversationSummaryMapper
    extends DTOMapper<ConversationSummaryDTO, ConversationSummary> {
  const ConversationSummaryMapper();

  @override
  ConversationSummary fromDTO(ConversationSummaryDTO dto) =>
      ConversationSummary(
        id: '${dto.id}',
        title: dto.title,
        status: statusFromWire(dto.status),
        updatedAt: DateTime.parse(dto.updatedAt),
      );

  @override
  ConversationSummaryDTO toDTO(ConversationSummary model) =>
      ConversationSummaryDTO(
        id: int.parse(model.id),
        title: model.title,
        status: statusToWire(model.status),
        updatedAt: model.updatedAt.toIso8601String(),
      );
}
