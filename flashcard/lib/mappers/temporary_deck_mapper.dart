import 'package:flashcard/model/entities/temporary_deck.dart';
import 'package:flashcard/network/dto/temporary_deck_dto.dart';
import 'package:pine/pine.dart';

class TemporaryDeckMapper extends DTOMapper<TemporaryDeckDTO, TemporaryDeck> {
  const TemporaryDeckMapper();

  @override
  TemporaryDeck fromDTO(TemporaryDeckDTO dto) => TemporaryDeck(
    id: '${dto.id}',
    name: dto.name,
    createdAt: DateTime.parse(dto.createdAt),
    expiresAt: DateTime.parse(dto.expiresAt),
    total: dto.total,
    done: dto.done,
    missed: dto.missed,
  );

  @override
  TemporaryDeckDTO toDTO(TemporaryDeck model) => TemporaryDeckDTO(
    id: int.parse(model.id),
    name: model.name,
    createdAt: model.createdAt.toIso8601String(),
    expiresAt: model.expiresAt.toIso8601String(),
    total: model.total,
    done: model.done,
    missed: model.missed,
  );
}
