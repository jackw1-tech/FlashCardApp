import 'package:flashcard/model/entities/study_card.dart';

class SessionSummary {
  final int knew;
  final int didntKnow;

  final List<StudyCard> missed;

  final List<String> reviewIds;

  const SessionSummary({
    required this.knew,
    required this.didntKnow,
    this.missed = const [],
    this.reviewIds = const [],
  });

  int get total => knew + didntKnow;

  @override
  bool operator ==(Object other) =>
      other is SessionSummary &&
      other.knew == knew &&
      other.didntKnow == didntKnow &&
      _sameIds(other.missed, missed) &&
      _sameValues(other.reviewIds, reviewIds);

  @override
  int get hashCode => Object.hash(
    knew,
    didntKnow,
    Object.hashAll(missed.map((c) => c.id)),
    Object.hashAll(reviewIds),
  );

  static bool _sameIds(List<StudyCard> a, List<StudyCard> b) =>
      a.length == b.length &&
      [for (var i = 0; i < a.length; i++) a[i].id == b[i].id]
          .every((same) => same);

  static bool _sameValues(List<String> a, List<String> b) =>
      a.length == b.length &&
      [for (var i = 0; i < a.length; i++) a[i] == b[i]].every((same) => same);
}
