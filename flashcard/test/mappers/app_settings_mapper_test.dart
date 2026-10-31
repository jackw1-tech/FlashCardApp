import 'package:flashcard/mappers/app_settings_mapper.dart';
import 'package:flashcard/model/entities/app_settings.dart';
import 'package:flashcard/network/dto/settings_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('i valori mancanti prendono quelli predefiniti', () {
    expect(
      const AppSettingsMapper().fromDTO(const SettingsDTO()),
      const AppSettings(),
    );
  });

  test('andata e ritorno tra DTO e modello', () {
    const settings = AppSettings(textScale: 1.3, dailyGoal: 50);
    final mapper = const AppSettingsMapper();

    expect(mapper.fromDTO(mapper.toDTO(settings)), settings);
  });
}
