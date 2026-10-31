import 'package:auto_route/auto_route.dart';
import 'package:flashcard/model/entities/session_summary.dart';
import 'package:flashcard/model/entities/session_draft.dart';
import 'package:flashcard/repositories/study_repository.dart';
import 'package:flashcard/routers/app_router.dart';
import 'package:flashcard/state_management/cubits/decks_cubit/decks_cubit.dart';
import 'package:flashcard/state_management/cubits/stats_cubit/stats_cubit.dart';
import 'package:flashcard/state_management/cubits/session_save_cubit/session_save_cubit.dart';
import 'package:flashcard/state_management/cubits/temporary_decks_cubit/temporary_decks_cubit.dart';
import 'package:flashcard/theme/app_colors.dart';
import 'package:flashcard/theme/dimensions.dart';
import 'package:flashcard/ui/widgets/content_width.dart';
import 'package:flashcard/ui/widgets/motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

@RoutePage()
class SessionSummaryPage extends StatelessWidget {
  final String? deckSlug;

  final String? noteTitle;

  final String? temporaryDeckId;
  final String deckName;
  final SessionSummary summary;

  final int sessionLength;

  const SessionSummaryPage({
    required this.deckName,
    required this.summary,
    required this.sessionLength,
    this.deckSlug,
    this.noteTitle,
    this.temporaryDeckId,
    super.key,
  });

  void _refreshCounters(BuildContext context) {
    context.read<DecksCubit>().fetch();
    context.read<StatsCubit>().fetch();
    context.read<TemporaryDecksCubit>().fetch();
  }

  void _backToDecks(BuildContext context) {
    _refreshCounters(context);
    context.router.popUntilRoot();
  }

  void _studyAgain(BuildContext context) {
    _refreshCounters(context);
    context.router.replace(
      StudyRoute(
        deckSlug: deckSlug,
        deckName: deckName,
        noteTitle: noteTitle,
        temporaryDeckId: temporaryDeckId,
        sessionLength: sessionLength,
      ),
    );
  }

  void _reviewMissed(BuildContext context) {
    _refreshCounters(context);
    context.router.replace(
      StudyRoute(
        deckSlug: deckSlug,
        deckName: deckName,
        noteTitle: noteTitle,
        temporaryDeckId: temporaryDeckId,
        sessionLength: sessionLength,
        fixedCards: summary.missed,
      ),
    );
  }

