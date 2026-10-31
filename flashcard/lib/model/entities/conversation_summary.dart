import 'package:flashcard/model/base_model.dart';
import 'package:flashcard/model/entities/conversation.dart';

class ConversationSummary implements BaseModel {
  @override
  final String id;
  final String title;
  final ConversationStatus status;
  final DateTime updatedAt;

  const ConversationSummary({
    required this.id,
    required this.title,
    required this.status,
    required this.updatedAt,
  });

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'status': status.name,
    'updatedAt': updatedAt.toIso8601String(),
  };

  @override
  ConversationSummary copyWith({
    String? id,
    String? title,
    ConversationStatus? status,
    DateTime? updatedAt,
  }) => ConversationSummary(
    id: id ?? this.id,
    title: title ?? this.title,
    status: status ?? this.status,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}
