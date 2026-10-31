import 'package:flashcard/model/entities/conversation.dart';
import 'package:flashcard/theme/app_theme.dart';
import 'package:flashcard/ui/widgets/chat_item_view.dart';
import 'package:flashcard/ui/widgets/pending_confirmation_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget app(Widget child) => MaterialApp(
  theme: AppTheme.lightTheme,
  home: Scaffold(body: child),
);

void main() {
  testWidgets('la scheda di conferma si disegna e i pulsanti rispondono', (
    tester,
  ) async {
    var approved = false;
    var rejected = false;
    await tester.pumpWidget(
      app(
        PendingConfirmationCard(
          pending: const PendingConfirmation(
            action: 'Creare il mazzo provvisorio?',
            deck: PendingDeck(
              name: 'Fencing token',
              total: 9,
              byNote: [(note: 'Failover, split brain e fencing', taken: 9)],
              adjustments: ['Chieste 20 card, ne esistono 9.'],
            ),
          ),
          enabled: true,
          onApprove: () => approved = true,
          onReject: () => rejected = true,
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Fencing token · 9 card'), findsOneWidget);
    await tester.tap(find.text('Crea il mazzo'));
    await tester.tap(find.text('No, cambia'));
    expect((approved, rejected), (true, true));
  });

  testWidgets('il mazzo creato nella chat ha il pulsante Studia', (
    tester,
  ) async {
    var studied = false;
    await tester.pumpWidget(
      app(
        ChatItemView(
          item: const ChatItem(
            kind: ChatItemKind.deckCreated,
            text: 'Fencing token',
            temporaryDeckId: '3',
            total: 9,
          ),
          onStudy: () => studied = true,
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Studia'));
    expect(studied, isTrue);
  });
}
