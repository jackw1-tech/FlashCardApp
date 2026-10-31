import 'package:flashcard/model/entities/app_settings.dart';
import 'package:flashcard/repositories/base_repository.dart';

abstract class SettingsRepository extends BaseRepository<AppSettings> {
  Future<AppSettings> load();

  Future<void> save(AppSettings settings);
}
