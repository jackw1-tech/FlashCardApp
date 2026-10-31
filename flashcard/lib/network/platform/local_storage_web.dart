import 'package:web/web.dart' as web;

String? storageRead(String key) => web.window.localStorage.getItem(key);

void storageWrite(String key, String value) =>
    web.window.localStorage.setItem(key, value);

void storageRemove(String key) => web.window.localStorage.removeItem(key);

List<String> storageKeys() => [
  for (var i = 0; i < web.window.localStorage.length; i++)
    web.window.localStorage.key(i)!,
];
