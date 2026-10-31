import 'package:flashcard/model/entities/study_card.dart';
import 'package:flashcard/theme/app_colors.dart';
import 'package:flashcard/theme/app_text_styles.dart';
import 'package:flashcard/theme/dimensions.dart';
import 'package:flashcard/ui/widgets/card_markdown.dart';
import 'package:flutter/material.dart';

class CardTile extends StatefulWidget {
  final StudyCard card;

  final Widget? header;

  final List<Widget> actions;

  const CardTile({
    required this.card,
    this.header,
    this.actions = const [],
    super.key,
  });

  @override
  State<CardTile> createState() => _CardTileState();
}

class _CardTileState extends State<CardTile> {
  bool _showBack = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final radius = BorderRadius.circular(Dimensions.radiusLg);
    return Material(
      color: colors.card,
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: () => setState(() => _showBack = !_showBack),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            Dimensions.paddingLarge - 4,
            Dimensions.paddingMedium,
            Dimensions.paddingLarge - 4,
            Dimensions.paddingSmall,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${widget.card.deckName} · ${widget.card.noteTitle}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption.copyWith(color: colors.muted),
              ),
              if (widget.header != null) ...[
                const SizedBox(height: Dimensions.spaceXxs),
                widget.header!,
              ],
              const SizedBox(height: Dimensions.paddingSmall),
              CardMarkdown(
                widget.card.front,
                style: AppTextStyles.titleSm.copyWith(color: colors.ink),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                alignment: Alignment.topCenter,
                child: _showBack
                    ? Padding(
                        padding: const EdgeInsets.only(
                          top: Dimensions.paddingSmall,
                        ),
                        child: CardMarkdown(
                          widget.card.back,
                          style: AppTextStyles.bodySm.copyWith(
                            color: colors.body,
                          ),
                        ),
                      )
                    : const SizedBox(width: double.infinity),
              ),
              Row(
                children: [
                  Text(
                    _showBack ? 'Nascondi risposta' : 'Mostra risposta',
                    style: AppTextStyles.caption.copyWith(
                      color: colors.primary,
                    ),
                  ),
                  const Spacer(),
                  ...widget.actions,
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
