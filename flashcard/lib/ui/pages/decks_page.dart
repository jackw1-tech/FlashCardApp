import 'dart:math' as math;

import 'package:auto_route/auto_route.dart';
import 'package:flashcard/model/entities/deck_summary.dart';
import 'package:flashcard/model/entities/decks_overview.dart';
import 'package:flashcard/model/entities/temporary_deck.dart';
import 'package:flashcard/routers/app_router.dart';
import 'package:flashcard/state_management/cubits/decks_cubit/decks_cubit.dart';
import 'package:flashcard/state_management/cubits/settings_cubit/settings_cubit.dart';
import 'package:flashcard/state_management/cubits/stats_cubit/stats_cubit.dart';
import 'package:flashcard/state_management/cubits/temporary_decks_cubit/temporary_decks_cubit.dart';
import 'package:flashcard/theme/dimensions.dart';
import 'package:flashcard/ui/widgets/daily_goal_card.dart';
import 'package:flashcard/ui/widgets/deck_card.dart';
import 'package:flashcard/ui/widgets/error_view.dart';
import 'package:flashcard/ui/widgets/loading_skeleton.dart';
import 'package:flashcard/ui/widgets/motion.dart';
import 'package:flashcard/ui/widgets/rename_deck_dialog.dart';
import 'package:flashcard/ui/widgets/session_length_sheet.dart';
import 'package:flashcard/ui/widgets/temporary_deck_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

@RoutePage()
class DecksPage extends StatelessWidget {
  const DecksPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: BlocConsumer<DecksCubit, DecksState>(
      listenWhen: (_, state) =>
          state is FetchedDecksState && state.notice != null,
      listener: (context, state) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text((state as FetchedDecksState).notice!)),
      ),
      builder: (context, state) => switch (state) {
        FetchingDecksState() => const LoadingSkeleton(rows: 5),
        ErrorDecksState(:final message) => SafeArea(
          child: ErrorView(
            message: message,
            onRetry: () => context.read<DecksCubit>().fetch(),
          ),
        ),
        FetchedDecksState(:final overview) => _DeckList(overview),
      },
    ),
  );
}

class _DeckList extends StatelessWidget {
  final DecksOverview overview;

  const _DeckList(this.overview);

