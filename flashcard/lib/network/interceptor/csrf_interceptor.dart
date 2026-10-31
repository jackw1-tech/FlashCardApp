import 'package:http/http.dart' as http;

class CsrfInterceptor extends http.BaseClient {
  static const header = 'X-Requested-With';
  static const value = 'flashcard';

  final http.Client _inner;

  CsrfInterceptor(this._inner);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    if (request.method != 'GET' && request.method != 'HEAD') {
      request.headers[header] = value;
    }
    return _inner.send(request);
  }

  @override
  void close() => _inner.close();
}
