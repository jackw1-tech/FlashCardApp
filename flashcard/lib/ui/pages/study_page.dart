import 'package:auto_route/auto_route.dart';
import 'package:flashcard/model/entities/review_outcome.dart';
import 'package:flashcard/model/entities/study_card.dart';
import 'package:flashcard/routers/app_router.dart';
import 'package:flashcard/state_management/cubits/settings_cubit/settings_cubit.dart';
import 'package:flashcard/state_management/cubits/study_session_cubit/study_session_cubit.dart';
import 'package:flashcard/theme/app_colors.dart';
import 'package:flashcard/theme/dimensions.dart';
import 'package:flashcard/ui/widgets/answer_button.dart';
import 'package:flashcard/ui/widgets/card_actions_listener.dart';
import 'package:flashcard/ui/widgets/card_actions_menu.dart';
import 'package:flashcard/ui/widgets/content_width.dart';
import 'package:flashcard/ui/widgets/error_view.dart';
import 'package:flashcard/ui/widgets/flashcard_view.dart';
import 'package:flashcard/ui/widgets/outcome_counter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

@RoutePage()
class StudyPage extends StatelessWidget {
  final String? deckSlug;
  final String deckName;

  final int sessionLength;

  final String? noteTitle;

  final String? temporaryDeckId;

  final List<StudyCard>? fixedCards;

  const StudyPage({
    required this.deckName,
    required this.sessionLength,
    this.deckSlug,
    this.noteTitle,
    this.temporaryDeckId,
    this.fixedCards,
    super.key,
  });

  String get _title => noteTitle ?? deckName;

