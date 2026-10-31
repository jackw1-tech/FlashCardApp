import 'package:auto_route/auto_route.dart';
import 'package:flashcard/model/entities/study_stats.dart';
import 'package:flashcard/state_management/cubits/settings_cubit/settings_cubit.dart';
import 'package:flashcard/state_management/cubits/stats_cubit/stats_cubit.dart';
import 'package:flashcard/theme/app_colors.dart';
import 'package:flashcard/theme/app_text_styles.dart';
import 'package:flashcard/theme/dimensions.dart';
import 'package:flashcard/ui/widgets/daily_goal_card.dart';
import 'package:flashcard/ui/widgets/error_view.dart';
import 'package:flashcard/ui/widgets/loading_skeleton.dart';
import 'package:flashcard/ui/widgets/motion.dart';
import 'package:flashcard/ui/widgets/content_width.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

@RoutePage()
class StatsPage extends StatelessWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Statistiche')),
    body: ContentWidth(
      maxWidth: Dimensions.readingMaxWidth,
      child: BlocBuilder<StatsCubit, StatsState>(
        builder: (context, state) => switch (state) {
          FetchingStatsState() => const LoadingSkeleton(rows: 5),
          ErrorStatsState(:final message) => ErrorView(
            message: message,
            onRetry: () => context.read<StatsCubit>().fetch(),
          ),
          FetchedStatsState(:final stats) => RefreshIndicator(
            onRefresh: () => context.read<StatsCubit>().fetch(),
            child: ListView(
              padding: const EdgeInsets.all(Dimensions.paddingMedium),
              children: [
                DailyGoalCard(
                  todayReviews: stats.todayReviews,
                  goal: context.select<SettingsCubit, int>(
                    (s) => s.state.dailyGoal,
                  ),
                  streakDays: stats.streakDays,
                ),
                const SizedBox(height: Dimensions.paddingLarge),
                Text(
                  'PER MAZZO',
                  style: AppTextStyles.captionUppercase.copyWith(
                    color: context.colors.muted,
                  ),
                ),
                const SizedBox(height: Dimensions.paddingSmall),
                for (final deck in stats.decks) ...[
                  FadeSlideIn(
                    key: ValueKey(deck.id),
                    child: _DeckStatsRow(deck),
                  ),
                  const SizedBox(height: Dimensions.paddingSmall),
                ],
              ],
            ),
          ),
        },
      ),
    ),
  );
}

class _DeckStatsRow extends StatelessWidget {
  final DeckStats deck;

  const _DeckStatsRow(this.deck);

  String _lastStudied() {
    final last = deck.lastStudiedAt;
    if (last == null) return 'Mai studiato';
    final days = DateTime.now().difference(last).inDays;
    if (days == 0) return 'Oggi, ${DateFormat.Hm().format(last)}';
    if (days == 1) return 'Ieri';
    return '$days giorni fa';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final ratio = deck.knewRatio;
    return Container(
      padding: const EdgeInsets.all(Dimensions.paddingMedium + 4),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(Dimensions.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  deck.name,
                  style: AppTextStyles.titleSm.copyWith(color: colors.ink),
                ),
              ),
              Text(
                ratio == null ? '—' : '${(ratio * 100).round()}% sapevo',
                style: AppTextStyles.caption.copyWith(
                  color: ratio == null ? colors.muted : colors.knew,
                ),
              ),
            ],
          ),
          const SizedBox(height: Dimensions.paddingSmall),
          ClipRRect(
            borderRadius: BorderRadius.circular(Dimensions.radiusPill),
            child: LinearProgressIndicator(
              value: ratio ?? 0,
              minHeight: Dimensions.progressBarHeight,
              color: colors.knew,
              backgroundColor: ratio == null
                  ? colors.hairline
                  : colors.didntKnow.withValues(alpha: 0.35),
            ),
          ),
          const SizedBox(height: Dimensions.paddingSmall),
          Text(
            '${deck.reviews == 1 ? '1 risposta' : '${deck.reviews} risposte'} · ${_lastStudied()}',
            style: AppTextStyles.caption.copyWith(color: colors.muted),
          ),
        ],
      ),
    );
  }
}
