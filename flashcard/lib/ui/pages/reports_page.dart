import 'package:auto_route/auto_route.dart';
import 'package:flashcard/state_management/cubits/card_actions_cubit/card_actions_cubit.dart';
import 'package:flashcard/state_management/cubits/reports_cubit/reports_cubit.dart';
import 'package:flashcard/theme/app_colors.dart';
import 'package:flashcard/theme/app_text_styles.dart';
import 'package:flashcard/theme/dimensions.dart';
import 'package:flashcard/ui/widgets/card_actions_listener.dart';
import 'package:flashcard/ui/widgets/card_tile.dart';
import 'package:flashcard/ui/widgets/error_view.dart';
import 'package:flashcard/ui/widgets/content_width.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

@RoutePage()
class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (context) => ReportsCubit(repository: context.read())..fetch(),
    child: CardActionsListener(
      child: Scaffold(
        appBar: AppBar(title: const Text('Card segnalate')),
        body: ContentWidth(
          maxWidth: Dimensions.readingMaxWidth,
          child: BlocConsumer<ReportsCubit, ReportsState>(
            listenWhen: (_, state) =>
                state is FetchedReportsState && state.notice != null,
            listener: (context, state) => ScaffoldMessenger.of(context)
                .showSnackBar(
                  SnackBar(
                    content: Text((state as FetchedReportsState).notice!),
                  ),
                ),
            builder: (context, state) => switch (state) {
              FetchingReportsState() => const Center(
                child: CircularProgressIndicator(),
              ),
              ErrorReportsState(:final message) => ErrorView(
                message: message,
                onRetry: () => context.read<ReportsCubit>().fetch(),
              ),
              FetchedReportsState(:final reports) when reports.isEmpty =>
                Center(
                  child: Text(
                    'Nessuna card da correggere.',
                    style: AppTextStyles.bodySm.copyWith(
                      color: context.colors.muted,
                    ),
                  ),
                ),
              FetchedReportsState(:final reports) => ListView.separated(
                padding: const EdgeInsets.all(Dimensions.paddingMedium),
                itemCount: reports.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: Dimensions.paddingSmall),
                itemBuilder: (context, index) {
                  final report = reports[index];
                  final colors = context.colors;
                  return CardTile(
                    card: report.card,
                    header: Text(
                      report.comment.isEmpty
                          ? report.reason.label
                          : '${report.reason.label}: ${report.comment}',
                      style: AppTextStyles.caption.copyWith(
                        color: colors.didntKnow,
                      ),
                    ),
                    actions: [
                      IconButton(
                        tooltip: 'Apri la nota in Obsidian',
                        icon: const Icon(Icons.open_in_new_rounded),
                        onPressed: () => context
                            .read<CardActionsCubit>()
                            .openInObsidian(report.card.noteTitle),
                      ),
                      TextButton.icon(
                        onPressed: () =>
                            context.read<ReportsCubit>().resolve(report.id),
                        icon: const Icon(Icons.check_rounded),
                        label: const Text('Risolta'),
                      ),
                    ],
                  );
                },
              ),
            },
          ),
        ),
      ),
    ),
  );
}
