part of 'conversations_cubit.dart';

sealed class ConversationsState {
  const ConversationsState();
}

class LoadingConversationsState extends ConversationsState {
  const LoadingConversationsState();
}

class LoadedConversationsState extends ConversationsState {
  final List<ConversationSummary> conversations;

  const LoadedConversationsState(this.conversations);
}

class ErrorConversationsState extends ConversationsState {
  final String message;

  const ErrorConversationsState(this.message);
}
