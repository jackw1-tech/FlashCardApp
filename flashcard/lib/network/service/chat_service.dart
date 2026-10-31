import 'package:flashcard/network/service/base_service.dart';

abstract class ChatService extends BaseService {
  Future<Map<String, dynamic>> fetchConversations();

  Future<Map<String, dynamic>> createConversation();

  Future<Map<String, dynamic>> fetchConversation(String id);

  Future<Map<String, dynamic>> sendMessage(String id, String text);

  Future<Map<String, dynamic>> confirm(String id, {required bool approve});

  Future<void> deleteConversation(String id);
}
