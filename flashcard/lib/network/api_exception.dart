class ApiException implements Exception {
  final int? statusCode;
  final String message;

  const ApiException(this.statusCode, this.message);

  const ApiException.network(this.message) : statusCode = null;

  const ApiException.configuration()
    : statusCode = null,
      message = 'configurazione mancante';

  bool get isConfiguration =>
      statusCode == null && message == 'configurazione mancante';

  @override
  String toString() => 'ApiException($statusCode, $message)';
}
