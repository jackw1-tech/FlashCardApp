import 'package:flashcard/model/entities/card_report.dart';
import 'package:flashcard/model/entities/report_draft.dart';
import 'package:flashcard/model/entities/study_card.dart';
import 'package:flashcard/repositories/base_repository.dart';

abstract class CardRepository extends BaseRepository<StudyCard> {
  Future<List<StudyCard>> search(String query, {String? deckSlug});

  Future<void> report(ReportDraft draft);

  Future<List<CardReport>> openReports();

  Future<void> resolveReport(String reportId);
}
