import 'package:flashcard/model/base_model.dart';

class SavedSession implements BaseModel {
  @override
  final String id;
  final DateTime startedAt;
  final DateTime endedAt;
  final int knew;
  final int didntKnow;
  final String? deckName;
  final String? noteTitle;
  final String? temporaryDeckName;

  const SavedSession({
    required this.id,
    required this.startedAt,
    required this.endedAt,
    required this.knew,
    required this.didntKnow,
    this.deckName,
    this.noteTitle,
    this.temporaryDeckName,
  });

  int get total => knew + didntKnow;

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'startedAt': startedAt.toIso8601String(),
    'endedAt': endedAt.toIso8601String(),
    'knew': knew,
    'didntKnow': didntKnow,
    'deckName': deckName,
    'noteTitle': noteTitle,
    'temporaryDeckName': temporaryDeckName,
  };

  @override
  SavedSession copyWith({String? id}) => SavedSession(
    id: id ?? this.id,
    startedAt: startedAt,
    endedAt: endedAt,
    knew: knew,
    didntKnow: didntKnow,
    deckName: deckName,
    noteTitle: noteTitle,
    temporaryDeckName: temporaryDeckName,
  );
}
