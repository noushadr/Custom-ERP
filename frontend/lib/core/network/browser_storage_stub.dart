import 'browser_storage.dart';

BrowserStorage createBrowserStorageImpl({required bool sessionOnly}) =>
    _NoBrowserStorage();

class _NoBrowserStorage implements BrowserStorage {
  @override
  String? read(String key) => null;

  @override
  void write(String key, String value) {}

  @override
  void delete(String key) {}
}
