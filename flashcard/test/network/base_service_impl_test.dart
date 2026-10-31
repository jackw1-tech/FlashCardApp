import 'package:flashcard/network/api_exception.dart';
import 'package:flashcard/network/service/impl/base_service_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class _Service extends BaseServiceImpl {
  _Service(http.Client client)
    : super(client: client, baseUrl: 'https://flashcard.test');

  Future<Map<String, dynamic>> request() => postJson('/api/sessions/', {
    'review_ids': [1],
  });
}

void main() {
  test('una risposta HTML diventa un errore API leggibile', () async {
    final service = _Service(
      MockClient(
        (_) async => http.Response(
          '<!DOCTYPE html><title>Not found</title>',
          404,
          headers: {'content-type': 'text/html'},
        ),
      ),
    );

    await expectLater(
      service.request(),
      throwsA(
        isA<ApiException>()
            .having((error) => error.statusCode, 'status', 404)
            .having(
              (error) => error.message,
              'message',
              isNot(contains('<!DOCTYPE')),
            ),
      ),
    );
  });
}
