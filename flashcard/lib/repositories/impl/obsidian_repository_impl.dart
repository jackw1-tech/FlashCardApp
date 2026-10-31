import 'package:flashcard/network/service/obsidian_service.dart';
import 'package:flashcard/other/constants/api_constants.dart';
import 'package:flashcard/repositories/obsidian_repository.dart';

class ObsidianRepositoryImpl implements ObsidianRepository {
  final ObsidianService service;
  final String vault;

  ObsidianRepositoryImpl({
    required this.service,
    this.vault = ApiConstants.obsidianVault,
  });

  @override
  Future<bool> openNote(String noteTitle) =>
      service.openNote(vault: vault, noteTitle: noteTitle);
}
