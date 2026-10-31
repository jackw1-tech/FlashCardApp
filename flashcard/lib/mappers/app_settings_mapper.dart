import 'package:flashcard/model/entities/app_settings.dart';
import 'package:flashcard/network/dto/settings_dto.dart';
import 'package:pine/pine.dart';

class AppSettingsMapper extends DTOMapper<SettingsDTO, AppSettings> {
  const AppSettingsMapper();

  @override
  AppSettings fromDTO(SettingsDTO dto) {
    const defaults = AppSettings();
    return AppSettings(
      textScale: dto.textScale ?? defaults.textScale,
      dailyGoal: dto.dailyGoal ?? defaults.dailyGoal,
    );
  }

  @override
  SettingsDTO toDTO(AppSettings model) =>
      SettingsDTO(textScale: model.textScale, dailyGoal: model.dailyGoal);
}
