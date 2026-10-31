import 'package:flashcard/model/app_failure.dart';
import 'package:flashcard/network/api_exception.dart';

mixin BaseRepositoryImpl {
  Future<T> guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on ApiException catch (error) {
      throw _toFailure(error);
    }
  }

  AppFailure _toFailure(ApiException error) => switch (error.statusCode) {
    null when error.isConfiguration => const ConfigurationFailure(),
    null => const NetworkFailure(),
    401 || 403 => const UnauthorizedFailure(),
    404 => NotFoundFailure(error.message),
    429 => const TooManyAttemptsFailure(),
    final int code => ServerFailure(code, error.message),
  };
}
