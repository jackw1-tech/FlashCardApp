import 'package:flashcard/theme/app_colors.dart';
import 'package:flashcard/theme/app_text_styles.dart';
import 'package:flashcard/theme/dimensions.dart';
import 'package:flashcard/ui/widgets/motion.dart';
import 'package:flutter/material.dart';

class DeckCard extends StatelessWidget {
  final String name;
  final int totalCards;
  final int unseenCards;
  final int subdeckCount;
  final VoidCallback onTap;

  final VoidCallback? onMore;

  final bool featured;

  const DeckCard({
    required this.name,
    required this.totalCards,
    required this.unseenCards,
    required this.onTap,
    this.subdeckCount = 0,
    this.onMore,
    this.featured = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final seen = totalCards - unseenCards;
    final progress = totalCards == 0 ? 0.0 : seen / totalCards;
    final foreground = featured ? colors.onPrimary : colors.ink;
    final secondary = featured
        ? colors.onPrimary.withValues(alpha: 0.8)
        : colors.muted;
    final radius = BorderRadius.circular(Dimensions.radiusLg);

    return Material(
      color: featured ? colors.primary : colors.card,
      borderRadius: radius,
      child: Pressable(
        borderRadius: radius,
        semanticLabel: '$name, $totalCards card, $unseenCards da scoprire',
        onTap: onTap,
        onLongPress: onMore,
        child: Padding(
          padding: EdgeInsets.all(
            featured ? Dimensions.spaceXl : Dimensions.paddingLarge,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style:
                          (featured
                                  ? AppTextStyles.displaySm
                                  : AppTextStyles.titleMd)
                              .copyWith(color: foreground),
                    ),
                  ),
                  if (onMore != null)
                    SizedBox.square(
                      dimension: 32,
                      child: IconButton(
                        tooltip: 'Opzioni del mazzo',
                        padding: EdgeInsets.zero,
                        icon: Icon(Icons.more_horiz_rounded, color: secondary),
                        onPressed: onMore,
                      ),
                    )
                  else
                    Icon(Icons.arrow_forward_rounded, color: secondary),
                ],
              ),
              const SizedBox(height: Dimensions.spaceXxs),
              Text(
                subdeckCount == 0
                    ? '$totalCards card'
                    : '$subdeckCount sottomazzi · $totalCards card',
                style: AppTextStyles.caption.copyWith(color: secondary),
              ),
              const SizedBox(height: Dimensions.paddingMedium),
              ClipRRect(
                borderRadius: BorderRadius.circular(Dimensions.radiusPill),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(end: progress),
                  duration: context.motionDuration(650),
                  curve: Curves.easeOutCubic,
                  builder: (_, value, _) => LinearProgressIndicator(
                    value: value,
                    minHeight: Dimensions.progressBarHeight,
                    color: featured ? colors.onPrimary : colors.knew,
                    backgroundColor: featured
                        ? colors.onPrimary.withValues(alpha: 0.25)
                        : colors.hairline,
                  ),
                ),
              ),
              const SizedBox(height: Dimensions.paddingSmall),
              Text(
                unseenCards == 0
                    ? 'Tutte viste almeno una volta'
                    : '${seen == 1 ? '1 vista' : '$seen viste'} · $unseenCards da scoprire',
                style: AppTextStyles.caption.copyWith(color: secondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
