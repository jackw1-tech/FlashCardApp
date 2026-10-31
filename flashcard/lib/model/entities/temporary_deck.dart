import 'package:flashcard/model/base_model.dart';

class TemporaryDeck implements BaseModel {
  @override
  final String id;
  final String name;
  final DateTime createdAt;
  final DateTime expiresAt;
  final int total;

  final int done;

  final int missed;

  const TemporaryDeck({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.expiresAt,
    required this.total,
    required this.done,
    required this.missed,
  });

  int get remaining => total - done;

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'createdAt': createdAt.toIso8601String(),
    'expiresAt': expiresAt.toIso8601String(),
    'total': total,
    'done': done,
    'missed': missed,
  };

  @override
  TemporaryDeck copyWith({String? id, String? name, int? done, int? missed}) =>
      TemporaryDeck(
        id: id ?? this.id,
        name: name ?? this.name,
        createdAt: createdAt,
        expiresAt: expiresAt,
        total: total,
        done: done ?? this.done,
        missed: missed ?? this.missed,
      );
}
