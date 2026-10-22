import 'browser_storage_stub.dart'
    if (dart.library.js_interop) 'browser_storage_web.dart'
    as impl;

/// Plain synchronous key/value storage backed by the browser's
/// `localStorage`/`sessionStorage`. [TokenStorage] falls back to this when
/// `flutter_secure_storage` can't be used - its web backend needs a "secure
/// context" (HTTPS or localhost) and throws on a plain-HTTP LAN address, which
/// is how staff reach the app, so without a fallback every page reload there
/// signed the user out. On non-web builds the stub never stores anything.
abstract interface class BrowserStorage {
  String? read(String key);
  void write(String key, String value);
  void delete(String key);
}

/// [sessionOnly] selects `sessionStorage` (survives a reload, gone when the
/// tab closes) instead of `localStorage` (survives closing the browser).
BrowserStorage createBrowserStorage({required bool sessionOnly}) =>
    impl.createBrowserStorageImpl(sessionOnly: sessionOnly);
