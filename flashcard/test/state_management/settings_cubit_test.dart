import 'package:flashcard/model/entities/app_settings.dart';
import 'package:flashcard/repositories/settings_repository.dart';
import 'package:flashcard/state_management/cubits/settings_cubit/settings_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeSettingsRepository implements SettingsRepository {
  AppSettings stored;

  FakeSettingsRepository(this.stored);

  @override
  Future<AppSettings> load() async => stored;

  @override
  Future<void> save(AppSettings settings) async => stored = settings;
}

void main() {
  test(
    'parte con le impostazioni predefinite e poi carica quelle salvate',
    () async {
      final repository = FakeSettingsRepository(
        const AppSettings(textScale: 1.3, dailyGoal: 50),
      );
      final cubit = SettingsCubit(repository: repository);

      expect(cubit.state, const AppSettings());
      await cubit.load();

      expect(cubit.state, const AppSettings(textScale: 1.3, dailyGoal: 50));
    },
  );

  test('ogni modifica viene salvata sul telefono', () async {
    final repository = FakeSettingsRepository(const AppSettings());
    final cubit = SettingsCubit(repository: repository);

    await cubit.setTextScale(1.15);
    await cubit.setDailyGoal(10);

    expect(
      repository.stored,
      const AppSettings(textScale: 1.15, dailyGoal: 10),
    );
  });
}
