import 'package:flashcard/model/entities/conversation.dart';

ConversationStatus statusFromWire(String value) => switch (value) {
  'running' => ConversationStatus.running,
  'waiting_confirmation' => ConversationStatus.waitingConfirmation,
  _ => ConversationStatus.idle,
};

String statusToWire(ConversationStatus status) => switch (status) {
  ConversationStatus.idle => 'idle',
  ConversationStatus.running => 'running',
  ConversationStatus.waitingConfirmation => 'waiting_confirmation',
};

ChatItemKind kindFromWire(String value) => switch (value) {
  'user' => ChatItemKind.user,
  'deck_created' => ChatItemKind.deckCreated,
  'activity' => ChatItemKind.activity,
  _ => ChatItemKind.assistant,
};

String kindToWire(ChatItemKind kind) => switch (kind) {
  ChatItemKind.user => 'user',
  ChatItemKind.assistant => 'assistant',
  ChatItemKind.activity => 'activity',
  ChatItemKind.deckCreated => 'deck_created',
};
