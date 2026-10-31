import 'package:flashcard/model/app_failure.dart';
import 'package:flashcard/model/entities/decks_overview.dart';
import 'package:flashcard/model/entities/note_summary.dart';
import 'package:flashcard/model/entities/vault_sync_report.dart';
import 'package:flashcard/repositories/deck_repository.dart';
import 'package:flashcard/state_management/cubits/vault_sync_cubit/vault_sync_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeDeckRepository implements DeckRepository {
  AppFailure? failure;
  VaultSyncReport report = const VaultSyncReport(
    id: 'abc1234',
    branch: 'main',
    notes: 76,
    cards: 2568,
    created: 0,
    updated: 0,
    archived: 0,
    restored: 0,
    problems: 0,
    embeddings: 0,
    embeddingsUpToDate: 2568,
  );

  @override
  Future<VaultSyncReport> syncVault() async {
    if (failure case final error?) throw error;
    return report;
  }

  @override
  DecksOverview? cachedOverview() => throw UnimplementedError();
  @override
  Future<DecksOverview> fetchOverview() => throw UnimplementedError();
  @override
  Future<List<NoteSummary>> fetchNotes(String slug) =>
      throw UnimplementedError();
  @override
  Future<String> renameDeck({required String slug, required String name}) =>
      throw UnimplementedError();
}

void main() {
  late FakeDeckRepository repository;
  late VaultSyncCubit cubit;

  setUp(() {
    repository = FakeDeckRepository();
    cubit = VaultSyncCubit(repository: repository);
  });

  tearDown(() => cubit.close());

  test('espone il report completo', () async {
    await cubit.sync();

    final state = cubit.state as CompletedVaultSyncState;
    expect((state.report.notes, state.report.cards), (76, 2568));
  });

  test('mantiene il report parziale come successo leggibile', () async {
    repository.report = VaultSyncReport(
      id: 'abc1234',
      branch: 'main',
      notes: 76,
      cards: 2568,
      created: 1,
      updated: 0,
      archived: 0,
      restored: 0,
      problems: 0,
      embeddings: 0,
      embeddingsUpToDate: 2000,
      embeddingError: 'Voyage non risponde',
    );

    await cubit.sync();

    final state = cubit.state as CompletedVaultSyncState;
    expect(state.report.isPartial, isTrue);
    expect(state.report.created, 1);
  });

  test('espone gli errori che impediscono anche l’import', () async {
    repository.failure = const NetworkFailure();

    await cubit.sync();

    expect(cubit.state, isA<ErrorVaultSyncState>());
  });
}
