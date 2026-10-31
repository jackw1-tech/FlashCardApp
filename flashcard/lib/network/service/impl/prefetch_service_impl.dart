import 'package:flashcard/network/platform/prefetch.dart';
import 'package:flashcard/network/service/prefetch_service.dart';

class PrefetchServiceImpl implements PrefetchService {
  @override
  Future<PrefetchedResponse?> take(String name) => takePrefetched(name);
}
