import 'package:flashcard/model/entities/study_card.dart';
import 'package:flashcard/state_management/cubits/card_actions_cubit/card_actions_cubit.dart';
import 'package:flashcard/ui/widgets/report_card_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum _CardAction { report, obsidian }

class CardActionsMenu extends StatelessWidget {
  final StudyCard card;

  const CardActionsMenu({required this.card, super.key});

  Future<void> _onSelected(BuildContext context, _CardAction action) async {
    final actions = context.read<CardActionsCubit>();
    switch (action) {
      case _CardAction.report:
        final report = await ReportCardSheet.show(
          context,
          cardId: card.id,
          front: card.front,
        );
        if (report != null) {
          await actions.report(
            cardId: card.id,
            reason: report.reason,
            comment: report.comment,
          );
        }
      case _CardAction.obsidian:
        await actions.openInObsidian(card.noteTitle);
    }
  }

  @override
  Widget build(BuildContext context) => PopupMenuButton<_CardAction>(
    tooltip: 'Azioni sulla card',
    icon: const Icon(Icons.more_horiz_rounded),
    onSelected: (action) => _onSelected(context, action),
    itemBuilder: (_) => const [
      PopupMenuItem(
        value: _CardAction.report,
        child: ListTile(
          leading: Icon(Icons.flag_outlined),
          title: Text('Segnala la card'),
        ),
      ),
      PopupMenuItem(
        value: _CardAction.obsidian,
        child: ListTile(
          leading: Icon(Icons.open_in_new_rounded),
          title: Text('Apri la nota in Obsidian'),
        ),
      ),
    ],
  );
}
