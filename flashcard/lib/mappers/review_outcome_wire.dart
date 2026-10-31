import 'package:flashcard/model/entities/review_outcome.dart';

const Map<ReviewOutcome, String> _wire = {
  ReviewOutcome.knew: 'knew',
  ReviewOutcome.didntKnow: 'didnt_know',
};

String outcomeToWire(ReviewOutcome outcome) => _wire[outcome]!;

ReviewOutcome outcomeFromWire(String value) =>
    _wire.entries.firstWhere((entry) => entry.value == value).key;
