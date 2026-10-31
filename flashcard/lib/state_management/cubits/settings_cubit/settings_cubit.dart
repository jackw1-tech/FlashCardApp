import 'package:flashcard/model/entities/app_settings.dart';
import 'package:flashcard/repositories/settings_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SettingsCubit extends Cubit<AppSettings> {
  final SettingsRepository repository;

  SettingsCubit({required this.repository}) : super(const AppSettings());

  Future<void> load() async => emit(await repository.load());

  Future<void> setTextScale(double textScale) =>
      _update(state.copyWith(textScale: textScale));

  Future<void> setDailyGoal(int dailyGoal) =>
      _update(state.copyWith(dailyGoal: dailyGoal));

  Future<void> _update(AppSettings settings) async {
    emit(settings);
    await repository.save(settings);
  }
}
