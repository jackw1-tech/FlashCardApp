import 'package:pine/pine.dart';

class ConversationSummaryDTO extends DTO {
  final int id;
  final String title;
  final String status;
  final String updatedAt;

  const ConversationSummaryDTO({
    required this.id,
    required this.title,
    required this.status,
    required this.updatedAt,
  });

  factory ConversationSummaryDTO.fromJson(Map<String, dynamic> json) =>
      ConversationSummaryDTO(
        id: json['id'] as int,
        title: json['title'] as String,
        status: json['status'] as String,
        updatedAt: json['updated_at'] as String,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'status': status,
    'updated_at': updatedAt,
  };
}
