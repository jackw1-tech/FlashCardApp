part of 'auth_cubit.dart';

sealed class AuthState {
  const AuthState();
}

class CheckingAuthState extends AuthState {
  const CheckingAuthState();
}

class AuthenticatedAuthState extends AuthState {
  final AuthUser user;

  final bool verified;

  const AuthenticatedAuthState(this.user, {required this.verified});
}

class UnauthenticatedAuthState extends AuthState {
  final String? message;
  final bool submitting;

  const UnauthenticatedAuthState({this.message, this.submitting = false});
}
