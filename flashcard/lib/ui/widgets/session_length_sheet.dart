import 'package:auto_route/auto_route.dart';
import 'package:flashcard/other/constants/app_constants.dart';
import 'package:flashcard/routers/app_router.dart';
import 'package:flashcard/theme/app_colors.dart';
import 'package:flashcard/theme/app_text_styles.dart';
import 'package:flashcard/theme/dimensions.dart';
import 'package:flashcard/ui/widgets/motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SessionLengthSheet extends StatelessWidget {
  final String deckName;
  final int totalCards;

  const SessionLengthSheet({
    required this.deckName,
    required this.totalCards,
    super.key,
  });

  static Future<int?> show(
    BuildContext context, {
    required String deckName,
    required int totalCards,
  }) => showModalBottomSheet<int>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) =>
        SessionLengthSheet(deckName: deckName, totalCards: totalCards),
  );

  static Future<void> startSession(
    BuildContext context, {
    required String deckName,
    required int totalCards,
    String? deckSlug,
    String? noteTitle,
  }) async {
    final length = totalCards <= AppConstants.sessionLengthOptions.first
        ? totalCards
        : await show(
            context,
            deckName: noteTitle ?? deckName,
            totalCards: totalCards,
          );
    if (length == null || !context.mounted) return;
    HapticFeedback.selectionClick();
    await context.router.push(
      StudyRoute(
        deckSlug: deckSlug,
        deckName: deckName,
        noteTitle: noteTitle,
        sessionLength: length,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final options = AppConstants.sessionLengthOptions.where(
      (n) => n < totalCards,
    );
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          Dimensions.paddingLarge,
          0,
          Dimensions.paddingLarge,
          Dimensions.paddingLarge,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Quante card?',
              style: AppTextStyles.displaySm.copyWith(color: colors.ink),
            ),
            const SizedBox(height: Dimensions.spaceXxs),
            Text(
              '$deckName · $totalCards card',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption.copyWith(color: colors.muted),
            ),
            const SizedBox(height: Dimensions.paddingLarge),
            for (final length in options) ...[
              _Option(
                label: '$length card',
                highlighted: length == AppConstants.sessionLength,
                onTap: () => Navigator.of(context).pop(length),
              ),
              const SizedBox(height: Dimensions.paddingSmall),
            ],
            _Option(
              label: 'Tutte',
              detail: '$totalCards card',
              onTap: () => Navigator.of(context).pop(totalCards),
            ),
          ],
        ),
      ),
    );
  }
}

class _Option extends StatelessWidget {
  final String label;
  final String? detail;
  final bool highlighted;
  final VoidCallback onTap;

  const _Option({
    required this.label,
    required this.onTap,
    this.detail,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final radius = BorderRadius.circular(Dimensions.radiusLg);
    return Material(
      color: colors.card,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: highlighted
            ? BorderSide(color: colors.primary, width: 1.5)
            : BorderSide.none,
      ),
      child: Pressable(
        borderRadius: radius,
        onTap: onTap,
        semanticLabel: detail == null ? label : '$label, $detail',
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Dimensions.paddingLarge - 4,
            vertical: Dimensions.paddingMedium,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.titleSm.copyWith(color: colors.ink),
                ),
              ),
              if (detail != null) ...[
                Text(
                  detail!,
                  style: AppTextStyles.caption.copyWith(color: colors.muted),
                ),
                const SizedBox(width: Dimensions.paddingSmall),
              ],
              if (highlighted) ...[
                Text(
                  'consigliato',
                  style: AppTextStyles.caption.copyWith(color: colors.primary),
                ),
                const SizedBox(width: Dimensions.paddingSmall),
              ],
              Icon(Icons.arrow_forward_rounded, size: 20, color: colors.muted),
            ],
          ),
        ),
      ),
    );
  }
}
