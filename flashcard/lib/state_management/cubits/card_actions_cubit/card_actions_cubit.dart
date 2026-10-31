import 'package:flashcard/model/app_failure.dart';
import 'package:flashcard/model/entities/report_draft.dart';
import 'package:flashcard/model/entities/report_reason.dart';
import 'package:flashcard/repositories/card_repository.dart';
import 'package:flashcard/repositories/obsidian_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'card_actions_cubit_state.dart';

class CardActionsCubit extends Cubit<CardActionsState> {
  final CardRepository cards;
  final ObsidianRepository obsidian;

  CardActionsCubit({required this.cards, required this.obsidian})
    : super(const CardActionsState());

  Future<void> report({
    required String cardId,
    required ReportReason reason,
    required String comment,
  }) async {
    try {
      await cards.report(
        ReportDraft.create(cardId: cardId, reason: reason, comment: comment),
      );
      _notify('Segnalazione salvata: la trovi in Impostazioni.');
    } on AppFailure catch (failure) {
      _notify('Segnalazione non salvata. ${failure.message}');
    }
  }

  Future<void> openInObsidian(String noteTitle) async {
    if (!await obsidian.openNote(noteTitle)) {
      _notify('Obsidian non è installato su questo dispositivo.');
    }
  }

  void _notify(String message) =>
      emit(CardActionsState(message: message, sequence: state.sequence + 1));
}
