import 'package:flashcard/network/interceptor/session_refresher.dart';
import 'package:flashcard/other/constants/api_constants.dart';
import 'package:http/http.dart' as http;

class SessionInterceptor extends http.BaseClient {
  final http.Client _inner;
  final SessionRefresher _refresher;

  SessionInterceptor(this._inner, this._refresher);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final retry = _copy(request);
    final response = await _inner.send(request);
    if (response.statusCode != 401 ||
        request.url.path.startsWith(ApiConstants.authPathPrefix) ||
        retry == null) {
      return response;
    }
    final refreshed = await _refresher.refresh();
    if (refreshed.status != 200) {
      _refresher.markExpired();
      return response;
    }
    await response.stream.drain<void>();
    return _inner.send(retry);
  }

  http.Request? _copy(http.BaseRequest request) {
    if (request is! http.Request) return null;
    return http.Request(request.method, request.url)
      ..headers.addAll(request.headers)
      ..bodyBytes = request.bodyBytes
      ..followRedirects = request.followRedirects;
  }

  @override
  void close() => _inner.close();
}
