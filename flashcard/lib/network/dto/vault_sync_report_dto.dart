import 'package:pine/pine.dart';

class VaultSyncReportDTO extends DTO {
  final String branch;
  final String commit;
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

  const VaultSyncReportDTO({
    required this.branch,
    required this.commit,
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

  factory VaultSyncReportDTO.fromJson(Map<String, dynamic> json) =>
      VaultSyncReportDTO(
        branch: json['branch'] as String,
        commit: json['commit'] as String,
        notes: json['notes'] as int,
        cards: json['cards'] as int,
        created: json['created'] as int,
        updated: json['updated'] as int,
        archived: json['archived'] as int,
        restored: json['restored'] as int,
        problems: json['problems'] as int,
        embeddings: json['embeddings'] as int,
        embeddingsUpToDate: json['embeddings_up_to_date'] as int,
        embeddingError: json['embedding_error'] as String?,
      );

  Map<String, dynamic> toJson() => {
    'branch': branch,
    'commit': commit,
    'notes': notes,
    'cards': cards,
    'created': created,
    'updated': updated,
    'archived': archived,
    'restored': restored,
    'problems': problems,
    'embeddings': embeddings,
    'embeddings_up_to_date': embeddingsUpToDate,
    'embedding_error': embeddingError,
  };
}
