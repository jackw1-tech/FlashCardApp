import 'package:flashcard/model/entities/conversation.dart';
import 'package:flashcard/model/entities/conversation_summary.dart';
import 'package:flashcard/repositories/base_repository.dart';

abstract class ChatRepository extends BaseRepository<Conversation> {
  Future<List<ConversationSummary>> conversations();

  Future<Conversation> create();

  Future<Conversation> fetch(String id);

  Future<Conversation> send(String id, String text);

  Future<Conversation> confirm(String id, {required bool approve});

  Future<void> delete(String id);
}
