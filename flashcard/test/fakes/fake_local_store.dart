import 'package:flashcard/network/service/local_store_service.dart';

class FakeLocalStore implements LocalStoreService {
  final Map<String, String> values = {};

  @override
  String? read(String key) => values[key];

  @override
  void write(String key, String value) => values[key] = value;

  @override
  void remove(String key) => values.remove(key);

  @override
  void removeWhere(String prefix) =>
      values.removeWhere((key, _) => key.startsWith(prefix));
}
