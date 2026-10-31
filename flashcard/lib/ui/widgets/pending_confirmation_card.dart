import 'package:flashcard/model/entities/conversation.dart';
import 'package:flashcard/theme/app_colors.dart';
import 'package:flashcard/theme/app_text_styles.dart';
import 'package:flashcard/theme/dimensions.dart';
import 'package:flutter/material.dart';

class PendingConfirmationCard extends StatelessWidget {
  final PendingConfirmation pending;
  final bool enabled;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const PendingConfirmationCard({
    required this.pending,
    required this.enabled,
    required this.onApprove,
    required this.onReject,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final deck = pending.deck;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Dimensions.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(pending.action, style: AppTextStyles.titleSm),
            if (deck != null) ...[
              const SizedBox(height: Dimensions.paddingSmall),
              Text(
                '${deck.name} · ${deck.total} card',
                style: AppTextStyles.bodyMd.copyWith(color: colors.ink),
              ),
              for (final row in deck.byNote)
                Text(
                  '${row.note}: ${row.taken}',
                  style: AppTextStyles.bodySm.copyWith(color: colors.body),
                ),
              for (final adjustment in deck.adjustments)
                Padding(
                  padding: const EdgeInsets.only(top: Dimensions.spaceXxs),
                  child: Text(
                    adjustment,
                    style: AppTextStyles.caption.copyWith(color: colors.muted),
                  ),
                ),
            ],
            const SizedBox(height: Dimensions.spaceSm),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: enabled ? onReject : null,
                  child: const Text('No, cambia'),
                ),
                const SizedBox(width: Dimensions.paddingSmall),
                FilledButton(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(88, 40),
                  ),
                  onPressed: enabled ? onApprove : null,
                  child: const Text('Crea il mazzo'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
