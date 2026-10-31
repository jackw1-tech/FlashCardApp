import 'package:flashcard/network/interceptor/session_refresher.dart';
import 'package:flashcard/network/service/auth_service.dart';
import 'package:flashcard/network/service/impl/base_service_impl.dart';
import 'package:flashcard/other/constants/api_constants.dart';

class AuthServiceImpl extends BaseServiceImpl implements AuthService {
  final SessionRefresher refresher;

  AuthServiceImpl({
    required super.client,
    required super.baseUrl,
    required this.refresher,
  });

  @override
  Future<Map<String, dynamic>> login(String username, String password) async {
    final body = await postJson(ApiConstants.loginPath, {
      'username': username,
      'password': password,
    });
    refresher.publish(body);
    return body;
  }

  @override
  Future<SessionResult> session() => refresher.refresh();

  @override
  Future<void> logout() => postJson(ApiConstants.logoutPath, const {});

  @override
  Stream<Map<String, dynamic>> get sessionUpdates => refresher.updates;

  @override
  Stream<void> get sessionExpired => refresher.expired;
}
