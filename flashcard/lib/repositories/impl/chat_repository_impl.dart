import 'package:flashcard/model/entities/conversation.dart';
import 'package:flashcard/model/entities/conversation_summary.dart';
import 'package:flashcard/network/dto/conversation_dto.dart';
import 'package:flashcard/network/dto/conversation_summary_dto.dart';
import 'package:flashcard/network/service/chat_service.dart';
import 'package:flashcard/repositories/chat_repository.dart';
import 'package:flashcard/repositories/impl/base_repository_impl.dart';
import 'package:pine/pine.dart';

class ChatRepositoryImpl with BaseRepositoryImpl implements ChatRepository {
  final ChatService service;
  final DTOMapper<ConversationDTO, Conversation> mapper;
  final DTOMapper<ConversationSummaryDTO, ConversationSummary> summaryMapper;

  ChatRepositoryImpl({
    required this.service,
    required this.mapper,
    required this.summaryMapper,
  });

  @override
  Future<List<ConversationSummary>> conversations() => guard(() async {
    final raw = await service.fetchConversations();
    return [
      for (final row in raw['conversations'] as List)
        summaryMapper.fromDTO(
          ConversationSummaryDTO.fromJson(row as Map<String, dynamic>),
        ),
    ];
  });

  @override
  Future<Conversation> create() =>
      guard(() async => _map(await service.createConversation()));

  @override
  Future<Conversation> fetch(String id) =>
      guard(() async => _map(await service.fetchConversation(id)));

  @override
  Future<Conversation> send(String id, String text) =>
      guard(() async => _map(await service.sendMessage(id, text)));

  @override
  Future<Conversation> confirm(String id, {required bool approve}) =>
      guard(() async => _map(await service.confirm(id, approve: approve)));

  @override
  Future<void> delete(String id) => guard(() => service.deleteConversation(id));

  Conversation _map(Map<String, dynamic> raw) =>
      mapper.fromDTO(ConversationDTO.fromJson(raw));
}
