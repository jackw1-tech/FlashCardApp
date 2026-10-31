import 'package:flashcard/network/service/base_service.dart';

typedef PrefetchedResponse = ({int status, String body});

abstract class PrefetchService extends BaseService {
  Future<PrefetchedResponse?> take(String name);
}
