import 'dart:async';

import 'package:flashcard/model/entities/card_report.dart';
import 'package:flashcard/model/entities/report_draft.dart';
import 'package:flashcard/model/entities/study_card.dart';
import 'package:flashcard/repositories/card_repository.dart';
import 'package:flashcard/state_management/cubits/search_cubit/search_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

StudyCard card(String id) =>
    StudyCard(id: id, deckName: 'D', noteTitle: 'N', front: id, back: id);

class FakeCardRepository implements CardRepository {
  final Map<String, Completer<List<StudyCard>>> pending = {};

  @override
  Future<List<StudyCard>> search(String query, {String? deckSlug}) =>
      (pending[query] = Completer<List<StudyCard>>()).future;

  @override
  Future<void> report(ReportDraft draft) async {}

  @override
  Future<List<CardReport>> openReports() async => const [];

  @override
  Future<void> resolveReport(String reportId) async {}
}

void main() {
  late FakeCardRepository repository;
  late SearchCubit cubit;

  setUp(() {
    repository = FakeCardRepository();
    cubit = SearchCubit(
      repository: repository,
      debounce: const Duration(milliseconds: 10),
    );
  });

  tearDown(() => cubit.close());

  test(
    'aspetta che si smetta di scrivere e cerca solo l\'ultima query',
    () async {
      cubit.queryChanged('le');
      cubit.queryChanged('lea');
      cubit.queryChanged('leader');
      await Future<void>.delayed(const Duration(milliseconds: 30));

      expect(repository.pending.keys, ['leader']);
    },
  );

  test('sotto le 2 lettere non cerca', () async {
    cubit.queryChanged('l');
    await Future<void>.delayed(const Duration(milliseconds: 30));

    expect(repository.pending, isEmpty);
    expect(cubit.state, isA<IdleSearchState>());
  });

  test(
    'una risposta arrivata in ritardo non sovrascrive quella della query nuova',
    () async {
      cubit.queryChanged('leader');
      await Future<void>.delayed(const Duration(milliseconds: 30));
      cubit.queryChanged('follower');
      await Future<void>.delayed(const Duration(milliseconds: 30));

      repository.pending['follower']!.complete([card('f')]);
      await Future<void>.delayed(Duration.zero);
      repository.pending['leader']!.complete([card('l')]);
      await Future<void>.delayed(Duration.zero);

      final state = cubit.state as ResultsSearchState;
      expect((state.query, state.results.single.id), ('follower', 'f'));
    },
  );
}
