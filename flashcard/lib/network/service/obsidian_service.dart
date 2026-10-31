import 'package:flashcard/network/service/base_service.dart';

abstract class ObsidianService extends BaseService {
  Future<bool> openNote({required String vault, required String noteTitle});
}
