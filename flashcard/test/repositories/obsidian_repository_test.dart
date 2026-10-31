import 'package:flashcard/network/service/obsidian_service.dart';
import 'package:flashcard/repositories/impl/obsidian_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeObsidianService implements ObsidianService {
  String? vault;
  String? noteTitle;
  bool installed = true;

  @override
  Future<bool> openNote({
    required String vault,
    required String noteTitle,
  }) async {
    this.vault = vault;
    this.noteTitle = noteTitle;
    return installed;
  }
}

void main() {
  test('apre la nota nel vault configurato', () async {
    final service = FakeObsidianService();
    final repository = ObsidianRepositoryImpl(service: service, vault: 'V');

    expect(await repository.openNote('Liste'), isTrue);
    expect((service.vault, service.noteTitle), ('V', 'Liste'));
  });

  test('restituisce false se Obsidian non è installato', () async {
    final service = FakeObsidianService()..installed = false;
    final repository = ObsidianRepositoryImpl(service: service);

    expect(await repository.openNote('Liste'), isFalse);
  });
}
