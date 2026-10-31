import 'package:flashcard/model/entities/auth_user.dart';
import 'package:flashcard/repositories/base_repository.dart';

abstract class AuthRepository extends BaseRepository<AuthUser> {
  AuthUser? likelySessionUser();

  bool likelyAccessValid();

  Future<AuthUser?> restoreSession();

  Future<AuthUser> login(String username, String password);

  Future<void> logout();

  Stream<void> get sessionExpired;
}
