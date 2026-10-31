import 'package:flashcard/model/app_failure.dart';
import 'package:flashcard/model/entities/deck_summary.dart';
import 'package:flashcard/model/entities/decks_overview.dart';
import 'package:flashcard/model/entities/note_summary.dart';
import 'package:flashcard/model/entities/vault_sync_report.dart';
import 'package:flashcard/repositories/deck_repository.dart';
import 'package:flashcard/state_management/cubits/decks_cubit/decks_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

const overview = DecksOverview(
  totalCards: 3,
  unseenCards: 3,
  decks: [
    DeckSummary(id: 'ddia', name: 'ddia', totalCards: 2, unseenCards: 2),
    DeckSummary(id: 'scala', name: 'scala', totalCards: 1, unseenCards: 1),
  ],
);

class FakeDeckRepository implements DeckRepository {
  int fetches = 0;
  bool failRename = false;

  @override
  Future<DecksOverview> fetchOverview() async {
    fetches++;
    if (failFetch) throw const NetworkFailure();
    return overview;
  }

  DecksOverview? cached;
  bool failFetch = false;

  @override
  DecksOverview? cachedOverview() => cached;

  @override
  Future<List<NoteSummary>> fetchNotes(String slug) async => const [];

  @override
  Future<String> renameDeck({
    required String slug,
    required String name,
  }) async {
    if (failRename) throw const NetworkFailure();
    return name.trim();
  }

  @override
  Future<VaultSyncReport> syncVault() => throw UnimplementedError();
}

void main() {
  late FakeDeckRepository repository;
  late DecksCubit cubit;

  setUp(() async {
    repository = FakeDeckRepository();
    cubit = DecksCubit(repository: repository);
    await cubit.fetch();
  });

  tearDown(() => cubit.close());

  test(
    'la rinomina aggiorna solo quel mazzo senza ricaricare la lista',
    () async {
      await cubit.rename('ddia', ' Designing Data-Intensive Applications ');

      final state = cubit.state as FetchedDecksState;
      expect(state.overview.decks.map((d) => d.name), [
        'Designing Data-Intensive Applications',
        'scala',
      ]);
      expect(state.notice, isNull);
      expect(repository.fetches, 1);
    },
  );

  test(
    'se la rinomina fallisce la lista resta com\'era con un avviso',
    () async {
      repository.failRename = true;

      await cubit.rename('ddia', 'DDIA');

      final state = cubit.state as FetchedDecksState;
      expect(state.overview.decks.first.name, 'ddia');
      expect(state.notice, contains('Nome non salvato'));
    },
  );

  group('stale-while-revalidate', () {
    late FakeDeckRepository repo;
    late DecksCubit fresh;

    setUp(() {
      repo = FakeDeckRepository()
        ..cached = const DecksOverview(
          totalCards: 1,
          unseenCards: 1,
          decks: [],
        );
      fresh = DecksCubit(repository: repo);
    });

    tearDown(() => fresh.close());

    test('mostra subito la copia locale e poi quella del server', () async {
      final states = <DecksState>[];
      final subscription = fresh.stream.listen(states.add);

      await fresh.fetch();
      await Future<void>.delayed(Duration.zero);
      await subscription.cancel();

      final first = states.first as FetchedDecksState;
      final last = states.last as FetchedDecksState;
      expect((first.overview.totalCards, first.refreshing), (1, true));
      expect((last.overview.totalCards, last.refreshing), (3, false));
    });

    test('senza rete resta la copia locale con un avviso', () async {
      repo.failFetch = true;

      await fresh.fetch();

      final state = fresh.state as FetchedDecksState;
      expect(state.overview.totalCards, 1);
      expect(state.notice, contains('Dati non aggiornati'));
    });

    test('senza copia locale e senza rete mostra l\'errore', () async {
      repo
        ..cached = null
        ..failFetch = true;

      await fresh.fetch();

      expect(fresh.state, isA<ErrorDecksState>());
    });
  });
}
