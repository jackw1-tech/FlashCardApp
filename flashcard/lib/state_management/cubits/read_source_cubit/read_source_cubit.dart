import 'dart:async';

import 'package:flashcard/model/entities/db_node.dart';
import 'package:flashcard/repositories/read_source_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'read_source_cubit_state.dart';

class ReadSourceCubit extends Cubit<ReadSourceState> {
  final ReadSourceRepository repository;
  StreamSubscription<DbNode>? _subscription;

  ReadSourceCubit({required this.repository}) : super(const ReadSourceState());

  void start() {
    _subscription ??= repository.nodes.listen(
      (node) => emit(ReadSourceState(node: node, count: state.count + 1)),
    );
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
