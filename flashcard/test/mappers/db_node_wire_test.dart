import 'package:flashcard/mappers/db_node_wire.dart';
import 'package:flashcard/model/entities/db_node.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('primary è il primary, qualunque alias di replica è una replica', () {
    expect(dbNodeFromWire('primary'), DbNode.primary);
    expect(dbNodeFromWire('replica1'), DbNode.replica);
    expect(dbNodeFromWire('replica2'), DbNode.replica);
  });

  test('senza header non c\'è un database', () {
    expect(dbNodeFromWire(null), isNull);
    expect(dbNodeFromWire(''), isNull);
  });
}
