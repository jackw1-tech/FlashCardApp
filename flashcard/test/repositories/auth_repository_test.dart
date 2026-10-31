import 'dart:async';
import 'dart:convert';

import 'package:flashcard/mappers/auth_user_mapper.dart';
import 'package:flashcard/model/app_failure.dart';
import 'package:flashcard/model/entities/auth_user.dart';
import 'package:flashcard/network/api_exception.dart';
import 'package:flashcard/network/interceptor/session_refresher.dart';
import 'package:flashcard/network/service/auth_service.dart';
import 'package:flashcard/other/constants/app_constants.dart';
import 'package:flashcard/repositories/impl/auth_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_local_store.dart';

final now = DateTime.utc(2026, 10, 22, 12);

Map<String, dynamic> sessionBody({
  String? refreshExpires = '2026-11-21T12:00:00Z',
}) => {
  'user': {'id': 1, 'username': 'giacomo'},
  'access_expires_at': '2026-10-23T12:00:00Z',
  'refresh_expires_at': refreshExpires,
};

class FakeAuthService implements AuthService {
  final updates = StreamController<Map<String, dynamic>>.broadcast(sync: true);
  final expired = StreamController<void>.broadcast(sync: true);
  SessionResult sessionResult = (
    status: 200,
    body: sessionBody(refreshExpires: null),
  );
  Object? sessionError;
  Object? loginError;
  Object? logoutError;
  int sessionCalls = 0;
  int logoutCalls = 0;

  @override
  Future<Map<String, dynamic>> login(String username, String password) async {
    if (loginError != null) throw loginError!;
    updates.add(sessionBody());
    return sessionBody();
  }

  @override
  Future<SessionResult> session() async {
    sessionCalls++;
    if (sessionError != null) throw sessionError!;
    if (sessionResult.body != null) updates.add(sessionResult.body!);
    return sessionResult;
  }

  @override
  Future<void> logout() async {
    logoutCalls++;
    if (logoutError != null) throw logoutError!;
  }

  @override
  Stream<Map<String, dynamic>> get sessionUpdates => updates.stream;

  @override
  Stream<void> get sessionExpired => expired.stream;
}

void main() {
  late FakeAuthService service;
  late FakeLocalStore store;
  late AuthRepositoryImpl repository;
  const giacomo = AuthUser(id: '1', username: 'giacomo');

  setUp(() {
    service = FakeAuthService();
    store = FakeLocalStore();
    repository = AuthRepositoryImpl(
      service: service,
      store: store,
      mapper: const AuthUserMapper(),
      apiBase: 'http://api.test',
      now: () => now,
    );
  });

  void rememberSession() => service.updates.add(sessionBody());

  test('salva l\'indirizzo dell\'API per lo script di index.html', () {
    expect(store.read(AppConstants.apiBaseKey), 'http://api.test');
  });

  test('senza una sessione salvata non chiama il server', () async {
    expect(repository.likelySessionUser(), isNull);
    expect(await repository.restoreSession(), isNull);
    expect(service.sessionCalls, 0);
  });

  test('con un refresh scaduto non chiama il server', () async {
    service.updates.add(sessionBody(refreshExpires: '2026-10-01T00:00:00Z'));

    expect(await repository.restoreSession(), isNull);
    expect(service.sessionCalls, 0);
  });

  test('con una sessione salvata la conferma col server', () async {
    rememberSession();

    expect(repository.likelySessionUser(), giacomo);
    expect(await repository.restoreSession(), giacomo);
    expect(service.sessionCalls, 1);
  });

  test('se il server rifiuta la sessione cancella i dati locali', () async {
    rememberSession();
    store.write(AppConstants.decksSnapshotKey, '{}');
    service.sessionResult = (status: 401, body: null);

    expect(await repository.restoreSession(), isNull);
    expect(store.read(AppConstants.userKey), isNull);
    expect(store.read(AppConstants.decksSnapshotKey), isNull);
    expect(store.read(AppConstants.apiBaseKey), isNotNull);
  });

  test(
    'senza rete resta dentro con l\'utente locale (non è un logout)',
    () async {
      rememberSession();
      service.sessionError = Exception('offline');

      expect(await repository.restoreSession(), giacomo);
      expect(store.read(AppConstants.userKey), isNotNull);
    },
  );

  test('l\'access si considera scaduto un minuto prima di exp', () {
    service.updates.add({
      ...sessionBody(),
      'access_expires_at': '2026-10-22T12:00:30Z',
    });
    expect(repository.likelyAccessValid(), isFalse);

    service.updates.add({
      ...sessionBody(),
      'access_expires_at': '2026-10-22T12:05:00Z',
    });
    expect(repository.likelyAccessValid(), isTrue);
  });

  test(
    'una rotazione senza refresh nuovo non cancella la scadenza del refresh',
    () {
      rememberSession();
      service.updates.add(sessionBody(refreshExpires: null));

      expect(
        store.read(AppConstants.refreshExpiresKey),
        '2026-11-21T12:00:00Z',
      );
    },
  );

  test('il login restituisce l\'utente e ricorda la sessione', () async {
    expect(await repository.login('giacomo', 'pw'), giacomo);
    expect(repository.likelySessionUser(), giacomo);
  });

  test(
    'credenziali sbagliate e troppi tentativi diventano errori di dominio',
    () async {
      service.loginError = const ApiException(401, 'no');
      expect(
        repository.login('giacomo', 'x'),
        throwsA(isA<UnauthorizedFailure>()),
      );

      service.loginError = const ApiException(429, 'troppi');
      expect(
        repository.login('giacomo', 'x'),
        throwsA(isA<TooManyAttemptsFailure>()),
      );
    },
  );

  test(
    'il logout pulisce i dati locali anche se il server non risponde',
    () async {
      rememberSession();
      service.logoutError = Exception('offline');

      await repository.logout();

      expect(repository.likelySessionUser(), isNull);
      expect(store.read(AppConstants.apiBaseKey), isNotNull);
    },
  );

  test(
    'la sessione scaduta segnalata dalla rete pulisce i dati locali',
    () async {
      rememberSession();
      final expired = repository.sessionExpired.first;

      service.expired.add(null);
      await expired;

      expect(repository.likelySessionUser(), isNull);
      expect(
        jsonEncode(store.values.keys.toList()),
        contains(AppConstants.apiBaseKey),
      );
    },
  );
}
