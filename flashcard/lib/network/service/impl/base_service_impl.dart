import 'dart:convert';

import 'package:flashcard/network/api_exception.dart';
import 'package:flashcard/network/service/base_service.dart';
import 'package:flashcard/network/service/prefetch_service.dart';
import 'package:flashcard/other/constants/app_constants.dart';
import 'package:http/http.dart' as http;

abstract class BaseServiceImpl implements BaseService {
  final http.Client client;

  final String baseUrl;

  final PrefetchService? prefetch;

  BaseServiceImpl({required this.client, required this.baseUrl, this.prefetch});

  Future<Map<String, dynamic>> getJsonPrefetched(
    String name,
    String path,
  ) async {
    final prefetched = await prefetch?.take(name);
    if (prefetched != null && prefetched.status == 200) {
      return jsonDecode(prefetched.body) as Map<String, dynamic>;
    }
    return getJson(path);
  }

  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, String>? query,
  }) => _send(() => client.get(_uri(path, query)));

  Future<Map<String, dynamic>> postJson(
    String path,
    Map<String, dynamic> body, {
    Duration? timeout,
  }) => _send(
    () => client.post(
      _uri(path),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    ),
    timeout: timeout,
  );

  Future<void> delete(String path) => _send(() => client.delete(_uri(path)));

  Future<Map<String, dynamic>> patchJson(
    String path,
    Map<String, dynamic> body,
  ) => _send(
    () => client.patch(
      _uri(path),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    ),
  );

  Uri _uri(String path, [Map<String, String>? query]) {
    if (baseUrl.isEmpty) throw const ApiException.configuration();
    final uri = Uri.parse('$baseUrl$path');
    return query == null || query.isEmpty
        ? uri
        : uri.replace(queryParameters: query);
  }

  Future<Map<String, dynamic>> _send(
    Future<http.Response> Function() request, {
    Duration? timeout,
  }) async {
    final http.Response response;
    try {
      response = await request().timeout(
        timeout ?? AppConstants.requestTimeout,
      );
    } on ApiException {
      rethrow;
    } on Exception catch (error) {
      throw ApiException.network(error.toString());
    }
    Object? body;
    if (response.bodyBytes.isNotEmpty) {
      try {
        body = jsonDecode(utf8.decode(response.bodyBytes));
      } on FormatException {
        final message = response.statusCode >= 400
            ? response.reasonPhrase ?? 'Errore HTTP ${response.statusCode}'
            : 'Il server ha restituito una risposta non valida.';
        throw ApiException(response.statusCode, message);
      }
    }
    if (response.statusCode >= 400) {
      final detail = body is Map<String, dynamic>
          ? body['detail'] ?? body.toString()
          : response.reasonPhrase;
      throw ApiException(response.statusCode, '$detail');
    }
    return body as Map<String, dynamic>? ?? const {};
  }
}
