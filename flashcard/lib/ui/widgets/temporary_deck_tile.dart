import 'package:flashcard/model/entities/temporary_deck.dart';
import 'package:flashcard/theme/app_colors.dart';
import 'package:flashcard/utils/date_time_utils.dart';
import 'package:flutter/material.dart';

class TemporaryDeckTile extends StatelessWidget {
  final TemporaryDeck deck;

  final VoidCallback? onStudy;
  final VoidCallback onDelete;

  const TemporaryDeckTile({
    required this.deck,
    required this.onStudy,
    required this.onDelete,
    super.key,
  });

  String get _progress {
    final expires = DateTimeUtils.formatTime(deck.expiresAt.toLocal());
    final status = deck.remaining == 0
        ? 'completato'
        : '${deck.done}/${deck.total} fatte';
    final missed = deck.missed > 0 ? ' · ${deck.missed} sbagliate' : '';
    return '$status$missed · scade alle $expires';
  }

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      onTap: onStudy,
      leading: Icon(
        deck.remaining == 0 ? Icons.check_circle_rounded : Icons.style_rounded,
        color: deck.remaining == 0 ? context.colors.knew : null,
      ),
      title: Text(deck.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_progress),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: deck.total == 0 ? 0 : deck.done / deck.total,
          ),
        ],
      ),
      trailing: PopupMenuButton<void>(
        tooltip: 'Altro',
        itemBuilder: (_) => [
          PopupMenuItem(onTap: onDelete, child: const Text('Elimina')),
        ],
      ),
    ),
  );
}
