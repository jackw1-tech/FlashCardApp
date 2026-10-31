import 'package:flashcard/model/entities/conversation.dart';
import 'package:flashcard/theme/app_colors.dart';
import 'package:flashcard/theme/app_text_styles.dart';
import 'package:flashcard/theme/dimensions.dart';
import 'package:flashcard/ui/widgets/card_markdown.dart';
import 'package:flutter/material.dart';

class ChatItemView extends StatelessWidget {
  final ChatItem item;

  final VoidCallback? onStudy;

  const ChatItemView({required this.item, this.onStudy, super.key});

  @override
  Widget build(BuildContext context) => switch (item.kind) {
    ChatItemKind.user => _Bubble(text: item.text, mine: true),
    ChatItemKind.assistant => _Bubble(text: item.text, mine: false),
    ChatItemKind.activity => _Activity(text: item.text),
    ChatItemKind.deckCreated => _DeckCreated(item: item, onStudy: onStudy),
  };
}

class _Bubble extends StatelessWidget {
  final String text;
  final bool mine;

  const _Bubble({required this.text, required this.mine});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: mine ? colors.primary : colors.card,
            borderRadius: BorderRadius.circular(Dimensions.radiusLg),
            border: mine ? null : Border.all(color: colors.hairline),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Dimensions.spaceSm,
              vertical: Dimensions.paddingSmall,
            ),
            child: mine
                ? Text(
                    text,
                    style: AppTextStyles.bodyMd.copyWith(
                      color: colors.onPrimary,
                    ),
                  )
                : CardMarkdown(text),
          ),
        ),
      ),
    );
  }
}

class _Activity extends StatelessWidget {
  final String text;

  const _Activity({required this.text});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: Dimensions.spaceXxs),
    child: Row(
      children: [
        Icon(Icons.bolt_rounded, size: 16, color: context.colors.muted),
        const SizedBox(width: Dimensions.spaceXxs),
        Text(
          text,
          style: AppTextStyles.caption.copyWith(color: context.colors.muted),
        ),
      ],
    ),
  );
}

class _DeckCreated extends StatelessWidget {
  final ChatItem item;
  final VoidCallback? onStudy;

  const _DeckCreated({required this.item, this.onStudy});

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      leading: const Icon(Icons.style_rounded),
      title: Text(item.text),
      subtitle: Text('${item.total ?? 0} card · scade a mezzanotte'),
      trailing: FilledButton(
        style: FilledButton.styleFrom(minimumSize: const Size(88, 40)),
        onPressed: onStudy,
        child: const Text('Studia'),
      ),
    ),
  );
}
