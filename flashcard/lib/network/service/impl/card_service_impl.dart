import 'package:flashcard/network/service/card_service.dart';
import 'package:flashcard/network/service/impl/base_service_impl.dart';
import 'package:flashcard/other/constants/api_constants.dart';

class CardServiceImpl extends BaseServiceImpl implements CardService {
  CardServiceImpl({required super.client, required super.baseUrl});

  @override
  Future<Map<String, dynamic>> search({
    required String query,
    String? deckSlug,
  }) =>
      getJson(ApiConstants.searchPath, query: {'q': query, 'deck': ?deckSlug});

  @override
  Future<Map<String, dynamic>> reportCard(
    String cardId,
    Map<String, dynamic> body,
  ) => postJson(ApiConstants.cardReportsPath(cardId), body);

  @override
  Future<Map<String, dynamic>> fetchOpenReports() =>
      getJson(ApiConstants.reportsPath);

  @override
  Future<Map<String, dynamic>> resolveReport(String reportId) =>
      postJson(ApiConstants.resolveReportPath(reportId), const {});
}
