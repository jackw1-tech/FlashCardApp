import 'package:flashcard/model/entities/deck_summary.dart';
import 'package:flashcard/model/entities/decks_overview.dart';
import 'package:flashcard/model/entities/note_summary.dart';
import 'package:flashcard/model/entities/vault_sync_report.dart';
import 'package:flashcard/repositories/base_repository.dart';

abstract class DeckRepository extends BaseRepository<DeckSummary> {
  DecksOverview? cachedOverview();

  Future<DecksOverview> fetchOverview();

  Future<List<NoteSummary>> fetchNotes(String slug);

  Future<String> renameDeck({required String slug, required String name});

  Future<VaultSyncReport> syncVault();
}
