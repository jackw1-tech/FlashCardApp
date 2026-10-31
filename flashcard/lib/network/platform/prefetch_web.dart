import 'dart:js_interop';
import 'dart:js_interop_unsafe';

@JS('__fcPrefetch')
external JSObject? get _prefetch;

Future<({int status, String body})?> takePrefetched(String name) async {
  final prefetch = _prefetch;
  if (prefetch == null || !prefetch.hasProperty(name.toJS).toDart) return null;
  final promise = prefetch.getProperty<JSPromise<JSObject>?>(name.toJS);
  prefetch.delete(name.toJS);
  if (promise == null) return null;
  try {
    final result = await promise.toDart;
    return (
      status: result.getProperty<JSNumber>('status'.toJS).toDartInt,
      body: result.getProperty<JSString>('body'.toJS).toDart,
    );
  } catch (_) {
    return null;
  }
}
