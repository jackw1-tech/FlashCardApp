import 'dart:async';
import 'dart:convert';

import 'package:flashcard/network/interceptor/csrf_interceptor.dart';
import 'package:flashcard/network/interceptor/session_interceptor.dart';
import 'package:flashcard/network/interceptor/session_refresher.dart';
import 'package:flashcard/network/service/prefetch_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const base = 'http://api.test';
const sessionBody = {
  'user': {'id': 1, 'username': 'giacomo'},
  'access_expires_at': '2026-10-23T10:00:00Z',
  'refresh_expires_at': '2026-11-22T10:00:00Z',
};

class NoPrefetch implements PrefetchService {
  @override
  Future<PrefetchedResponse?> take(String name) async => null;
}

class OnePrefetch implements PrefetchService {
  PrefetchedResponse? response;

  OnePrefetch(this.response);

  @override
  Future<PrefetchedResponse?> take(String name) async {
    final taken = response;
    response = null;
    return name == 'session' ? taken : null;
  }
}

class FakeBackend {
  bool sessionValid = false;
  List<int> sessionStatuses = [200];
  int sessionCalls = 0;
  final List<http.Request> apiRequests = [];
  final Completer<void> releaseSession = Completer()..complete();

  late final MockClient client = MockClient((request) async {
    if (request.url.path == '/api/auth/session/') {
      sessionCalls++;
      await releaseSession.future;
      final status = sessionStatuses.length > 1
          ? sessionStatuses.removeAt(0)
          : sessionStatuses.first;
      if (status == 200) sessionValid = true;
      return http.Response(
        status == 200 ? jsonEncode(sessionBody) : '{}',
        status,
      );
    }
    apiRequests.add(request);
    return sessionValid
        ? http.Response('{"ok": true}', 200)
        : http.Response('{}', 401);
  });
}

void main() {
  late FakeBackend backend;
  late SessionRefresher refresher;
  late http.Client client;

  setUp(() {
    backend = FakeBackend();
    refresher = SessionRefresher(
      client: backend.client,
      baseUrl: base,
      prefetch: NoPrefetch(),
      raceRetryDelay: Duration.zero,
    );
    client = SessionInterceptor(backend.client, refresher);
  });

  test('un 401 rinnova la sessione e ripete la richiesta', () async {
    final response = await client.get(Uri.parse('$base/api/decks/'));

    expect(response.statusCode, 200);
    expect(backend.sessionCalls, 1);
    expect(backend.apiRequests, hasLength(2));
  });

  test(
    'richieste concorrenti con 401 fanno un solo rinnovo (single-flight)',
    () async {
      final responses = await Future.wait([
        client.get(Uri.parse('$base/api/decks/')),
        client.get(Uri.parse('$base/api/stats/')),
        client.get(Uri.parse('$base/api/next-card/')),
      ]);

      expect(responses.map((r) => r.statusCode), everyElement(200));
      expect(backend.sessionCalls, 1);
    },
  );

  test('una POST ripetuta mantiene il corpo', () async {
    await client.post(Uri.parse('$base/api/reviews/'), body: '{"card_id": 7}');

    expect(backend.apiRequests.map((r) => r.body), [
      '{"card_id": 7}',
      '{"card_id": 7}',
    ]);
  });

  test(
    'se il rinnovo fallisce segnala la sessione scaduta e restituisce il 401',
    () async {
      backend.sessionStatuses = [401];
      final expired = expectLater(refresher.expired, emits(null));

      final response = await client.get(Uri.parse('$base/api/decks/'));

      expect(response.statusCode, 401);
      await expired;
    },
  );

  test('le chiamate di autenticazione non vengono intercettate', () async {
    await client.post(Uri.parse('$base/api/auth/logout/'));

    expect(backend.sessionCalls, 0);
  });

  test('un 409 (gara tra schede) fa riprovare il rinnovo una volta', () async {
    backend.sessionStatuses = [409, 200];

    final response = await client.get(Uri.parse('$base/api/decks/'));

    expect(response.statusCode, 200);
    expect(backend.sessionCalls, 2);
  });

  test('il rinnovo pubblica utente e scadenze', () async {
    final update = expectLater(refresher.updates, emits(sessionBody));

    await refresher.refresh();

    await update;
  });

  test('la prima sessione usa la risposta anticipata da index.html', () async {
    refresher = SessionRefresher(
      client: backend.client,
      baseUrl: base,
      prefetch: OnePrefetch((status: 200, body: jsonEncode(sessionBody))),
    );

    final result = await refresher.refresh();

    expect(result.status, 200);
    expect(backend.sessionCalls, 0);
  });

  group('CsrfInterceptor', () {
    late List<http.BaseRequest> sent;
    late http.Client csrf;

    setUp(() {
      sent = [];
      csrf = CsrfInterceptor(
        MockClient((request) async {
          sent.add(request);
          return http.Response('{}', 200);
        }),
      );
    });

    test(
      'le GET restano senza header personalizzati (niente preflight CORS)',
      () async {
        await csrf.get(Uri.parse('$base/api/decks/'));

        expect(
          sent.single.headers.containsKey(CsrfInterceptor.header),
          isFalse,
        );
      },
    );

    test('le richieste che scrivono hanno l\'header anti-CSRF', () async {
      await csrf.post(Uri.parse('$base/api/reviews/'));
      await csrf.patch(Uri.parse('$base/api/decks/x/'));

      expect(
        sent.map((r) => r.headers[CsrfInterceptor.header]),
        everyElement(CsrfInterceptor.value),
      );
    });
  });
}
