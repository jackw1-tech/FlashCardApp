import 'package:flashcard/model/entities/db_node.dart';
import 'package:flashcard/repositories/base_repository.dart';

abstract class ReadSourceRepository extends BaseRepository<DbNode> {
  Stream<DbNode> get nodes;
}
