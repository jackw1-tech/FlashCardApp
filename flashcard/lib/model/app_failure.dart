sealed class AppFailure implements Exception {
  final String message;

  const AppFailure(this.message);

  @override
  String toString() => message;
}

class ConfigurationFailure extends AppFailure {
  const ConfigurationFailure()
    : super(
        'Backend non configurato: avvia l\'app con --dart-define-from-file=dart_defines.env.',
      );
}

class UnauthorizedFailure extends AppFailure {
  const UnauthorizedFailure([
    super.message = 'Sessione scaduta: accedi di nuovo.',
  ]);
}

class TooManyAttemptsFailure extends AppFailure {
  const TooManyAttemptsFailure()
    : super('Troppi tentativi sbagliati. Riprova tra un minuto.');
}

class NotFoundFailure extends AppFailure {
  const NotFoundFailure(super.message);
}

class NetworkFailure extends AppFailure {
  const NetworkFailure()
    : super('Il backend non risponde. Controlla che sia acceso e riprova.');
}

class ServerFailure extends AppFailure {
  const ServerFailure(int statusCode, String detail)
    : super('Errore del backend ($statusCode): $detail');
}
