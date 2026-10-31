import 'dart:async';
import 'dart:convert';

import 'package:flashcard/network/service/prefetch_service.dart';
import 'package:flashcard/other/constants/api_constants.dart';
import 'package:http/http.dart' as http;

typedef SessionResult = ({int status, Map<String, dynamic>? body});

class SessionRefresher {
  final http.Client _client;
  final String _baseUrl;
  final PrefetchService _prefetch;
  final Duration _raceRetryDelay;

  final _updates = StreamController<Map<String, dynamic>>.broadcast();
  final _expired = StreamController<void>.broadcast();
  Future<SessionResult>? _inflight;

  SessionRefresher({
    required http.Client client,
    required String baseUrl,
    required PrefetchService prefetch,
    Duration raceRetryDelay = const Duration(milliseconds: 300),
  }) : _client = client,
       _baseUrl = baseUrl,
       _prefetch = prefetch,
       _raceRetryDelay = raceRetryDelay;

  Stream<Map<String, dynamic>> get updates => _updates.stream;

  Stream<void> get expired => _expired.stream;

  Future<SessionResult> refresh() =>
      _inflight ??= _refresh().whenComplete(() => _inflight = null);

  void publish(Map<String, dynamic> body) => _updates.add(body);

  void markExpired() => _expired.add(null);

  Future<SessionResult> _refresh() async {
    var result = await _call(usePrefetch: true);
    if (result.status == 409) {
      await Future<void>.delayed(_raceRetryDelay);
      result = await _call(usePrefetch: false);
    }
    if (result.body != null) publish(result.body!);
    return result;
  }

  Future<SessionResult> _call({required bool usePrefetch}) async {
    final prefetched = usePrefetch ? await _prefetch.take('session') : null;
    final (status, body) = prefetched != null
        ? (prefetched.status, prefetched.body)
        : await _get();
    return (
      status: status,
      body: status == 200 ? jsonDecode(body) as Map<String, dynamic> : null,
    );
  }

  Future<(int, String)> _get() async {
    final response = await _client.get(
      Uri.parse('$_baseUrl${ApiConstants.sessionPath}'),
    );
    return (response.statusCode, utf8.decode(response.bodyBytes));
  }
}
