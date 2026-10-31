import 'package:pine/pine.dart';

class SettingsDTO extends DTO {
  final double? textScale;
  final int? dailyGoal;

  const SettingsDTO({this.textScale, this.dailyGoal});

  factory SettingsDTO.fromJson(Map<String, dynamic> json) => SettingsDTO(
    textScale: (json['text_scale'] as num?)?.toDouble(),
    dailyGoal: json['daily_goal'] as int?,
  );

  Map<String, dynamic> toJson() => {
    'text_scale': textScale,
    'daily_goal': dailyGoal,
  };
}
