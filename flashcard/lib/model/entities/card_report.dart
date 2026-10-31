import 'package:flashcard/model/base_model.dart';
import 'package:flashcard/model/entities/report_reason.dart';
import 'package:flashcard/model/entities/study_card.dart';

class CardReport implements BaseModel {
  @override
  final String id;
  final ReportReason reason;
  final String comment;
  final DateTime createdAt;
  final StudyCard card;

  const CardReport({
    required this.id,
    required this.reason,
    required this.comment,
    required this.createdAt,
    required this.card,
  });

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'reason': reason.name,
    'comment': comment,
    'createdAt': createdAt.toIso8601String(),
    'card': card.toJson(),
  };

  @override
  CardReport copyWith({String? id, ReportReason? reason, String? comment}) =>
      CardReport(
        id: id ?? this.id,
        reason: reason ?? this.reason,
        comment: comment ?? this.comment,
        createdAt: createdAt,
        card: card,
      );
}
