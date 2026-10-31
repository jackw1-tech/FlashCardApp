import 'package:flashcard/model/entities/db_node.dart';

DbNode? dbNodeFromWire(String? value) {
  if (value == null || value.isEmpty) return null;
  return value == 'primary' ? DbNode.primary : DbNode.replica;
}
