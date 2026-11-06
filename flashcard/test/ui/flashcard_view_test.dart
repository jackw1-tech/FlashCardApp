import 'package:flashcard/model/entities/review_outcome.dart';
import 'package:flashcard/theme/app_text_styles.dart';
import 'package:flashcard/theme/dimensions.dart';
import 'package:flashcard/ui/widgets/flashcard_view.dart';
import 'package:flashcard/ui/widgets/outcome_dots.dart';
import 'package:flashcard/ui/widgets/card_markdown.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> pump(
  WidgetTester tester, {
  double textScale = 1.0,
  List<ReviewOutcome> history = const [],
  FlashcardController? controller,
  bool revealed = false,
}) => tester.pumpWidget(
  MaterialApp(
    home: Scaffold(
      body: FlashcardView(
        front: 'Domanda',
        back: 'Risposta',
        caption: 'Nota',
        revealed: revealed,
        interactive: true,
        textScale: textScale,
        recentOutcomes: history,
        controller: controller,
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

  testWidgets('il flip non ricostruisce il contenuto Markdown a ogni frame', (
    tester,
  ) async {
    final controller = FlashcardController();
    await pump(tester, controller: controller);

    debugCardMarkdownBuildCount = 0;
    addTearDown(() => debugCardMarkdownBuildCount = 0);

    controller.flip();
    for (
      var elapsed = Duration.zero;
      elapsed < const Duration(milliseconds: Dimensions.flipDurationMs);
      elapsed += const Duration(milliseconds: 16)
    ) {
      await tester.pump(const Duration(milliseconds: 16));
    }

    expect(debugCardMarkdownBuildCount, 0);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is SelectableText &&
            widget.textSpan?.toPlainText() == 'Risposta',
      ),
      findsOneWidget,
    );
  });

  testWidgets(
    'il trascinamento non ricostruisce il Markdown a ogni movimento',
    (tester) async {
      await pump(tester, revealed: true);

      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(FlashcardView)),
      );
      await gesture.moveBy(const Offset(20, 0));
      await tester.pump();
      debugCardMarkdownBuildCount = 0;
      addTearDown(() => debugCardMarkdownBuildCount = 0);

      for (var i = 0; i < 10; i++) {
        await gesture.moveBy(const Offset(5, 0));
        await tester.pump();
      }

      expect(debugCardMarkdownBuildCount, 0);
      await gesture.cancel();
    },
  );
}
