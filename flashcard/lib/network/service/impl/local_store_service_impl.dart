import 'package:flashcard/network/platform/local_storage.dart';
import 'package:flashcard/network/service/local_store_service.dart';

class LocalStoreServiceImpl implements LocalStoreService {
  @override
  String? read(String key) => storageRead(key);

  @override
  void write(String key, String value) => storageWrite(key, value);

  @override
  void remove(String key) => storageRemove(key);

  @override
  void removeWhere(String prefix) {
    for (final key in storageKeys()) {
      if (key.startsWith(prefix)) storageRemove(key);
    }
  }
}
