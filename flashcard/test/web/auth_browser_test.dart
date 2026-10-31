@TestOn('browser')
library;

import 'dart:async';
import 'dart:convert';

import 'package:flashcard/model/entities/app_settings.dart';
import 'package:flashcard/model/entities/auth_user.dart';
import 'package:flashcard/network/interceptor/session_refresher.dart';
import 'package:flashcard/network/platform/local_storage.dart';
import 'package:flashcard/network/service/prefetch_service.dart';
import 'package:flashcard/repositories/auth_repository.dart';
import 'package:flashcard/repositories/deck_repository.dart';
import 'package:flashcard/repositories/settings_repository.dart';
import 'package:flashcard/state_management/cubits/auth_cubit/auth_cubit.dart';
import 'package:flashcard/state_management/cubits/decks_cubit/decks_cubit.dart';
import 'package:flashcard/state_management/cubits/settings_cubit/settings_cubit.dart';
import 'package:flashcard/theme/app_theme.dart';
import 'package:flashcard/ui/pages/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

class _AuthRepository implements AuthRepository {
  final _expired = StreamController<void>.broadcast();
  bool loggedOut = false;

  @override
  Stream<void> get sessionExpired => _expired.stream;

  @override
  bool likelyAccessValid() => true;

  @override
  AuthUser? likelySessionUser() => const AuthUser(id: '1', username: 'giacomo');

  @override
  Future<AuthUser> login(String username, String password) async =>
      const AuthUser(id: '1', username: 'giacomo');

  @override
  Future<void> logout() async {
    loggedOut = true;
    storageRemove('fc.user');
  }

  @override
  Future<AuthUser?> restoreSession() async => likelySessionUser();

  Future<void> close() => _expired.close();
}

class _SettingsRepository implements SettingsRepository {
  @override
  Future<AppSettings> load() async => const AppSettings();

  @override
  Future<void> save(AppSettings settings) async {}
}

class _DeckRepository implements DeckRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _NoPrefetch implements PrefetchService {
  @override
  Future<PrefetchedResponse?> take(String name) async => null;
}

class _TwoTabClient extends http.BaseClient {
  int calls = 0;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final call = ++calls;
    await Future<void>.delayed(Duration.zero);
    final status = call == 2 ? 409 : 200;
    final body = status == 200
        ? jsonEncode({
            'user': {'id': '1', 'username': 'giacomo'},
            'access_expires_at': '2026-10-26T12:00:00Z',
            'refresh_expires_at': '2026-11-02T12:00:00Z',
          })
        : '{}';
    return http.StreamedResponse(
      Stream.value(utf8.encode(body)),
      status,
      request: request,
    );
  }
}

void main() {
  testWidgets('logout reale dalla schermata Impostazioni pulisce la sessione', (
    tester,
  ) async {
    storageWrite('fc.user', '{"id":"1","username":"giacomo"}');
    final authRepository = _AuthRepository();
    final authCubit = AuthCubit(repository: authRepository);
    await authCubit.start();
    final deckRepository = _DeckRepository();

    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<DeckRepository>.value(value: deckRepository),
        ],
        child: MultiBlocProvider(
          providers: [
            BlocProvider.value(value: authCubit),
            BlocProvider(
              create: (_) => SettingsCubit(repository: _SettingsRepository()),
            ),
            BlocProvider(create: (_) => DecksCubit(repository: deckRepository)),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const SettingsPage(),
          ),
        ),
      ),
    );

    expect(find.text('giacomo'), findsOneWidget);
    await tester.tap(find.text('Esci'));
    await tester.pump();

    expect(authRepository.loggedOut, isTrue);
    expect(storageRead('fc.user'), isNull);
    expect(authCubit.state, isA<UnauthenticatedAuthState>());

    await authCubit.close();
    await authRepository.close();
  });

  test('due schede concorrenti recuperano la rotazione del refresh', () async {
    final client = _TwoTabClient();
    final firstTab = SessionRefresher(
      client: client,
      baseUrl: 'https://flashcard.test',
      prefetch: _NoPrefetch(),
      raceRetryDelay: Duration.zero,
    );
    final secondTab = SessionRefresher(
      client: client,
      baseUrl: 'https://flashcard.test',
      prefetch: _NoPrefetch(),
      raceRetryDelay: Duration.zero,
    );

    final results = await Future.wait([
      firstTab.refresh(),
      secondTab.refresh(),
    ]);

    expect(results.map((result) => result.status), everyElement(200));
    expect(results.map((result) => result.body?['user']['username']), [
      'giacomo',
      'giacomo',
    ]);
    expect(client.calls, 3);
  });
}
