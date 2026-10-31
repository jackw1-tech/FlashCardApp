import 'package:auto_route/auto_route.dart';
import 'package:flashcard/state_management/cubits/notes_cubit/notes_cubit.dart';
import 'package:flashcard/model/entities/note_summary.dart';
import 'package:flashcard/theme/app_colors.dart';
import 'package:flashcard/theme/app_text_styles.dart';
import 'package:flashcard/theme/dimensions.dart';
import 'package:flashcard/ui/widgets/error_view.dart';
import 'package:flashcard/ui/widgets/loading_skeleton.dart';
import 'package:flashcard/ui/widgets/motion.dart';
import 'package:flashcard/ui/widgets/session_length_sheet.dart';
import 'package:flashcard/ui/widgets/content_width.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

@RoutePage()
class NotesPage extends StatelessWidget {
  final String deckSlug;
  final String deckName;

  const NotesPage({required this.deckSlug, required this.deckName, super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (context) =>
        NotesCubit(repository: context.read(), deckSlug: deckSlug)..fetch(),
    child: Scaffold(
      appBar: AppBar(title: Text(deckName)),
      body: ContentWidth(
        maxWidth: Dimensions.readingMaxWidth,
        child: BlocBuilder<NotesCubit, NotesState>(
          builder: (context, state) => switch (state) {
            FetchingNotesState() => const LoadingSkeleton(),
            ErrorNotesState(:final message) => ErrorView(
              message: message,
              onRetry: () => context.read<NotesCubit>().fetch(),
            ),
            FetchedNotesState(:final notes) => ListView.separated(
              padding: const EdgeInsets.all(Dimensions.paddingMedium),
              itemCount: notes.length + 1,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: Dimensions.paddingSmall),
              itemBuilder: (context, index) {
                final colors = context.colors;
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(
                      bottom: Dimensions.paddingSmall,
                    ),
                    child: Text(
                      '${notes.length} argomenti',
                      style: AppTextStyles.captionUppercase.copyWith(
                        color: colors.muted,
                      ),
                    ),
                  );
                }
                final note = notes[index - 1];
                return FadeSlideIn(
                  key: ValueKey(note.id),
                  child: _NoteTile(
                    note: note,
                    onTap: () => SessionLengthSheet.startSession(
                      context,
                      deckSlug: deckSlug,
                      deckName: deckName,
                      noteTitle: note.title,
                      totalCards: note.totalCards,
                    ),
                  ),
                );
              },
            ),
          },
        ),
      ),
    ),
  );
}

class _NoteTile extends StatelessWidget {
  final NoteSummary note;
  final VoidCallback onTap;

  const _NoteTile({required this.note, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final seen = note.totalCards - note.unseenCards;
    final progress = note.totalCards == 0 ? 0.0 : seen / note.totalCards;
    final radius = BorderRadius.circular(Dimensions.radiusLg);
    return Material(
      color: colors.card,
      borderRadius: radius,
      child: Pressable(
        borderRadius: radius,
        onTap: onTap,
        semanticLabel: '${note.title}, ${note.totalCards} card',
        child: Padding(
          padding: const EdgeInsets.all(Dimensions.paddingMedium + 4),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      note.title,
                      style: AppTextStyles.titleSm.copyWith(color: colors.ink),
                    ),
                    const SizedBox(height: Dimensions.spaceXxs),
                    Text(
                      '${note.totalCards} card · $seen viste',
                      style: AppTextStyles.caption.copyWith(
                        color: colors.muted,
                      ),
                    ),
                    const SizedBox(height: Dimensions.paddingSmall),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(
                        Dimensions.radiusPill,
                      ),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(end: progress),
                        duration: context.motionDuration(550),
                        builder: (_, value, _) => LinearProgressIndicator(
                          value: value,
                          minHeight: Dimensions.progressBarHeight,
                          color: colors.knew,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: Dimensions.paddingMedium),
              Icon(Icons.arrow_forward_rounded, size: 20, color: colors.muted),
            ],
          ),
        ),
      ),
    );
  }
}