  String get _headline {
    if (summary.total == 0) return 'Sessione chiusa';
    final ratio = summary.knew / summary.total;
    if (ratio >= 0.8) return 'Ottimo lavoro!';
    if (ratio >= 0.5) return 'Stai andando bene';
    return 'Continua a ripassare';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ratio = summary.total == 0 ? 0.0 : summary.knew / summary.total;

    return BlocProvider(
      create: (_) => SessionSaveCubit(
        repository: context.read<StudyRepository>(),
        draft: SessionDraft.create(
          reviewIds: summary.reviewIds,
          deckSlug: deckSlug,
          noteTitle: noteTitle,
          temporaryDeckId: temporaryDeckId,
        ),
      ),
      child: Builder(
        builder: (context) => Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            leading: IconButton(
              icon: const Icon(Icons.close_rounded),
              onPressed: () => _backToDecks(context),
            ),
            title: Text(deckName),
          ),
          body: ContentWidth(
            maxWidth: Dimensions.summaryMaxWidth,
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(Dimensions.paddingLarge),
                child: FadeSlideIn(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: Dimensions.paddingMedium),
                      Icon(
                        ratio >= 0.8
                            ? Icons.auto_awesome_rounded
                            : Icons.insights_rounded,
                        size: 36,
                        color: ratio >= 0.8
                            ? context.colors.primary
                            : context.colors.ink,
                      ),
                      const SizedBox(height: Dimensions.paddingSmall),
                      Text(
                        _headline,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.displaySmall,
                      ),
                      const SizedBox(height: Dimensions.paddingSmall),
                      Text(
                        summary.total == 0
                            ? 'Nessuna risposta data'
                            : '${summary.total} card ripassate',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(height: Dimensions.paddingLarge * 1.5),
                      Center(
                        child: SizedBox.square(
                          dimension: 160,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0, end: ratio),
                                duration: const Duration(milliseconds: 900),
                                curve: Curves.easeOutCubic,
                                builder: (_, value, _) =>
                                    CircularProgressIndicator(
                                      value: value,
                                      strokeWidth: 14,
                                      strokeCap: StrokeCap.round,
                                      color: context.colors.knew,
                                      backgroundColor: summary.total == 0
                                          ? theme.colorScheme.outline
                                          : context.colors.didntKnow.withValues(
                                              alpha: 0.35,
                                            ),
                                    ),
                              ),
                              Center(
                                child: Text(
                                  '${(ratio * 100).round()}%',
                                  style: theme.textTheme.displaySmall,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: Dimensions.paddingLarge * 1.5),
                      _ResultRow(
                        label: 'Sapevo',
                        count: summary.knew,
                        color: context.colors.knew,
                      ),
                      const SizedBox(height: Dimensions.paddingSmall + 4),
                      _ResultRow(
                        label: 'Non sapevo',
                        count: summary.didntKnow,
                        color: context.colors.didntKnow,
                      ),
                      if (summary.total > 0) ...[
                        const SizedBox(height: Dimensions.paddingLarge),
                        const _SessionSavePrompt(),
                      ],
                      const SizedBox(height: Dimensions.spaceXl),
                      if (summary.missed.isNotEmpty) ...[
                        FilledButton.icon(
                          onPressed: () => _reviewMissed(context),
                          icon: const Icon(Icons.replay_rounded),
                          label: Text(
                            summary.missed.length == 1
                                ? 'Ripassa quella che non sapevi'
                                : 'Ripassa le ${summary.missed.length} che non sapevi',
                          ),
                        ),
                        const SizedBox(height: Dimensions.paddingSmall),
                        OutlinedButton(
                          onPressed: () => _studyAgain(context),
                          child: const Text('Continua a studiare'),
                        ),
                      ] else
                        FilledButton(
                          onPressed: () => _studyAgain(context),
                          child: const Text('Continua a studiare'),
                        ),
                      const SizedBox(height: Dimensions.paddingSmall),
                      TextButton(
                        onPressed: () => _backToDecks(context),
                        child: const Text('Torna ai mazzi'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SessionSavePrompt extends StatelessWidget {
  const _SessionSavePrompt();

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<SessionSaveCubit, SessionSaveState>(
        builder: (context, state) => Container(
          padding: const EdgeInsets.all(Dimensions.paddingMedium),
          decoration: BoxDecoration(
            color: context.colors.card,
            borderRadius: BorderRadius.circular(Dimensions.radiusLg),
          ),
          child: switch (state) {
            AskingSessionSaveState() => _choice(context),
            SavingSessionSaveState() => const Row(
              children: [
                SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
                SizedBox(width: Dimensions.paddingMedium),
                Text('Salvataggio della sessione…'),
              ],
            ),
            SavedSessionSaveState() => const Row(
              children: [
                Icon(Icons.check_circle_outline_rounded),
                SizedBox(width: Dimensions.paddingMedium),
                Text('Sessione salvata'),
              ],
            ),
            SkippedSessionSaveState() => const Text('Sessione non salvata'),
            ErrorSessionSaveState(:final message) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  message,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                const SizedBox(height: Dimensions.paddingSmall),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: context.read<SessionSaveCubit>().skip,
                      child: const Text('Non salvare'),
                    ),
                    FilledButton(
                      style: _compactFilledButtonStyle,
                      onPressed: context.read<SessionSaveCubit>().save,
                      child: const Text('Riprova'),
                    ),
                  ],
                ),
              ],
            ),
          },
        ),
      );

  Widget _choice(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        'Salvare questa sessione?',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      const SizedBox(height: Dimensions.paddingSmall),
      Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: context.read<SessionSaveCubit>().skip,
            child: const Text('Non salvare'),
          ),
          FilledButton(
            style: _compactFilledButtonStyle,
            onPressed: context.read<SessionSaveCubit>().save,
            child: const Text('Salva'),
          ),
        ],
      ),
    ],
  );

  ButtonStyle get _compactFilledButtonStyle => FilledButton.styleFrom(
    minimumSize: const Size(88, Dimensions.buttonHeight),
  );
}

class _ResultRow extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _ResultRow({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: Dimensions.paddingLarge - 4,
      vertical: Dimensions.paddingMedium,
    ),
    decoration: BoxDecoration(
      color: context.colors.card,
      borderRadius: BorderRadius.circular(Dimensions.radiusLg),
    ),
    child: Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: Dimensions.paddingMedium),
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.titleMedium),
        ),
        Text(
          '$count',
          style: Theme.of(context).textTheme.titleMedium
              ?.copyWith(color: color),
        ),
      ],
    ),
  );
}
