import 'package:flashcard/model/entities/review_outcome.dart';
import 'package:flashcard/theme/app_colors.dart';
import 'package:flutter/material.dart';

class OutcomeDots extends StatelessWidget {
  final List<ReviewOutcome> outcomes;

  const OutcomeDots(this.outcomes, {super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Tooltip(
      message: 'Ultime risposte',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final outcome in outcomes)
            Container(
              width: 7,
              height: 7,
              margin: const EdgeInsets.only(left: 4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: outcome == ReviewOutcome.knew
                    ? colors.knew
                    : colors.didntKnow,
              ),
            ),
        ],
      ),
    );
  }
}
