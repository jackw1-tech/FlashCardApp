import 'package:flashcard/network/interceptor/session_refresher.dart';
import 'package:flashcard/network/service/base_service.dart';

abstract class AuthService extends BaseService {
  Future<Map<String, dynamic>> login(String username, String password);

  Future<SessionResult> session();

  Future<void> logout();

  Stream<Map<String, dynamic>> get sessionUpdates;

  Stream<void> get sessionExpired;
}
