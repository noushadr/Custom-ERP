import 'package:web/web.dart' as web;
import 'browser_storage.dart';

BrowserStorage createBrowserStorageImpl({required bool sessionOnly}) =>
    _WebBrowserStorage(
      sessionOnly ? web.window.sessionStorage : web.window.localStorage,
    );

/// Every call swallows storage errors (disabled storage, private browsing,
/// quota): persisting a login is a nice-to-have and must never break auth.
class _WebBrowserStorage implements BrowserStorage {
  _WebBrowserStorage(this._storage);

  final web.Storage _storage;

  @override
  String? read(String key) {
    try {
      return _storage.getItem(key);
    } catch (_) {
      return null;
    }
  }

  @override
  void write(String key, String value) {
    try {
      _storage.setItem(key, value);
    } catch (_) {}
  }

  @override
  void delete(String key) {
    try {
      _storage.removeItem(key);
    } catch (_) {}
  }
}
