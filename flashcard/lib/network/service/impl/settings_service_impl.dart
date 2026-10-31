import 'package:flashcard/network/service/settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsServiceImpl implements SettingsService {
  final SharedPreferencesAsync _prefs;

  SettingsServiceImpl({SharedPreferencesAsync? prefs})
    : _prefs = prefs ?? SharedPreferencesAsync();

  @override
  Future<double?> readDouble(String key) => _prefs.getDouble(key);

  @override
  Future<int?> readInt(String key) => _prefs.getInt(key);

  @override
  Future<void> writeDouble(String key, double value) =>
      _prefs.setDouble(key, value);

  @override
  Future<void> writeInt(String key, int value) => _prefs.setInt(key, value);
}
