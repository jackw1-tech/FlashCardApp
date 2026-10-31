import 'package:flashcard/model/base_model.dart';
import 'package:uuid/uuid.dart';

class SessionDraft implements BaseModel {
  @override
  final String id;

  final List<String> reviewIds;
  final String? deckSlug;
  final String? noteTitle;
  final String? temporaryDeckId;

  const SessionDraft({
    required this.id,
    required this.reviewIds,
    this.deckSlug,
    this.noteTitle,
    this.temporaryDeckId,
  });

  SessionDraft.create({
    required this.reviewIds,
    this.deckSlug,
    this.noteTitle,
    this.temporaryDeckId,
  }) : id = const Uuid().v4();

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'reviewIds': reviewIds,
    'deckSlug': deckSlug,
    'noteTitle': noteTitle,
    'temporaryDeckId': temporaryDeckId,
  };

  @override
  SessionDraft copyWith({String? id}) => SessionDraft(
    id: id ?? this.id,
    reviewIds: reviewIds,
    deckSlug: deckSlug,
    noteTitle: noteTitle,
    temporaryDeckId: temporaryDeckId,
  );
}
