import 'package:flashcard/mappers/decks_overview_mapper.dart';
import 'package:flashcard/mappers/note_summary_mapper.dart';
import 'package:flashcard/mappers/vault_sync_report_mapper.dart';
import 'package:flashcard/model/app_failure.dart';
import 'package:flashcard/network/api_exception.dart';
import 'package:flashcard/network/service/deck_service.dart';
import 'package:flashcard/repositories/impl/deck_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_local_store.dart';

class FakeDeckService implements DeckService {
  ApiException? failure;

  @override
  Future<Map<String, dynamic>> fetchOverview() async {
    if (failure != null) throw failure!;
    return {
      'all': {'total_cards': 3, 'unseen_cards': 2},
      'decks': [
        {'slug': 'ddia', 'name': 'DDIA', 'total_cards': 3, 'unseen_cards': 2},
      ],
    };
  }

  @override
  Future<Map<String, dynamic>> fetchNotes(String slug) async => {
    'notes': [
      {'title': 'Liste', 'total_cards': 2, 'unseen_cards': 1},
    ],
  };

  @override
  Future<Map<String, dynamic>> renameDeck({
    required String slug,
    required String name,
  }) async => {'slug': slug, 'name': name.trim()};

  @override
  Future<Map<String, dynamic>> syncVault() async => {
    'branch': 'main',
    'commit': 'abc1234',
    'notes': 76,
    'cards': 2568,
    'created': 3,
    'updated': 2,
    'archived': 1,
    'restored': 4,
    'problems': 0,
    'embeddings': 5,
    'embeddings_up_to_date': 2563,
  };
}

void main() {
  late FakeDeckService service;
  late DeckRepositoryImpl repository;

  setUp(() {
    service = FakeDeckService();
    repository = DeckRepositoryImpl(
      service: service,
      mapper: const DecksOverviewMapper(),
      noteMapper: const NoteSummaryMapper(),
      vaultSyncMapper: const VaultSyncReportMapper(),
      store: FakeLocalStore(),
    );
  });

  test('la lista Mazzi esce come modello di dominio', () async {
    final overview = await repository.fetchOverview();

    expect(overview.totalCards, 3);
    expect(overview.decks.single.id, 'ddia');
  });

  test('le note escono come NoteSummary', () async {
    final notes = await repository.fetchNotes('ddia');

    expect(notes.single.title, 'Liste');
    expect(notes.single.unseenCards, 1);
  });

  test('la rinomina restituisce il nome salvato dal backend', () async {
    expect(await repository.renameDeck(slug: 'ddia', name: ' Nuovo '), 'Nuovo');
  });

  test('la sincronizzazione restituisce il report del Vault', () async {
    final report = await repository.syncVault();

    expect((report.id, report.notes, report.cards), ('abc1234', 76, 2568));
    expect((report.created, report.embeddingsUpToDate), (3, 2563));
  });

  test('gli errori di rete diventano AppFailure', () async {
    service.failure = const ApiException.network('giù');
    await expectLater(
      repository.fetchOverview(),
      throwsA(isA<NetworkFailure>()),
    );

    service.failure = const ApiException(401, 'no');
    await expectLater(
      repository.fetchOverview(),
      throwsA(isA<UnauthorizedFailure>()),
    );

    service.failure = const ApiException(500, 'boom');
    await expectLater(
      repository.fetchOverview(),
      throwsA(isA<ServerFailure>()),
    );
  });
}
