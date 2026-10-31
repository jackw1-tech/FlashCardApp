import 'package:flashcard/network/service/read_source_service.dart';
import 'package:http/http.dart' as http;

class ReadSourceInterceptor extends http.BaseClient {
  static const header = 'x-read-from';

  final http.Client _inner;
  final ReadSourceService _service;

  ReadSourceInterceptor(this._inner, this._service);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final response = await _inner.send(request);
    _service.record(response.headers[header]);
    return response;
  }

  @override
  void close() => _inner.close();
}
