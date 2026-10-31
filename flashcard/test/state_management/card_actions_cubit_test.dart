import 'package:flashcard/model/app_failure.dart';
import 'package:flashcard/model/entities/card_report.dart';
import 'package:flashcard/model/entities/report_draft.dart';
import 'package:flashcard/model/entities/report_reason.dart';
import 'package:flashcard/model/entities/study_card.dart';
import 'package:flashcard/repositories/card_repository.dart';
import 'package:flashcard/repositories/obsidian_repository.dart';
import 'package:flashcard/state_management/cubits/card_actions_cubit/card_actions_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeCardRepository implements CardRepository {
  ReportDraft? reported;
  bool fail = false;

  @override
  Future<void> report(ReportDraft draft) async {
    if (fail) throw const NetworkFailure();
    reported = draft;
  }

  @override
  Future<List<StudyCard>> search(String query, {String? deckSlug}) async =>
      const [];

  @override
  Future<List<CardReport>> openReports() async => const [];

  @override
  Future<void> resolveReport(String reportId) async {}
}

class FakeObsidianRepository implements ObsidianRepository {
  bool installed = true;

  @override
  Future<bool> openNote(String noteTitle) async => installed;
}

void main() {
  late FakeCardRepository cards;
  late FakeObsidianRepository obsidian;
  late CardActionsCubit cubit;

  setUp(() {
    cards = FakeCardRepository();
    obsidian = FakeObsidianRepository();
    cubit = CardActionsCubit(cards: cards, obsidian: obsidian);
  });

  test(
    'la segnalazione costruisce la bozza e la passa al Repository',
    () async {
      await cubit.report(
        cardId: '1',
        reason: ReportReason.other,
        comment: 'ciao',
      );

      expect(cards.reported!.cardId, '1');
      expect(cards.reported!.reason, ReportReason.other);
      expect(cubit.state.message, contains('Segnalazione salvata'));
      expect(cubit.state.sequence, 1);
    },
  );

  test('una segnalazione fallita diventa un messaggio', () async {
    cards.fail = true;

    await cubit.report(cardId: '1', reason: ReportReason.other, comment: '');

    expect(cubit.state.message, contains('non salvata'));
  });

  test('Obsidian non installato produce un messaggio', () async {
    obsidian.installed = false;

    await cubit.openInObsidian('Liste');

    expect(cubit.state.message, contains('Obsidian'));
  });
}
