import 'package:flashcard/model/entities/app_settings.dart';
import 'package:flashcard/network/dto/settings_dto.dart';
import 'package:flashcard/network/service/settings_service.dart';
import 'package:flashcard/other/constants/app_constants.dart';
import 'package:flashcard/repositories/settings_repository.dart';
import 'package:pine/pine.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  final SettingsService service;
  final DTOMapper<SettingsDTO, AppSettings> mapper;

  SettingsRepositoryImpl({required this.service, required this.mapper});

  @override
  Future<AppSettings> load() async => mapper.fromDTO(
    SettingsDTO(
      textScale: await service.readDouble(AppConstants.textScaleKey),
      dailyGoal: await service.readInt(AppConstants.dailyGoalKey),
    ),
  );

  @override
  Future<void> save(AppSettings settings) async {
    final dto = mapper.toDTO(settings);
    await service.writeDouble(AppConstants.textScaleKey, dto.textScale!);
    await service.writeInt(AppConstants.dailyGoalKey, dto.dailyGoal!);
  }
}
