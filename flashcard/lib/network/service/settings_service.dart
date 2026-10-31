import 'package:flashcard/network/service/base_service.dart';

abstract class SettingsService extends BaseService {
  Future<double?> readDouble(String key);

  Future<int?> readInt(String key);

  Future<void> writeDouble(String key, double value);

  Future<void> writeInt(String key, int value);
}
