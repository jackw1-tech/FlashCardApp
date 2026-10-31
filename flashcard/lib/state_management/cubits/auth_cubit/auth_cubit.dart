import 'dart:async';

import 'package:flashcard/model/app_failure.dart';
import 'package:flashcard/model/entities/auth_user.dart';
import 'package:flashcard/repositories/auth_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'auth_cubit_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository repository;

  late final StreamSubscription<void> _expired;

  AuthCubit({required this.repository}) : super(const CheckingAuthState()) {
    _expired = repository.sessionExpired.listen(
      (_) => emit(
        const UnauthenticatedAuthState(
          message: 'Sessione scaduta: accedi di nuovo.',
        ),
      ),
    );
  }

  Future<void> start() async {
    final likely = repository.likelySessionUser();
    if (likely == null) {
      emit(const UnauthenticatedAuthState());
      return;
    }
    emit(AuthenticatedAuthState(likely, verified: false));
    final user = await repository.restoreSession();
    if (isClosed) return;
    emit(
      user == null
          ? const UnauthenticatedAuthState(
              message: 'Sessione scaduta: accedi di nuovo.',
            )
          : AuthenticatedAuthState(user, verified: true),
    );
  }

  Future<void> login(String username, String password) async {
    emit(const UnauthenticatedAuthState(submitting: true));
    try {
      final user = await repository.login(username.trim(), password);
      emit(AuthenticatedAuthState(user, verified: true));
    } on UnauthorizedFailure {
      emit(
        const UnauthenticatedAuthState(
          message: 'Username o password non validi.',
        ),
      );
    } on AppFailure catch (failure) {
      emit(UnauthenticatedAuthState(message: failure.message));
    }
  }

  Future<void> logout() async {
    await repository.logout();
    emit(const UnauthenticatedAuthState());
  }

  @override
  Future<void> close() {
    _expired.cancel();
    return super.close();
  }
}
