import 'package:pine/pine.dart';

class ReportRequestDTO extends DTO {
  final String reason;
  final String comment;

  const ReportRequestDTO({required this.reason, required this.comment});

  factory ReportRequestDTO.fromJson(Map<String, dynamic> json) =>
      ReportRequestDTO(
        reason: json['reason'] as String,
        comment: json['comment'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {'reason': reason, 'comment': comment};
}