  Future<void> _requestFinish(BuildContext context) async {
    final cubit = context.read<StudySessionCubit>();
    final state = cubit.state;
    final answered = switch (state) {
      ShowingCardStudySessionState(:final summary) => summary.total,
      _ => 0,
    };
    if (answered == 0) {
      cubit.finish();
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Terminare la sessione?'),
        content: Text(
          answered == 1
              ? 'La risposta già data resta salvata.'
              : 'Le $answered risposte già date restano salvate.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Continua'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Termina'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) cubit.finish();
  }

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (context) => StudySessionCubit(
      repository: context.read(),
      deckSlug: deckSlug,
      noteTitle: noteTitle,
      temporaryDeckId: temporaryDeckId,
      fixedCards: fixedCards,
      length: sessionLength,
    )..loadNext(),
    child: MultiBlocListener(
      listeners: [
        BlocListener<StudySessionCubit, StudySessionState>(
          listenWhen: (_, state) => state is FinishedStudySessionState,
          listener: (context, state) => context.router.replace(
            SessionSummaryRoute(
              deckSlug: deckSlug,
              deckName: deckName,
              noteTitle: noteTitle,
              temporaryDeckId: temporaryDeckId,
              sessionLength: sessionLength,
              summary: (state as FinishedStudySessionState).summary,
            ),
          ),
        ),
        BlocListener<StudySessionCubit, StudySessionState>(
          listenWhen: (previous, current) =>
              previous is ShowingCardStudySessionState &&
              previous.submitting &&
              current is! ShowingCardStudySessionState,
          listener: (_, _) => HapticFeedback.lightImpact(),
        ),
        BlocListener<StudySessionCubit, StudySessionState>(
          listenWhen: (_, state) =>
              state is ShowingCardStudySessionState && state.notice != null,
          listener: (context, state) => ScaffoldMessenger.of(context)
              .showSnackBar(
                SnackBar(
                  content: Text(
                    (state as ShowingCardStudySessionState).notice!,
                  ),
                ),
              ),
        ),
      ],
      child: CardActionsListener(
        child: PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _requestFinish(context);
          },
          child: Scaffold(
            appBar: AppBar(
              automaticallyImplyLeading: false,
              leading: Builder(
                builder: (context) => IconButton(
                  tooltip: 'Termina sessione',
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => _requestFinish(context),
                ),
              ),
              title: BlocBuilder<StudySessionCubit, StudySessionState>(
                builder: (context, state) => Column(
                  children: [
                    Text(
                      state is ShowingCardStudySessionState
                          ? '${state.position} / ${state.length}'
                          : _title,
                    ),
                    if (state is ShowingCardStudySessionState)
                      Text(
                        _title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
              actions: [
                BlocBuilder<StudySessionCubit, StudySessionState>(
                  builder: (context, state) => switch (state) {
                    ShowingCardStudySessionState() => Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Annulla l\'ultima risposta',
                          icon: const Icon(Icons.undo_rounded),
                          onPressed: state.canUndo && !state.submitting
                              ? context.read<StudySessionCubit>().undo
                              : null,
                        ),
                        CardActionsMenu(card: state.card),
                      ],
                    ),
                    _ => const SizedBox.shrink(),
                  },
                ),
              ],
            ),
            body: _Keyboard(
              builder: (flashcard) =>
                  BlocBuilder<StudySessionCubit, StudySessionState>(
                    buildWhen: (_, state) =>
                        state is! FinishedStudySessionState,
                    builder: (context, state) => switch (state) {
                      LoadingStudySessionState() ||
                      FinishedStudySessionState() => const Center(
                        child: CircularProgressIndicator(),
                      ),
                      ErrorStudySessionState(:final message) => ErrorView(
                        message: message,
                        onRetry: () =>
                            context.read<StudySessionCubit>().loadNext(),
                      ),
                      final ShowingCardStudySessionState showing => _Session(
                        showing,
                        flashcard,
                      ),
                    },
                  ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _Session extends StatelessWidget {
  final ShowingCardStudySessionState state;
  final FlashcardController flashcard;

  const _Session(this.state, this.flashcard);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cubit = context.read<StudySessionCubit>();
    final canAnswer = state.revealed && !state.submitting;

    final wide = context.isWide;
    return SafeArea(
      child: ContentWidth(
        maxWidth: Dimensions.studyMaxWidth,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Dimensions.paddingMedium,
          ),
          child: Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(
                  Dimensions.progressBarHeight,
                ),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(end: (state.position - 1) / state.length),
                  duration: const Duration(
                    milliseconds: Dimensions.swipeDurationMs,
                  ),
                  builder: (_, value, _) => LinearProgressIndicator(
                    value: value,
                    minHeight: Dimensions.progressBarHeight,
                  ),
                ),
              ),
              const SizedBox(height: Dimensions.paddingMedium),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OutcomeCounter(
                    count: state.summary.didntKnow,
                    label: 'Non sapevo',
                    color: context.colors.didntKnow,
                  ),
                  OutcomeCounter(
                    count: state.summary.knew,
                    label: 'Sapevo',
                    color: context.colors.knew,
                    alignEnd: true,
                  ),
                ],
              ),
              const SizedBox(height: Dimensions.spaceXxs),
              AnimatedSwitcher(
                duration: const Duration(
                  milliseconds: Dimensions.microAnimationMs,
                ),
                child: Text(
                  state.length - state.position + 1 == 1
                      ? 'Ultima card'
                      : '${state.length - state.position + 1} card rimaste',
                  key: ValueKey(state.position),
                  style: theme.textTheme.bodySmall,
                ),
              ),
              const SizedBox(height: Dimensions.paddingMedium),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxHeight: Dimensions.flashcardMaxHeight,
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(
                        milliseconds: Dimensions.swipeDurationMs,
                      ),
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: ScaleTransition(
                          scale: Tween(
                            begin: 0.94,
                            end: 1.0,
                          ).animate(animation),
                          child: child,
                        ),
                      ),
                      child: FlashcardView(
                        controller: flashcard,
                        key: ValueKey('${state.card.id}-${state.position}'),
                        front: state.card.front,
                        back: state.card.back,
                        caption: state.card.noteTitle,
                        recentOutcomes: state.card.recentOutcomes,
                        textScale: context.select<SettingsCubit, double>(
                          (settings) => settings.state.textScale,
                        ),
                        revealed: state.revealed,
                        interactive: !state.submitting,
                        onReveal: cubit.reveal,
                        onSwipe: cubit.answer,
                        keyboardHints: wide,
                      ),
                    ),
                  ),
                ),
              ),
              if (state.error != null) ...[
                const SizedBox(height: Dimensions.paddingMedium),
                Container(
                  padding: const EdgeInsets.only(
                    left: Dimensions.paddingMedium,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(Dimensions.radiusLg),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Risposta non salvata. ${state.error}',
                          style: TextStyle(
                            color: theme.colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: state.submitting
                            ? null
                            : () => cubit.answer(state.failedOutcome!),
                        child: const Text('Reinvia'),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: Dimensions.paddingLarge),
              SizedBox(
                height: Dimensions.answerButtonSize + 26,
                child: state.revealed
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          AnswerButton(
                            icon: Icons.close_rounded,
                            label: 'Non sapevo',
                            color: context.colors.didntKnow,
                            onPressed: canAnswer
                                ? () => cubit.answer(ReviewOutcome.didntKnow)
                                : null,
                          ),
                          AnswerButton(
                            icon: Icons.check_rounded,
                            label: 'Sapevo',
                            color: context.colors.knew,
                            onPressed: canAnswer
                                ? () => cubit.answer(ReviewOutcome.knew)
                                : null,
                          ),
                        ],
                      )
                    : Center(
                        child: Text(
                          wide
                              ? 'Spazio gira · ← → rispondono · Z annulla · Esc chiude'
                              : 'Pensa alla risposta, poi tocca la card',
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
              ),
              const SizedBox(height: Dimensions.paddingSmall),
            ],
          ),
        ),
      ),
    );
  }
}

class _Keyboard extends StatefulWidget {
  final Widget Function(FlashcardController flashcard) builder;

  const _Keyboard({required this.builder});

  @override
  State<_Keyboard> createState() => _KeyboardState();
}

class _KeyboardState extends State<_Keyboard> {
  final _focus = FocusNode(debugLabel: 'sessione');
  final _flashcard = FlashcardController();

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final cubit = context.read<StudySessionCubit>();
    switch (event.logicalKey) {
      case LogicalKeyboardKey.space || LogicalKeyboardKey.enter:
        _flashcard.flip();
      case LogicalKeyboardKey.arrowRight || LogicalKeyboardKey.keyK:
        _flashcard.answer(ReviewOutcome.knew);
      case LogicalKeyboardKey.arrowLeft || LogicalKeyboardKey.keyJ:
        _flashcard.answer(ReviewOutcome.didntKnow);
      case LogicalKeyboardKey.keyZ || LogicalKeyboardKey.backspace:
        cubit.undo();
      case LogicalKeyboardKey.escape:
        cubit.finish();
      default:
        return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) => Focus(
    focusNode: _focus,
    autofocus: true,
    onKeyEvent: _onKey,
    child: widget.builder(_flashcard),
  );
}
