import 'package:flashcard/model/entities/note_summary.dart';
import 'package:flashcard/repositories/base_repository.dart';

abstract class ObsidianRepository extends BaseRepository<NoteSummary> {
  Future<bool> openNote(String noteTitle);
}
