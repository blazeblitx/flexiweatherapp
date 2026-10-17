import 'dart:js_interop';

const _choiceKey = 'flexiweather_storage_consent';

@JS('window.localStorage')
external JSObject get _localStorage;

@JS()
extension type _Storage(JSObject _) implements JSObject {
  external JSString? getItem(JSString key);
  external void setItem(JSString key, JSString value);
}

String? readWebStorageChoice() =>
    _Storage(_localStorage).getItem(_choiceKey.toJS)?.toDart;

void writeWebStorageChoice(bool allowed) {
  _Storage(_localStorage)
      .setItem(_choiceKey.toJS, (allowed ? 'allow' : 'decline').toJS);
}
