import 'dart:async';

import 'package:flashcard/model/app_failure.dart';
import 'package:flashcard/model/entities/auth_user.dart';
import 'package:flashcard/repositories/auth_repository.dart';
import 'package:flashcard/state_management/cubits/auth_cubit/auth_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

const giacomo = AuthUser(id: '1', username: 'giacomo');

class FakeAuthRepository implements AuthRepository {
  AuthUser? likely;
  AuthUser? restored;
  Object? loginError;
  int restoreCalls = 0;
  final expired = StreamController<void>.broadcast(sync: true);
  final Completer<void> restoreGate = Completer()..complete();

  @override
  AuthUser? likelySessionUser() => likely;

  @override
  bool likelyAccessValid() => likely != null;

  @override
  Future<AuthUser?> restoreSession() async {
    restoreCalls++;
    await restoreGate.future;
    return restored;
  }

  @override
  Future<AuthUser> login(String username, String password) async {
    if (loginError != null) throw loginError!;
    return giacomo;
  }

  @override
  Future<void> logout() async {}

  @override
  Stream<void> get sessionExpired => expired.stream;
}

void main() {
  late FakeAuthRepository repository;
  late AuthCubit cubit;

  setUp(() {
    repository = FakeAuthRepository();
    cubit = AuthCubit(repository: repository);
  });

  tearDown(() => cubit.close());

  test('senza sessione salvata va al login subito e senza rete', () async {
    await cubit.start();

    expect(cubit.state, isA<UnauthenticatedAuthState>());
    expect(repository.restoreCalls, 0);
  });

  test(
    'con una sessione salvata mostra subito la home, poi la conferma',
    () async {
      repository
        ..likely = giacomo
        ..restored = giacomo;
      final states = <AuthState>[];
      final subscription = cubit.stream.listen(states.add);

      await cubit.start();
      await Future<void>.delayed(Duration.zero);
      await subscription.cancel();

      expect(states.map((s) => (s as AuthenticatedAuthState).verified), [
        false,
        true,
      ]);
    },
  );

  test(
    'se il server non conferma la sessione torna al login con un messaggio',
    () async {
      repository.likely = giacomo;

      await cubit.start();

      expect(
        (cubit.state as UnauthenticatedAuthState).message,
        contains('Sessione scaduta'),
      );
    },
  );

  test('una sessione scaduta durante l\'uso porta al login', () async {
    repository
      ..likely = giacomo
      ..restored = giacomo;
    await cubit.start();

    repository.expired.add(null);

    expect(cubit.state, isA<UnauthenticatedAuthState>());
  });

  test('login riuscito', () async {
    await cubit.login('  giacomo ', 'pw');

    expect((cubit.state as AuthenticatedAuthState).user, giacomo);
  });

  test(
    'credenziali sbagliate e troppi tentativi mostrano un messaggio',
    () async {
      repository.loginError = const UnauthorizedFailure();
      await cubit.login('giacomo', 'x');
      expect(
        (cubit.state as UnauthenticatedAuthState).message,
        'Username o password non validi.',
      );

      repository.loginError = const TooManyAttemptsFailure();
      await cubit.login('giacomo', 'x');
      expect(
        (cubit.state as UnauthenticatedAuthState).message,
        contains('Troppi tentativi'),
      );
    },
  );
}
