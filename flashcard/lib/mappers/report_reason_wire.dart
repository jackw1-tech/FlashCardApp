import 'package:flashcard/model/entities/report_reason.dart';

const Map<ReportReason, String> _wire = {
  ReportReason.wrongAnswer: 'wrong_answer',
  ReportReason.badFormat: 'bad_format',
  ReportReason.other: 'other',
};

String reasonToWire(ReportReason reason) => _wire[reason]!;

ReportReason reasonFromWire(String value) =>
    _wire.entries.firstWhere((entry) => entry.value == value).key;
