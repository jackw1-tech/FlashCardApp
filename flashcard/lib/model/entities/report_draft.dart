import 'package:flashcard/model/base_model.dart';
import 'package:flashcard/model/entities/report_reason.dart';
import 'package:uuid/uuid.dart';

class ReportDraft implements BaseModel {
  @override
  final String id;
  final String cardId;
  final ReportReason reason;
  final String comment;

  const ReportDraft({
    required this.id,
    required this.cardId,
    required this.reason,
    required this.comment,
  });

  ReportDraft.create({
    required this.cardId,
    required this.reason,
    this.comment = '',
  }) : id = const Uuid().v4();

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'cardId': cardId,
    'reason': reason.name,
    'comment': comment,
  };

  @override
  ReportDraft copyWith({String? id, String? comment}) => ReportDraft(
    id: id ?? this.id,
    cardId: cardId,
    reason: reason,
    comment: comment ?? this.comment,
  );
}
