import 'package:flashcard/mappers/app_settings_mapper.dart';
import 'package:flashcard/model/entities/app_settings.dart';
import 'package:flashcard/network/service/settings_service.dart';
import 'package:flashcard/other/constants/app_constants.dart';
import 'package:flashcard/repositories/impl/settings_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeSettingsService implements SettingsService {
  final Map<String, Object> values = {};

  @override
  Future<double?> readDouble(String key) async => values[key] as double?;

  @override
  Future<int?> readInt(String key) async => values[key] as int?;

  @override
  Future<void> writeDouble(String key, double value) async =>
      values[key] = value;

  @override
  Future<void> writeInt(String key, int value) async => values[key] = value;
}

void main() {
  test(
    'senza valori salvati restituisce le impostazioni predefinite',
    () async {
      final repository = SettingsRepositoryImpl(
        service: FakeSettingsService(),
        mapper: const AppSettingsMapper(),
      );

      expect(await repository.load(), const AppSettings());
    },
  );

  test('salva e rilegge le impostazioni', () async {
    final service = FakeSettingsService();
    final repository = SettingsRepositoryImpl(
      service: service,
      mapper: const AppSettingsMapper(),
    );

    await repository.save(const AppSettings(textScale: 1.3, dailyGoal: 50));

    expect(service.values[AppConstants.textScaleKey], 1.3);
    expect(service.values[AppConstants.dailyGoalKey], 50);
    expect(
      await repository.load(),
      const AppSettings(textScale: 1.3, dailyGoal: 50),
    );
  });
}
