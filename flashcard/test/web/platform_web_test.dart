@TestOn('browser')
library;

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:flashcard/network/platform/local_storage.dart';
import 'package:flashcard/network/platform/prefetch.dart';
import 'package:flashcard/ui/widgets/card_markdown.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class _MissingBundle extends CachingAssetBundle {
  bool requested = false;

  @override
  Future<ByteData> load(String key) {
    requested = true;
    return Future.error(FlutterError('Asset $key non presente'));
  }
}

JSObject _response(int status, String body) => JSObject()
  ..['status'] = status.toJS
  ..['body'] = body.toJS;

void main() {
  test('localStorage: scrittura, lettura, chiavi e rimozione', () {
    storageWrite('fc.test', 'valore');

    expect(storageRead('fc.test'), 'valore');
    expect(storageKeys(), contains('fc.test'));

    storageRemove('fc.test');
    expect(storageRead('fc.test'), isNull);
  });

  test(
    'la risposta anticipata da index.html si prende una volta sola',
    () async {
      globalContext['__fcPrefetch'] = JSObject()
        ..['session'] = Future.value(_response(200, '{"ok":true}')).toJS;

      final first = await takePrefetched('session');
      final second = await takePrefetched('session');

      expect((first!.status, first.body), (200, '{"ok":true}'));
      expect(second, isNull);
    },
  );

  test('senza risposte anticipate non restituisce nulla', () async {
    globalContext.delete('__fcPrefetch'.toJS);

    expect(await takePrefetched('decks'), isNull);
  });

  testWidgets(
    'in debug non richiede il manifest creato solo dalla build release',
    (_) async {
      final bundle = _MissingBundle();

      await expectLater(loadDeferredFonts(bundle), completes);

      expect(bundle.requested, isFalse);
    },
  );
}
