import 'package:flashcard/network/service/impl/obsidian_service_impl.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('il link alla nota codifica spazi e freccia senza usare il +', () {
    final uri = ObsidianServiceImpl.noteUri(
      '2Brain',
      'Failover, split brain e fencing',
    );

    expect(
      uri.toString(),
      'obsidian://open?vault=2Brain&file=Flashcard%20-%3E%20Failover%2C%20split%20brain%20e%20fencing',
    );
  });
}
