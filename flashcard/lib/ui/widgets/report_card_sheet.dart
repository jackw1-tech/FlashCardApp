import 'package:flashcard/model/entities/report_reason.dart';
import 'package:flashcard/theme/app_colors.dart';
import 'package:flashcard/theme/app_text_styles.dart';
import 'package:flashcard/theme/dimensions.dart';
import 'package:flutter/material.dart';

typedef ReportSheetResult = ({ReportReason reason, String comment});

class ReportCardSheet extends StatefulWidget {
  final String cardId;
  final String front;

  const ReportCardSheet({required this.cardId, required this.front, super.key});

  static Future<ReportSheetResult?> show(
    BuildContext context, {
    required String cardId,
    required String front,
  }) => showModalBottomSheet<ReportSheetResult>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => ReportCardSheet(cardId: cardId, front: front),
  );

  @override
  State<ReportCardSheet> createState() => _ReportCardSheetState();
}

class _ReportCardSheetState extends State<ReportCardSheet> {
  ReportReason _reason = ReportReason.wrongAnswer;
  final _comment = TextEditingController();

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            Dimensions.paddingLarge,
            0,
            Dimensions.paddingLarge,
            Dimensions.paddingLarge,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Segnala la card',
                style: AppTextStyles.displaySm.copyWith(color: colors.ink),
              ),
              const SizedBox(height: Dimensions.spaceXxs),
              Text(
                widget.front,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption.copyWith(color: colors.muted),
              ),
              const SizedBox(height: Dimensions.paddingMedium),
              RadioGroup<ReportReason>(
                groupValue: _reason,
                onChanged: (reason) =>
                    setState(() => _reason = reason ?? _reason),
                child: Column(
                  children: [
                    for (final reason in ReportReason.values)
                      RadioListTile<ReportReason>(
                        value: reason,
                        contentPadding: EdgeInsets.zero,
                        activeColor: colors.primary,
                        title: Text(
                          reason.label,
                          style: AppTextStyles.bodyMd.copyWith(
                            color: colors.ink,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: Dimensions.paddingSmall),
              TextField(
                controller: _comment,
                minLines: 2,
                maxLines: 4,
                maxLength: 2000,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'Cosa c\'è da correggere? (facoltativo)',
                ),
              ),
              const SizedBox(height: Dimensions.paddingSmall),
              FilledButton(
                onPressed: () =>
                    Navigator.of(context)
                        .pop((reason: _reason, comment: _comment.text)),
                child: const Text('Invia segnalazione'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
