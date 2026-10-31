import 'package:flashcard/model/entities/auth_user.dart';
import 'package:flashcard/network/dto/session_dto.dart';
import 'package:pine/pine.dart';

class AuthUserMapper extends DTOMapper<SessionUserDTO, AuthUser> {
  const AuthUserMapper();

  @override
  AuthUser fromDTO(SessionUserDTO dto) =>
      AuthUser(id: '${dto.id}', username: dto.username);

  @override
  SessionUserDTO toDTO(AuthUser model) =>
      SessionUserDTO(id: int.parse(model.id), username: model.username);
}
