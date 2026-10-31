import 'package:flashcard/model/base_model.dart';

class VaultSyncReport implements BaseModel {
  @override
  final String id;
  final String branch;
  final int notes;
  final int cards;
  final int created;
  final int updated;
  final int archived;
  final int restored;
  final int problems;
  final int embeddings;
  final int embeddingsUpToDate;
  final String? embeddingError;

  const VaultSyncReport({
    required this.id,
    required this.branch,
    required this.notes,
    required this.cards,
    required this.created,
    required this.updated,
    required this.archived,
    required this.restored,
    required this.problems,
    required this.embeddings,
    required this.embeddingsUpToDate,
    this.embeddingError,
  });

  bool get isPartial => embeddingError != null;

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'branch': branch,
    'notes': notes,
    'cards': cards,
    'created': created,
    'updated': updated,
    'archived': archived,
    'restored': restored,
    'problems': problems,
    'embeddings': embeddings,
    'embeddingsUpToDate': embeddingsUpToDate,
    'embeddingError': embeddingError,
  };

  @override
  VaultSyncReport copyWith({String? id}) => VaultSyncReport(
    id: id ?? this.id,
    branch: branch,
    notes: notes,
    cards: cards,
    created: created,
    updated: updated,
    archived: archived,
    restored: restored,
    problems: problems,
    embeddings: embeddings,
    embeddingsUpToDate: embeddingsUpToDate,
    embeddingError: embeddingError,
  );
}
