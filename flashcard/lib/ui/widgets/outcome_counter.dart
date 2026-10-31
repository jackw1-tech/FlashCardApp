import 'package:flashcard/theme/app_text_styles.dart';
import 'package:flashcard/theme/dimensions.dart';
import 'package:flutter/material.dart';

class OutcomeCounter extends StatelessWidget {
  final int count;
  final String label;
  final Color color;

  final bool alignEnd;

  const OutcomeCounter({
    required this.count,
    required this.label,
    required this.color,
    this.alignEnd = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final pill = Container(
      constraints: const BoxConstraints(minWidth: 36),
      padding: const EdgeInsets.symmetric(
        horizontal: Dimensions.spaceSm,
        vertical: Dimensions.spaceXxs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(Dimensions.radiusPill),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: Dimensions.microAnimationMs),
        transitionBuilder: (child, animation) => ScaleTransition(
          scale: animation,
          child: FadeTransition(opacity: animation, child: child),
        ),
        child: Text(
          '$count',
          key: ValueKey(count),
          textAlign: TextAlign.center,
          style: AppTextStyles.caption.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
    final text = Text(
      label,
      style: AppTextStyles.caption.copyWith(color: color),
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: alignEnd
          ? [text, const SizedBox(width: Dimensions.paddingSmall), pill]
          : [pill, const SizedBox(width: Dimensions.paddingSmall), text],
    );
  }
}
