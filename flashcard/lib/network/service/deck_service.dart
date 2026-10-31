import 'package:flashcard/network/service/base_service.dart';

abstract class DeckService extends BaseService {
  Future<Map<String, dynamic>> fetchOverview();

  Future<Map<String, dynamic>> fetchNotes(String slug);

  Future<Map<String, dynamic>> renameDeck({
    required String slug,
    required String name,
  });

  Future<Map<String, dynamic>> syncVault();
}
