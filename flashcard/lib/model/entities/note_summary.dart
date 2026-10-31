import 'package:flashcard/model/base_model.dart';

class NoteSummary implements BaseModel {
  @override
  final String id;
  final int totalCards;
  final int unseenCards;

  const NoteSummary({
    required this.id,
    required this.totalCards,
    required this.unseenCards,
  });

  String get title => id;

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'totalCards': totalCards,
    'unseenCards': unseenCards,
  };

  @override
  NoteSummary copyWith({String? id, int? totalCards, int? unseenCards}) =>
      NoteSummary(
        id: id ?? this.id,
        totalCards: totalCards ?? this.totalCards,
        unseenCards: unseenCards ?? this.unseenCards,
      );
}
