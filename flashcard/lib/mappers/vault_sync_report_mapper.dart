import 'package:flashcard/model/entities/vault_sync_report.dart';
import 'package:flashcard/network/dto/vault_sync_report_dto.dart';
import 'package:pine/pine.dart';

class VaultSyncReportMapper
    extends DTOMapper<VaultSyncReportDTO, VaultSyncReport> {
  const VaultSyncReportMapper();

  @override
  VaultSyncReport fromDTO(VaultSyncReportDTO dto) => VaultSyncReport(
    id: dto.commit,
    branch: dto.branch,
    notes: dto.notes,
    cards: dto.cards,
    created: dto.created,
    updated: dto.updated,
    archived: dto.archived,
    restored: dto.restored,
    problems: dto.problems,
    embeddings: dto.embeddings,
    embeddingsUpToDate: dto.embeddingsUpToDate,
    embeddingError: dto.embeddingError,
  );

  @override
  VaultSyncReportDTO toDTO(VaultSyncReport model) => VaultSyncReportDTO(
    branch: model.branch,
    commit: model.id,
    notes: model.notes,
    cards: model.cards,
    created: model.created,
    updated: model.updated,
    archived: model.archived,
    restored: model.restored,
    problems: model.problems,
    embeddings: model.embeddings,
    embeddingsUpToDate: model.embeddingsUpToDate,
    embeddingError: model.embeddingError,
  );
}
