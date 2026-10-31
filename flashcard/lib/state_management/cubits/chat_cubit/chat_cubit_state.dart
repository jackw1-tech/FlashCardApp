part of 'chat_cubit.dart';

sealed class ChatState {
  const ChatState();
}

class LoadingChatState extends ChatState {
  const LoadingChatState();
}

class ShowingChatState extends ChatState {
  final Conversation conversation;

  final bool working;

  final String? notice;

  const ShowingChatState(
    this.conversation, {
    this.working = false,
    this.notice,
  });
}

class ErrorChatState extends ChatState {
  final String message;

  const ErrorChatState(this.message);
}
