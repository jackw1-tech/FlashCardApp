import 'package:flashcard/mappers/report_reason_wire.dart';
import 'package:flashcard/model/entities/report_draft.dart';
import 'package:flashcard/network/dto/report_request_dto.dart';
import 'package:pine/pine.dart';

class ReportDraftMapper extends DTOMapper<ReportRequestDTO, ReportDraft> {
  const ReportDraftMapper();

  @override
  ReportDraft fromDTO(ReportRequestDTO dto) => ReportDraft.create(
    cardId: '',
    reason: reasonFromWire(dto.reason),
    comment: dto.comment,
  );

  @override
  ReportRequestDTO toDTO(ReportDraft model) => ReportRequestDTO(
    reason: reasonToWire(model.reason),
    comment: model.comment.trim(),
  );
}
