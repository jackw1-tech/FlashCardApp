import 'package:auto_route/auto_route.dart';
import 'package:flashcard/model/entities/app_settings.dart';
import 'package:flashcard/model/entities/vault_sync_report.dart';
import 'package:flashcard/other/constants/app_constants.dart';
import 'package:flashcard/routers/app_router.dart';
import 'package:flashcard/state_management/cubits/auth_cubit/auth_cubit.dart';
import 'package:flashcard/state_management/cubits/settings_cubit/settings_cubit.dart';
import 'package:flashcard/state_management/cubits/decks_cubit/decks_cubit.dart';
import 'package:flashcard/state_management/cubits/vault_sync_cubit/vault_sync_cubit.dart';
import 'package:flashcard/theme/app_colors.dart';
import 'package:flashcard/theme/app_text_styles.dart';
import 'package:flashcard/theme/dimensions.dart';
import 'package:flashcard/ui/widgets/content_width.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

@RoutePage()
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      appBar: AppBar(title: const Text('Impostazioni')),
      body: ContentWidth(
        maxWidth: Dimensions.readingMaxWidth,
        child: BlocBuilder<SettingsCubit, AppSettings>(
          builder: (context, settings) {
            final cubit = context.read<SettingsCubit>();
            return ListView(
              padding: const EdgeInsets.all(Dimensions.paddingMedium),
              children: [
                _Section(
                  title: 'Dimensione del testo',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SegmentedButton<double>(
                        showSelectedIcon: false,
                        segments: [
                          for (final (i, scale)
                              in AppConstants.textScaleOptions.indexed)
                            ButtonSegment(
                              value: scale,
                              label: Text(AppConstants.textScaleLabels[i]),
                            ),
                        ],
                        selected: {settings.textScale},
                        onSelectionChanged: (selection) =>
                            cubit.setTextScale(selection.single),
                      ),
                      const SizedBox(height: Dimensions.paddingMedium),
                      Container(
                        padding: const EdgeInsets.all(Dimensions.paddingLarge),
                        decoration: BoxDecoration(
                          color: colors.flashcard,
                          border: Border.all(color: colors.hairline),
                          borderRadius: BorderRadius.circular(
                            Dimensions.radiusXl,
                          ),
                        ),
                        child: Text(
                          'Come si crea un follower senza fermare il leader?',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.flashcard.copyWith(
                            color: colors.ink,
                            fontSize:
                                AppTextStyles.flashcard.fontSize! *
                                settings.textScale,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                _Section(
                  title: 'Obiettivo del giorno',
                  child: Wrap(
                    spacing: Dimensions.paddingSmall,
                    children: [
                      for (final goal in AppConstants.dailyGoalOptions)
                        ChoiceChip(
                          label: Text('$goal card'),
                          selected: settings.dailyGoal == goal,
                          onSelected: (_) => cubit.setDailyGoal(goal),
                        ),
                    ],
                  ),
                ),
                _Section(
                  title: 'Account',
                  child: Material(
                    color: colors.card,
                    borderRadius: BorderRadius.circular(Dimensions.radiusLg),
                    child: ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          Dimensions.radiusLg,
                        ),
                      ),
                      leading: const Icon(Icons.person_outline_rounded),
                      title: Text(switch (context.watch<AuthCubit>().state) {
                        AuthenticatedAuthState(:final user) => user.username,
                        _ => '',
                      }),
                      trailing: TextButton(
                        onPressed: () => context.read<AuthCubit>().logout(),
                        child: const Text('Esci'),
                      ),
                    ),
                  ),
                ),
                _Section(
                  title: 'Vault',
                  child: Column(
                    children: [
                      Material(
                        color: colors.card,
                        borderRadius: BorderRadius.circular(
                          Dimensions.radiusLg,
                        ),
                        child: ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              Dimensions.radiusLg,
                            ),
                          ),
                          leading: const Icon(Icons.history_rounded),
                          title: const Text('Sessioni salvate'),
                          subtitle: const Text(
                            'Storico dei ripassi conservati',
                          ),
                          trailing: const Icon(Icons.arrow_forward_rounded),
                          onTap: () =>
                              context.router.push(const SavedSessionsRoute()),
                        ),
                      ),
                      const SizedBox(height: Dimensions.paddingSmall),
                      const _VaultSyncTile(),
                      const SizedBox(height: Dimensions.paddingSmall),
                      Material(
                        color: colors.card,
                        borderRadius: BorderRadius.circular(
                          Dimensions.radiusLg,
                        ),
                        child: ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              Dimensions.radiusLg,
                            ),
                          ),
                          leading: const Icon(Icons.flag_outlined),
                          title: const Text('Card segnalate'),
                          subtitle: const Text('Da correggere nelle note'),
                          trailing: const Icon(Icons.arrow_forward_rounded),
                          onTap: () =>
                              context.router.push(const ReportsRoute()),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _VaultSyncTile extends StatelessWidget {
  const _VaultSyncTile();

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (context) => VaultSyncCubit(repository: context.read()),
    child: BlocConsumer<VaultSyncCubit, VaultSyncState>(
      listenWhen: (_, state) => state is CompletedVaultSyncState,
      listener: (context, state) async {
        final report = (state as CompletedVaultSyncState).report;
        await context.read<DecksCubit>().fetch();
        if (!context.mounted) return;
        await showDialog<void>(
          context: context,
          builder: (_) => _VaultSyncReportDialog(report: report),
        );
      },
      builder: (context, state) {
        final syncing = state is SyncingVaultSyncState;
        final error = switch (state) {
          ErrorVaultSyncState(:final message) => message,
          _ => null,
        };
        return Material(
          color: context.colors.card,
          borderRadius: BorderRadius.circular(Dimensions.radiusLg),
          child: ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Dimensions.radiusLg),
            ),
            leading: syncing
                ? const SizedBox.square(
                    dimension: 24,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  )
                : const Icon(Icons.sync_rounded),
            title: Text(
              syncing ? 'Sincronizzazione in corso…' : 'Sincronizza Vault',
            ),
            subtitle: Text(
              error ??
                  (syncing
                      ? 'Attendi: import ed embedding possono richiedere alcuni minuti'
                      : 'Scarica da GitHub e aggiorna card ed embedding'),
            ),
            trailing: syncing ? null : const Icon(Icons.arrow_forward_rounded),
            onTap: syncing ? null : context.read<VaultSyncCubit>().sync,
          ),
        );
      },
    ),
  );
}

class _VaultSyncReportDialog extends StatelessWidget {
  final VaultSyncReport report;

  const _VaultSyncReportDialog({required this.report});

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(
      report.isPartial
          ? 'Vault aggiornato parzialmente'
          : 'Vault sincronizzato',
    ),
    content: SingleChildScrollView(
      child: Text(
        '${report.branch}@${report.id}\n'
        '${report.notes} note · ${report.cards} card\n\n'
        'Create: ${report.created}\n'
        'Aggiornate: ${report.updated}\n'
        'Archiviate: ${report.archived}\n'
        'Ripristinate: ${report.restored}\n'
        'Problemi: ${report.problems}\n\n'
        'Embedding calcolati: ${report.embeddings}\n'
        'Già aggiornati: ${report.embeddingsUpToDate}'
        '${report.embeddingError == null ? '' : '\n\nEmbedding non completati:\n${report.embeddingError}'}',
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Chiudi'),
      ),
    ],
  );
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;

  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: Dimensions.spaceXl),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title.toUpperCase(),
          style: AppTextStyles.captionUppercase.copyWith(
            color: context.colors.muted,
          ),
        ),
        const SizedBox(height: Dimensions.spaceSm),
        child,
      ],
    ),
  );
}
