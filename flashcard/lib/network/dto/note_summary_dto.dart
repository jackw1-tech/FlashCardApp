import 'package:pine/pine.dart';

class NoteSummaryDTO extends DTO {
  final String title;
  final int totalCards;
  final int unseenCards;

  const NoteSummaryDTO({
    required this.title,
    required this.totalCards,
    required this.unseenCards,
  });

  factory NoteSummaryDTO.fromJson(Map<String, dynamic> json) => NoteSummaryDTO(
    title: json['title'] as String,
    totalCards: json['total_cards'] as int,
    unseenCards: json['unseen_cards'] as int,
  );

  Map<String, dynamic> toJson() => {
    'title': title,
    'total_cards': totalCards,
    'unseen_cards': unseenCards,
  };
}
