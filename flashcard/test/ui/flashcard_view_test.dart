import 'package:flashcard/model/entities/review_outcome.dart';
import 'package:flashcard/theme/app_text_styles.dart';
import 'package:flashcard/ui/widgets/flashcard_view.dart';
import 'package:flashcard/ui/widgets/outcome_dots.dart';
import 'package:flashcard/ui/widgets/card_markdown.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> pump(
  WidgetTester tester, {
  double textScale = 1.0,
  List<ReviewOutcome> history = const [],
}) => tester.pumpWidget(
  MaterialApp(
    home: Scaffold(
      body: FlashcardView(
        front: 'Domanda',
        back: 'Risposta',
        caption: 'Nota',
        revealed: false,
        interactive: true,
        textScale: textScale,
        recentOutcomes: history,
        onReveal: () {},
        onSwipe: (_) {},
      ),
    ),
  ),
);

double frontFontSize(WidgetTester tester) {
  final text = tester.widget<SelectableText>(
    find.byWidgetPredicate(
      (w) => w is SelectableText && w.textSpan?.toPlainText() == 'Domanda',
    ),
  );
  final span = text.textSpan!;
  return span.style?.fontSize ??
      (span.children!.first as TextSpan).style!.fontSize!;
}

void main() {
  setUpAll(preloadCardMarkdown);

  testWidgets('la dimensione del testo scelta ingrandisce la domanda', (
    tester,
  ) async {
    await pump(tester);
    final normal = frontFontSize(tester);

    await pump(tester, textScale: 1.3);

    expect(normal, AppTextStyles.flashcard.fontSize);
    expect(frontFontSize(tester), closeTo(normal * 1.3, 0.01));
  });

  testWidgets('mostra un pallino per ogni esito recente', (tester) async {
    await pump(
      tester,
      history: [
        ReviewOutcome.knew,
        ReviewOutcome.didntKnow,
        ReviewOutcome.knew,
      ],
    );

    final dots = find.descendant(
      of: find.byType(OutcomeDots),
      matching: find.byType(Container),
    );
    expect(dots, findsNWidgets(3));
  });
}
