import 'package:flashcard/mappers/card_report_mapper.dart';
import 'package:flashcard/mappers/report_draft_mapper.dart';
import 'package:flashcard/mappers/study_card_mapper.dart';
import 'package:flashcard/model/entities/report_draft.dart';
import 'package:flashcard/model/entities/report_reason.dart';
import 'package:flashcard/network/service/card_service.dart';
import 'package:flashcard/repositories/impl/card_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

const _card = {
  'id': 1,
  'deck': {'slug': 'scala', 'name': 'Scala'},
  'note_title': 'Liste',
  'kind': 'basic',
  'front': 'Q',
  'back': 'A',
};

class FakeCardService implements CardService {
  String? reportedCardId;
  Map<String, dynamic>? reportedBody;
  String? resolved;

  @override
  Future<Map<String, dynamic>> search({
    required String query,
    String? deckSlug,
  }) async => {
    'results': [_card],
  };

  @override
  Future<Map<String, dynamic>> reportCard(
    String cardId,
    Map<String, dynamic> body,
  ) async {
    reportedCardId = cardId;
    reportedBody = body;
    return {};
  }

  @override
  Future<Map<String, dynamic>> fetchOpenReports() async => {
    'reports': [
      {
        'id': 9,
        'reason': 'bad_format',
        'comment': 'x',
        'created_at': '2026-01-01T10:00:00Z',
        'card': _card,
      },
    ],
  };

  @override
  Future<Map<String, dynamic>> resolveReport(String reportId) async {
    resolved = reportId;
    return {};
  }
}

void main() {
  late FakeCardService service;
  late CardRepositoryImpl repository;

  setUp(() {
    service = FakeCardService();
    repository = CardRepositoryImpl(
      service: service,
      cardMapper: const StudyCardMapper(),
      reportMapper: const CardReportMapper(),
      draftMapper: const ReportDraftMapper(),
    );
  });

  test('la ricerca restituisce StudyCard', () async {
    final cards = await repository.search('li');

    expect(cards.single.id, '1');
  });

  test('la segnalazione parte con il corpo dell\'API', () async {
    await repository.report(
      ReportDraft.create(
        cardId: '1',
        reason: ReportReason.badFormat,
        comment: '  ciao ',
      ),
    );

    expect(service.reportedCardId, '1');
    expect(service.reportedBody, {'reason': 'bad_format', 'comment': 'ciao'});
  });

  test(
    'le segnalazioni aperte escono come CardReport e si risolvono',
    () async {
      final reports = await repository.openReports();
      await repository.resolveReport('9');

      expect(reports.single.id, '9');
      expect(reports.single.reason, ReportReason.badFormat);
      expect(service.resolved, '9');
    },
  );
}
