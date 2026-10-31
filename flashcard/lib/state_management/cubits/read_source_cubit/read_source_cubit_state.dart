part of 'read_source_cubit.dart';

class ReadSourceState {
  final DbNode? node;

  final int count;

  const ReadSourceState({this.node, this.count = 0});

  @override
  bool operator ==(Object other) =>
      other is ReadSourceState && other.node == node && other.count == count;

  @override
  int get hashCode => Object.hash(node, count);
}
