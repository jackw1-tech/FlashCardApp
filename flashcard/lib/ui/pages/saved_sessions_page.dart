import 'package:auto_route/auto_route.dart';
import 'package:flashcard/model/entities/saved_session.dart';
import 'package:flashcard/state_management/cubits/saved_sessions_cubit/saved_sessions_cubit.dart';
import 'package:flashcard/theme/app_colors.dart';
import 'package:flashcard/theme/app_text_styles.dart';
import 'package:flashcard/theme/dimensions.dart';
import 'package:flashcard/ui/widgets/content_width.dart';
import 'package:flashcard/ui/widgets/error_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

@RoutePage()
class SavedSessionsPage extends StatelessWidget {
  const SavedSessionsPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (context) =>
        SavedSessionsCubit(repository: context.read())..fetch(),
    child: Scaffold(
      appBar: AppBar(title: const Text('Sessioni salvate')),
      body: ContentWidth(
        maxWidth: Dimensions.readingMaxWidth,
        child: BlocBuilder<SavedSessionsCubit, SavedSessionsState>(
          builder: (context, state) => switch (state) {
            FetchingSavedSessionsState() => const Center(
              child: CircularProgressIndicator(),
            ),
            ErrorSavedSessionsState(:final message) => ErrorView(
              message: message,
              onRetry: context.read<SavedSessionsCubit>().fetch,
            ),
            FetchedSavedSessionsState(:final sessions) when sessions.isEmpty =>
              Center(
                child: Text(
                  'Nessuna sessione salvata.',
                  style: AppTextStyles.bodySm.copyWith(
                    color: context.colors.muted,
                  ),
                ),
              ),
            FetchedSavedSessionsState(:final sessions) => RefreshIndicator(
              onRefresh: context.read<SavedSessionsCubit>().fetch,
              child: ListView.separated(
                padding: const EdgeInsets.all(Dimensions.paddingMedium),
                itemCount: sessions.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: Dimensions.paddingSmall),
                itemBuilder: (_, index) =>
                    _SessionTile(session: sessions[index]),
              ),
            ),
          },
        ),
      ),
    ),
  );
}

class _SessionTile extends StatelessWidget {
  final SavedSession session;

  const _SessionTile({required this.session});

  String get _context =>
      session.temporaryDeckName ??
      session.noteTitle ??
      session.deckName ??
      'Tutti i mazzi';

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('dd/MM/yyyy · HH:mm')
        .format(session.endedAt.toLocal());
    return Material(
      color: context.colors.card,
      borderRadius: BorderRadius.circular(Dimensions.radiusLg),
      child: ListTile(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Dimensions.radiusLg),
        ),
        leading: CircleAvatar(child: Text('${session.total}')),
        title: Text(_context),
        subtitle: Text(
          '$date\n${session.knew} sapevo · ${session.didntKnow} non sapevo',
        ),
        isThreeLine: true,
      ),
    );
  }
}
