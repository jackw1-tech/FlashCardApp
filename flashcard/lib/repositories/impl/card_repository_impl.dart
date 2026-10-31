import 'package:flashcard/model/entities/card_report.dart';
import 'package:flashcard/model/entities/report_draft.dart';
import 'package:flashcard/model/entities/study_card.dart';
import 'package:flashcard/network/dto/card_dto.dart';
import 'package:flashcard/network/dto/card_report_dto.dart';
import 'package:flashcard/network/dto/report_request_dto.dart';
import 'package:flashcard/network/service/card_service.dart';
import 'package:flashcard/repositories/card_repository.dart';
import 'package:flashcard/repositories/impl/base_repository_impl.dart';
import 'package:pine/pine.dart';

class CardRepositoryImpl with BaseRepositoryImpl implements CardRepository {
  final CardService service;
  final DTOMapper<CardDTO, StudyCard> cardMapper;
  final DTOMapper<CardReportDTO, CardReport> reportMapper;
  final DTOMapper<ReportRequestDTO, ReportDraft> draftMapper;

  CardRepositoryImpl({
    required this.service,
    required this.cardMapper,
    required this.reportMapper,
    required this.draftMapper,
  });

  @override
  Future<List<StudyCard>> search(String query, {String? deckSlug}) =>
      guard(() async {
        final raw = await service.search(query: query, deckSlug: deckSlug);
        return cardMapper
            .fromDTOMany([
              for (final card in raw['results'] as List<dynamic>)
                CardDTO.fromJson(card as Map<String, dynamic>),
            ])
            .toList(growable: false);
      });

  @override
  Future<void> report(ReportDraft draft) => guard(
    () => service.reportCard(draft.cardId, draftMapper.toDTO(draft).toJson()),
  );

  @override
  Future<List<CardReport>> openReports() => guard(() async {
    final raw = await service.fetchOpenReports();
    return reportMapper
        .fromDTOMany([
          for (final report in raw['reports'] as List<dynamic>)
            CardReportDTO.fromJson(report as Map<String, dynamic>),
        ])
        .toList(growable: false);
  });

  @override
  Future<void> resolveReport(String reportId) =>
      guard(() => service.resolveReport(reportId));
}
