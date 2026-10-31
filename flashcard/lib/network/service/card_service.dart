import 'package:flashcard/network/service/base_service.dart';

abstract class CardService extends BaseService {
  Future<Map<String, dynamic>> search({
    required String query,
    String? deckSlug,
  });

  Future<Map<String, dynamic>> reportCard(
    String cardId,
    Map<String, dynamic> body,
  );

  Future<Map<String, dynamic>> fetchOpenReports();

  Future<Map<String, dynamic>> resolveReport(String reportId);
}
