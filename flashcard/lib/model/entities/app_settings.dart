import 'package:flashcard/other/constants/app_constants.dart';

class AppSettings {
  final double textScale;

  final int dailyGoal;

  const AppSettings({
    this.textScale = 1.0,
    this.dailyGoal = AppConstants.defaultDailyGoal,
  });

  AppSettings copyWith({double? textScale, int? dailyGoal}) => AppSettings(
    textScale: textScale ?? this.textScale,
    dailyGoal: dailyGoal ?? this.dailyGoal,
  );

  @override
  bool operator ==(Object other) =>
      other is AppSettings &&
      other.textScale == textScale &&
      other.dailyGoal == dailyGoal;

  @override
  int get hashCode => Object.hash(textScale, dailyGoal);
}
