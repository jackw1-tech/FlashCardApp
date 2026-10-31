import 'package:flashcard/network/service/base_service.dart';

abstract class ReadSourceService extends BaseService {
  Stream<String?> get sources;

  void record(String? value);
}
