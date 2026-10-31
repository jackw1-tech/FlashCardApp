import 'package:flashcard/network/service/deck_service.dart';
import 'package:flashcard/network/service/impl/base_service_impl.dart';
import 'package:flashcard/other/constants/api_constants.dart';

class DeckServiceImpl extends BaseServiceImpl implements DeckService {
  DeckServiceImpl({
    required super.client,
    required super.baseUrl,
    super.prefetch,
  });

  @override
  Future<Map<String, dynamic>> fetchOverview() =>
      getJsonPrefetched('decks', ApiConstants.decksPath);

  @override
  Future<Map<String, dynamic>> fetchNotes(String slug) =>
      getJson(ApiConstants.deckNotesPath(slug));

  @override
  Future<Map<String, dynamic>> renameDeck({
    required String slug,
    required String name,
  }) => patchJson(ApiConstants.deckPath(slug), {'name': name});

  @override
  Future<Map<String, dynamic>> syncVault() => postJson(
    ApiConstants.vaultSyncPath,
    const {},
    timeout: const Duration(minutes: 30),
  );
}