  Future<void> _studyDeck(BuildContext context, DeckSummary deck) async {
    void choose(BuildContext sheetContext, DeckSummary selected) {
      HapticFeedback.selectionClick();
      Navigator.pop(sheetContext, selected);
    }

    final selected = deck.hasSubdecks
        ? await showModalBottomSheet<DeckSummary>(
            context: context,
            showDragHandle: true,
            builder: (sheetContext) => SafeArea(
              child: ListView(
                shrinkWrap: true,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      Dimensions.paddingLarge,
                      Dimensions.paddingSmall,
                      Dimensions.paddingLarge,
                      Dimensions.paddingMedium,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          deck.name,
                          style: Theme.of(sheetContext)
                              .textTheme
                              .headlineMedium,
                        ),
                        const SizedBox(height: Dimensions.spaceXxs),
                        Text(
                          'Scegli cosa ripassare · ${deck.totalCards} card',
                          style: Theme.of(sheetContext).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.select_all_rounded),
                    ),
                    title: Text('Tutto ${deck.name}'),
                    subtitle: Text(
                      '${deck.totalCards - deck.unseenCards} viste · ${deck.unseenCards} da scoprire',
                    ),
                    trailing: const Icon(Icons.arrow_forward_rounded),
                    onTap: () => choose(sheetContext, deck),
                  ),
                  const Divider(indent: 72),
                  for (final subdeck in deck.subdecks)
                    ListTile(
                      leading: const Icon(Icons.subdirectory_arrow_right),
                      title: Text(subdeck.name),
                      subtitle: Text(
                        '${subdeck.totalCards} card · ${subdeck.unseenCards} nuove',
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => choose(sheetContext, subdeck),
                    ),
                ],
              ),
            ),
          )
        : deck;
    if (selected == null || !context.mounted) return;
    await SessionLengthSheet.startSession(
      context,
      deckSlug: selected.id,
      deckName: selected.name,
      totalCards: selected.totalCards,
    );
  }

  Future<void> _showDeckActions(BuildContext context, DeckSummary deck) async {
    final action = await showModalBottomSheet<_DeckAction>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(
                deck.name,
                style: Theme.of(sheetContext).textTheme.titleMedium,
              ),
              subtitle: Text('Tag flashcards/${deck.id}'),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.topic_outlined),
              title: const Text('Studia un argomento'),
              onTap: () => Navigator.of(sheetContext).pop(_DeckAction.notes),
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Rinomina mazzo'),
              onTap: () => Navigator.of(sheetContext).pop(_DeckAction.rename),
            ),
          ],
        ),
      ),
    );
    if (action == null || !context.mounted) return;
    if (action == _DeckAction.notes) {
      await context.router.push(
        NotesRoute(deckSlug: deck.id, deckName: deck.name),
      );
      return;
    }
    final name = await RenameDeckDialog.show(context, deck.name);
    if (name != null && context.mounted) {
      await context.read<DecksCubit>().rename(deck.id, name);
    }
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final theme = Theme.of(context);
      final width = constraints.maxWidth;
      final side = math.max(
        Dimensions.paddingMedium,
        (width - Dimensions.contentMaxWidth) / 2,
      );
      EdgeInsets pad(double top, double bottom) =>
          EdgeInsets.fromLTRB(side, top, side, bottom);

      final studyAll = DeckCard(
        name: 'Studia tutto',
        totalCards: overview.totalCards,
        unseenCards: overview.unseenCards,
        featured: true,
        onTap: () => SessionLengthSheet.startSession(
          context,
          deckName: 'Tutti i mazzi',
          totalCards: overview.totalCards,
        ),
      );
      Widget deckCard(DeckSummary deck) => DeckCard(
        name: deck.name,
        totalCards: deck.totalCards,
        unseenCards: deck.unseenCards,
        subdeckCount: deck.subdecks.length,
        onTap: () => _studyDeck(context, deck),
        onMore: () => _showDeckActions(context, deck),
      );

      return RefreshIndicator(
        onRefresh: () async {
          context.read<StatsCubit>().fetch();
          context.read<TemporaryDecksCubit>().fetch();
          await context.read<DecksCubit>().fetch();
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverSafeArea(
              bottom: false,
              sliver: SliverPadding(
                padding: pad(Dimensions.paddingLarge, Dimensions.paddingLarge),
                sliver: SliverToBoxAdapter(child: _Header(overview)),
              ),
            ),
            if (overview.decks.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Text('Nessun mazzo: lancia import_vault sul backend.'),
                ),
              )
            else ...[
              SliverPadding(
                padding: pad(0, Dimensions.paddingLarge),
                sliver: SliverToBoxAdapter(
                  child: width >= Dimensions.wideBreakpoint
                      ? IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Expanded(child: _DailyGoal()),
                              const SizedBox(width: Dimensions.paddingMedium),
                              Expanded(child: studyAll),
                            ],
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const _DailyGoal(
                              bottomGap: Dimensions.paddingLarge,
                            ),
                            studyAll,
                          ],
                        ),
                ),
              ),
              _TemporaryDecksSection(pad: pad),
              SliverPadding(
                padding: pad(0, Dimensions.spaceSm),
                sliver: SliverToBoxAdapter(
                  child: Text('MAZZI', style: theme.textTheme.labelSmall),
                ),
              ),
              SliverPadding(
                padding: pad(0, Dimensions.paddingLarge),
                sliver: width >= Dimensions.gridBreakpoint
                    ? SliverGrid.builder(
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: Dimensions.deckGridCellWidth,
                              mainAxisExtent: Dimensions.deckGridCellHeight,
                              crossAxisSpacing: Dimensions.spaceSm,
                              mainAxisSpacing: Dimensions.spaceSm,
                            ),
                        itemCount: overview.decks.length,
                        itemBuilder: (_, index) => FadeSlideIn(
                          key: ValueKey(overview.decks[index].id),
                          child: deckCard(overview.decks[index]),
                        ),
                      )
                    : SliverList.separated(
                        itemCount: overview.decks.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: Dimensions.spaceSm),
                        itemBuilder: (_, index) => FadeSlideIn(
                          key: ValueKey(overview.decks[index].id),
                          child: deckCard(overview.decks[index]),
                        ),
                      ),
              ),
            ],
          ],
        ),
      );
    },
  );
}

