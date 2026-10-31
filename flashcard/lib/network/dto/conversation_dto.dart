import 'package:pine/pine.dart';

class ConversationDTO extends DTO {
  final int id;
  final String title;
  final String status;
  final List<ChatItemDTO> items;
  final PendingDTO? pending;
  final String? error;

  const ConversationDTO({
    required this.id,
    required this.title,
    required this.status,
    required this.items,
    this.pending,
    this.error,
  });

  factory ConversationDTO.fromJson(Map<String, dynamic> json) =>
      ConversationDTO(
        id: json['id'] as int,
        title: json['title'] as String,
        status: json['status'] as String,
        items: [
          for (final item in json['items'] as List)
            ChatItemDTO.fromJson(item as Map<String, dynamic>),
        ],
        pending: json['pending'] == null
            ? null
            : PendingDTO.fromJson(json['pending'] as Map<String, dynamic>),
        error: json['error'] as String?,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'status': status,
    'items': [for (final item in items) item.toJson()],
    'pending': pending?.toJson(),
    'error': error,
  };
}

class ChatItemDTO extends DTO {
  final String kind;
  final String text;
  final int? temporaryDeckId;
  final int? total;

  const ChatItemDTO({
    required this.kind,
    required this.text,
    this.temporaryDeckId,
    this.total,
  });

  factory ChatItemDTO.fromJson(Map<String, dynamic> json) => ChatItemDTO(
    kind: json['kind'] as String,
    text: json['text'] as String,
    temporaryDeckId: json['temporary_deck_id'] as int?,
    total: json['total'] as int?,
  );

  Map<String, dynamic> toJson() => {
    'kind': kind,
    'text': text,
    'temporary_deck_id': ?temporaryDeckId,
    'total': ?total,
  };
}

class PendingDTO extends DTO {
  final String action;
  final PendingDeckDTO? deck;

  const PendingDTO({required this.action, this.deck});

  factory PendingDTO.fromJson(Map<String, dynamic> json) => PendingDTO(
    action: json['action'] as String,
    deck: json['deck'] == null
        ? null
        : PendingDeckDTO.fromJson(json['deck'] as Map<String, dynamic>),
  );

  Map<String, dynamic> toJson() => {'action': action, 'deck': deck?.toJson()};
}

class PendingDeckDTO extends DTO {
  final String name;
  final int total;
  final List<({String note, int taken})> byNote;
  final List<String> adjustments;

  const PendingDeckDTO({
    required this.name,
    required this.total,
    required this.byNote,
    required this.adjustments,
  });

  factory PendingDeckDTO.fromJson(Map<String, dynamic> json) => PendingDeckDTO(
    name: json['name'] as String,
    total: json['total'] as int,
    byNote: [
      for (final row in json['by_note'] as List)
        (
          note:
              (row as Map<String, dynamic>)['note'] as String? ??
              'Tutte le note',
          taken: row['taken'] as int,
        ),
    ],
    adjustments: [for (final a in json['adjustments'] as List) a as String],
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'total': total,
    'by_note': [
      for (final row in byNote) {'note': row.note, 'taken': row.taken},
    ],
    'adjustments': adjustments,
  };
}
