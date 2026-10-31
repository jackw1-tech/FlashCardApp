import 'package:flashcard/theme/app_colors.dart';
import 'package:flashcard/theme/app_text_styles.dart';
import 'package:flashcard/theme/dimensions.dart';
import 'package:flashcard/ui/widgets/motion.dart';
import 'package:flutter/material.dart';

class DailyGoalCard extends StatelessWidget {
  final int todayReviews;
  final int goal;
  final int streakDays;
  final VoidCallback? onTap;

  const DailyGoalCard({
    required this.todayReviews,
    required this.goal,
    required this.streakDays,
    this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final progress = goal == 0 ? 1.0 : (todayReviews / goal).clamp(0.0, 1.0);
    final reached = todayReviews >= goal;
    final radius = BorderRadius.circular(Dimensions.radiusLg);
    return Material(
      color: colors.card,
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(Dimensions.paddingLarge - 4),
          child: Row(
            children: [
              SizedBox.square(
                dimension: 56,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: progress),
                      duration: context.motionDuration(700),
                      curve: Curves.easeOutCubic,
                      builder: (_, value, _) => CircularProgressIndicator(
                        value: value,
                        strokeWidth: 6,
                        strokeCap: StrokeCap.round,
                        color: reached ? colors.knew : colors.primary,
                        backgroundColor: colors.hairline,
                      ),
                    ),
                    Center(
                      child: AnimatedSwitcher(
                        duration: context.motionDuration(
                          Dimensions.microAnimationMs,
                        ),
                        child: reached
                            ? Icon(
                                Icons.check_rounded,
                                key: const ValueKey('done'),
                                color: colors.knew,
                              )
                            : Text(
                                '${(progress * 100).round()}%',
                                key: const ValueKey('progress'),
                                style: AppTextStyles.caption.copyWith(
                                  color: colors.ink,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: Dimensions.paddingMedium),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reached ? 'Obiettivo raggiunto' : 'Obiettivo di oggi',
                      style: AppTextStyles.captionUppercase.copyWith(
                        color: colors.muted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$todayReviews / $goal card',
                      style: AppTextStyles.titleMd.copyWith(color: colors.ink),
                    ),
                  ],
                ),
              ),
              if (streakDays > 0) ...[
                Icon(
                  Icons.local_fire_department_rounded,
                  color: colors.primary,
                  size: 20,
                ),
                const SizedBox(width: 2),
                Text(
                  streakDays == 1 ? '1 giorno' : '$streakDays giorni',
                  style: AppTextStyles.caption.copyWith(color: colors.ink),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
