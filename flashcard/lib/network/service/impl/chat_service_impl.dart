import 'package:flashcard/network/service/chat_service.dart';
import 'package:flashcard/network/service/impl/base_service_impl.dart';
import 'package:flashcard/other/constants/api_constants.dart';
import 'package:flashcard/other/constants/app_constants.dart';

class ChatServiceImpl extends BaseServiceImpl implements ChatService {
  ChatServiceImpl({required super.client, required super.baseUrl});

  @override
  Future<Map<String, dynamic>> fetchConversations() =>
      getJson(ApiConstants.conversationsPath);

  @override
  Future<Map<String, dynamic>> createConversation() =>
      postJson(ApiConstants.conversationsPath, const {});

  @override
  Future<Map<String, dynamic>> fetchConversation(String id) =>
      getJson(ApiConstants.conversationPath(id));

  @override
  Future<Map<String, dynamic>> sendMessage(String id, String text) => postJson(
    ApiConstants.conversationMessagesPath(id),
    {'text': text},
    timeout: AppConstants.chatTurnTimeout,
  );

  @override
  Future<Map<String, dynamic>> confirm(String id, {required bool approve}) =>
      postJson(ApiConstants.conversationConfirmationPath(id), {
        'approve': approve,
      }, timeout: AppConstants.chatTurnTimeout);

  @override
  Future<void> deleteConversation(String id) =>
      delete(ApiConstants.conversationPath(id));
}
