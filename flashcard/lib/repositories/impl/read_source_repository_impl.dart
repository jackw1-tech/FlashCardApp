import 'package:flashcard/mappers/db_node_wire.dart';
import 'package:flashcard/model/entities/db_node.dart';
import 'package:flashcard/network/service/read_source_service.dart';
import 'package:flashcard/repositories/read_source_repository.dart';

class ReadSourceRepositoryImpl implements ReadSourceRepository {
  final ReadSourceService service;

  ReadSourceRepositoryImpl({required this.service});

  @override
  Stream<DbNode> get nodes =>
      service.sources.map(dbNodeFromWire).where((n) => n != null).cast();
}
