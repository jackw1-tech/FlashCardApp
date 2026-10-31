import 'package:flashcard/network/service/base_service.dart';

abstract class LocalStoreService extends BaseService {
  String? read(String key);

  void write(String key, String value);

  void remove(String key);

  void removeWhere(String prefix);
}