class _Header extends StatelessWidget {
  final DecksOverview overview;

  const _Header(this.overview);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final leafDecks = overview.decks.fold<int>(
      0,
      (total, deck) => total + (deck.hasSubdecks ? deck.subdecks.length : 1),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text('I tuoi mazzi', style: theme.textTheme.displaySmall),
            ),
            IconButton(
              tooltip: 'Chat di ripasso',
              icon: const Icon(Icons.chat_bubble_outline_rounded),
              onPressed: () async {
                await context.router.push(const ConversationsRoute());
                if (context.mounted) {
                  await context.read<TemporaryDecksCubit>().fetch();
                }
              },
            ),
            IconButton(
              tooltip: 'Cerca',
              icon: const Icon(Icons.search_rounded),
              onPressed: () => context.router.push(const SearchRoute()),
            ),
            IconButton(
              tooltip: 'Statistiche',
              icon: const Icon(Icons.insights_rounded),
              onPressed: () => context.router.push(const StatsRoute()),
            ),
            IconButton(
              tooltip: 'Impostazioni',
              icon: const Icon(Icons.tune_rounded),
              onPressed: () => context.router.push(const SettingsRoute()),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '${overview.totalCards} card · ${overview.decks.length} mazzi · $leafDecks sottomazzi',
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _TemporaryDecksSection extends StatelessWidget {
  final EdgeInsets Function(double top, double bottom) pad;

  const _TemporaryDecksSection({required this.pad});

  Future<void> _study(BuildContext context, TemporaryDeck deck) async {
    await context.router.push(
      StudyRoute(
        deckName: deck.name,
        sessionLength: deck.remaining,
        temporaryDeckId: deck.id,
      ),
    );
    if (context.mounted) await context.read<TemporaryDecksCubit>().fetch();
  }

  @override
  Widget build(BuildContext context) =>
      BlocConsumer<TemporaryDecksCubit, TemporaryDecksState>(
        listenWhen: (_, state) =>
            state is FetchedTemporaryDecksState && state.notice != null,
        listener: (context, state) => ScaffoldMessenger.of(context)
            .showSnackBar(
              SnackBar(
                content: Text((state as FetchedTemporaryDecksState).notice!),
              ),
            ),
        builder: (context, state) {
          final decks = switch (state) {
            FetchedTemporaryDecksState(:final decks) => decks,
            _ => const <TemporaryDeck>[],
          };
          if (decks.isEmpty) return const SliverToBoxAdapter();
          return SliverPadding(
            padding: pad(0, Dimensions.paddingLarge),
            sliver: SliverList.list(
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: Dimensions.spaceSm),
                  child: Text(
                    'MAZZI PROVVISORI',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
                for (final deck in decks)
                  Padding(
                    padding: const EdgeInsets.only(bottom: Dimensions.spaceSm),
                    child: TemporaryDeckTile(
                      deck: deck,
                      onStudy: deck.remaining == 0
                          ? null
                          : () => _study(context, deck),
                      onDelete: () =>
                          context.read<TemporaryDecksCubit>().delete(deck.id),
                    ),
                  ),
              ],
            ),
          );
        },
      );
}

enum _DeckAction { notes, rename }

class _DailyGoal extends StatelessWidget {
  final double bottomGap;

  const _DailyGoal({this.bottomGap = 0});

  @override
  Widget build(BuildContext context) => BlocBuilder<StatsCubit, StatsState>(
    builder: (context, state) => switch (state) {
      FetchedStatsState(:final stats) => Padding(
        padding: EdgeInsets.only(bottom: bottomGap),
        child: DailyGoalCard(
          todayReviews: stats.todayReviews,
          goal: context.select<SettingsCubit, int>((s) => s.state.dailyGoal),
          streakDays: stats.streakDays,
          onTap: () => context.router.push(const StatsRoute()),
        ),
      ),
      _ => const SizedBox.shrink(),
    },
  );
}
