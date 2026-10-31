import 'package:flashcard/model/base_model.dart';

enum ConversationStatus { idle, running, waitingConfirmation }

enum ChatItemKind { user, assistant, activity, deckCreated }

class ChatItem {
  final ChatItemKind kind;
  final String text;

  final String? temporaryDeckId;
  final int? total;

  const ChatItem({
    required this.kind,
    required this.text,
    this.temporaryDeckId,
    this.total,
  });
}

class PendingDeck {
  final String name;
  final int total;
  final List<({String note, int taken})> byNote;

  final List<String> adjustments;

  const PendingDeck({
    required this.name,
    required this.total,
    required this.byNote,
    required this.adjustments,
  });
}

class PendingConfirmation {
  final String action;
  final PendingDeck? deck;

  const PendingConfirmation({required this.action, this.deck});
}

class Conversation implements BaseModel {
  @override
  final String id;
  final String title;
  final ConversationStatus status;
  final List<ChatItem> items;
  final PendingConfirmation? pending;

  final String? error;

  const Conversation({
    required this.id,
    required this.title,
    required this.status,
    required this.items,
    this.pending,
    this.error,
  });

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'status': status.name,
    'items': items.length,
    'error': error,
  };

  @override
  Conversation copyWith({
    String? id,
    String? title,
    ConversationStatus? status,
    List<ChatItem>? items,
  }) => Conversation(
    id: id ?? this.id,
    title: title ?? this.title,
    status: status ?? this.status,
    items: items ?? this.items,
    pending: pending,
    error: error,
  );
}
