import 'package:auto_route/auto_route.dart';
import 'package:flashcard/state_management/cubits/search_cubit/search_cubit.dart';
import 'package:flashcard/theme/app_colors.dart';
import 'package:flashcard/theme/app_text_styles.dart';
import 'package:flashcard/theme/dimensions.dart';
import 'package:flashcard/ui/widgets/card_actions_listener.dart';
import 'package:flashcard/ui/widgets/card_actions_menu.dart';
import 'package:flashcard/ui/widgets/card_tile.dart';
import 'package:flashcard/ui/widgets/error_view.dart';
import 'package:flashcard/ui/widgets/loading_skeleton.dart';
import 'package:flashcard/ui/widgets/motion.dart';
import 'package:flashcard/ui/widgets/content_width.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

@RoutePage()
class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (context) => SearchCubit(repository: context.read()),
    child: CardActionsListener(
      child: Scaffold(
        appBar: AppBar(title: const Text('Cerca')),
        body: const ContentWidth(
          maxWidth: Dimensions.readingMaxWidth,
          child: _SearchBody(),
        ),
      ),
    ),
  );
}

class _SearchBody extends StatefulWidget {
  const _SearchBody();

  @override
  State<_SearchBody> createState() => _SearchBodyState();
}

class _SearchBodyState extends State<_SearchBody> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _changed(String value) {
    setState(() {});
    context.read<SearchCubit>().queryChanged(value);
  }

  void _clear() {
    _controller.clear();
    _changed('');
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(
          Dimensions.paddingMedium,
          Dimensions.paddingSmall,
          Dimensions.paddingMedium,
          Dimensions.paddingMedium,
        ),
        child: TextField(
          controller: _controller,
          autofocus: true,
          textInputAction: TextInputAction.search,
          onChanged: _changed,
          onTapOutside: (_) => FocusScope.of(context).unfocus(),
          decoration: InputDecoration(
            hintText: 'Domanda, risposta o argomento',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: _controller.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Cancella ricerca',
                    onPressed: _clear,
                    icon: const Icon(Icons.close_rounded),
                  ),
          ),
        ),
      ),
      Expanded(
        child: BlocBuilder<SearchCubit, SearchState>(
          builder: (context, state) => AnimatedSwitcher(
            duration: context.motionDuration(220),
            child: switch (state) {
              IdleSearchState() => const _Hint(
                key: ValueKey('idle'),
                icon: Icons.manage_search_rounded,
                text: 'Scrivi almeno 2 lettere per cercare.',
              ),
              SearchingSearchState() => const LoadingSkeleton(
                key: ValueKey('loading'),
                rows: 3,
              ),
              ErrorSearchState(:final message) => ErrorView(
                key: const ValueKey('error'),
                message: message,
                onRetry: () => _changed(_controller.text),
              ),
              ResultsSearchState(:final results) when results.isEmpty =>
                const _Hint(
                  key: ValueKey('empty'),
                  icon: Icons.search_off_rounded,
                  text: 'Nessuna card trovata. Prova parole più brevi.',
                ),
              ResultsSearchState(:final results) => ListView.separated(
                key: ValueKey('results-${results.length}'),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(
                  Dimensions.paddingMedium,
                  0,
                  Dimensions.paddingMedium,
                  Dimensions.paddingLarge,
                ),
                itemCount: results.length + 1,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: Dimensions.paddingSmall),
                itemBuilder: (_, index) => index == 0
                    ? Padding(
                        padding: const EdgeInsets.only(
                          bottom: Dimensions.spaceXxs,
                        ),
                        child: Text(
                          '${results.length} risultati',
                          style: AppTextStyles.captionUppercase.copyWith(
                            color: context.colors.muted,
                          ),
                        ),
                      )
                    : FadeSlideIn(
                        child: CardTile(
                          card: results[index - 1],
                          actions: [CardActionsMenu(card: results[index - 1])],
                        ),
                      ),
              ),
            },
          ),
        ),
      ),
    ],
  );
}

class _Hint extends StatelessWidget {
  final IconData icon;
  final String text;

  const _Hint({required this.icon, required this.text, super.key});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(Dimensions.spaceXl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 42, color: context.colors.muted),
          const SizedBox(height: Dimensions.paddingMedium),
          Text(
            text,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySm.copyWith(color: context.colors.muted),
          ),
        ],
      ),
    ),
  );
}
