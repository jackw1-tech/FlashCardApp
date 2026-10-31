import 'dart:async';

import 'package:flashcard/network/service/read_source_service.dart';

class ReadSourceServiceImpl implements ReadSourceService {
  final _controller = StreamController<String?>.broadcast();

  @override
  Stream<String?> get sources => _controller.stream;

  @override
  void record(String? value) => _controller.add(value);
}
