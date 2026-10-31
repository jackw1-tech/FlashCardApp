import 'package:flashcard/model/base_model.dart';

class DeckSummary implements BaseModel {
  @override
  final String id;
  final String name;
  final int totalCards;
  final int unseenCards;
  final List<DeckSummary> subdecks;

  const DeckSummary({
    required this.id,
    required this.name,
    required this.totalCards,
    required this.unseenCards,
    this.subdecks = const [],
  });

  bool get hasSubdecks => subdecks.isNotEmpty;

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'totalCards': totalCards,
    'unseenCards': unseenCards,
    'subdecks': [for (final deck in subdecks) deck.toJson()],
  };

  @override
  DeckSummary copyWith({
    String? id,
    String? name,
    int? totalCards,
    int? unseenCards,
    List<DeckSummary>? subdecks,
  }) => DeckSummary(
    id: id ?? this.id,
    name: name ?? this.name,
    totalCards: totalCards ?? this.totalCards,
    unseenCards: unseenCards ?? this.unseenCards,
    subdecks: subdecks ?? this.subdecks,
  );
}
