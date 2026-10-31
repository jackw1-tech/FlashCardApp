import 'package:flashcard/mappers/report_reason_wire.dart';
import 'package:flashcard/mappers/study_card_mapper.dart';
import 'package:flashcard/model/entities/card_report.dart';
import 'package:flashcard/network/dto/card_report_dto.dart';
import 'package:pine/pine.dart';

class CardReportMapper extends DTOMapper<CardReportDTO, CardReport> {
  final StudyCardMapper cardMapper;

  const CardReportMapper({this.cardMapper = const StudyCardMapper()});

  @override
  CardReport fromDTO(CardReportDTO dto) => CardReport(
    id: '${dto.id}',
    reason: reasonFromWire(dto.reason),
    comment: dto.comment,
    createdAt: DateTime.parse(dto.createdAt).toLocal(),
    card: cardMapper.fromDTO(dto.card),
  );

  @override
  CardReportDTO toDTO(CardReport model) => CardReportDTO(
    id: int.parse(model.id),
    reason: reasonToWire(model.reason),
    comment: model.comment,
    createdAt: model.createdAt.toUtc().toIso8601String(),
    card: cardMapper.toDTO(model.card),
  );
}
