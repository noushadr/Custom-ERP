import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Holds the current session's tokens in memory for the lifetime of the app,
/// and mirrors them to persistent secure storage only when the session
/// should survive a restart (`rememberMe`). This way a "not remembered"
/// session still works normally (API calls, silent refresh) until the app
/// closes, but a fresh launch afterwards finds nothing to restore.
class TokenStorage {
  TokenStorage(this._storage);

  final FlutterSecureStorage _storage;

  static const _accessTokenKey = 'auth_access_token';
  static const _refreshTokenKey = 'auth_refresh_token';

  String? _inMemoryAccessToken;
  String? _inMemoryRefreshToken;
  bool _rememberMe = true;

  // Holds the admin's own session while impersonating another user, so
  // "Return to admin" can restore it without asking them to log in again.
  // In-memory only — deliberately doesn't survive an app restart, so a
  // killed impersonation session always requires a fresh, explicit login.
  String? _stashedAccessToken;
  String? _stashedRefreshToken;
  bool? _stashedRememberMe;

  bool get hasStashedSession => _stashedAccessToken != null;

  void stashCurrentSession() {
    _stashedAccessToken = _inMemoryAccessToken;
    _stashedRefreshToken = _inMemoryRefreshToken;
    _stashedRememberMe = _rememberMe;
  }

  Future<void> restoreStashedSession() async {
    final accessToken = _stashedAccessToken;
    final refreshToken = _stashedRefreshToken;
    final rememberMe = _stashedRememberMe;
    _stashedAccessToken = null;
    _stashedRefreshToken = null;
    _stashedRememberMe = null;
    if (accessToken == null || refreshToken == null) return;
    await saveTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
      rememberMe: rememberMe,
    );
  }

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    bool? rememberMe,
  }) async {
    if (rememberMe != null) _rememberMe = rememberMe;
    _inMemoryAccessToken = accessToken;
    _inMemoryRefreshToken = refreshToken;

    if (_rememberMe) {
      await _storage.write(key: _accessTokenKey, value: accessToken);
      await _storage.write(key: _refreshTokenKey, value: refreshToken);
    } else {
      await _storage.delete(key: _accessTokenKey);
      await _storage.delete(key: _refreshTokenKey);
    }
  }

  Future<String?> get accessToken async =>
      _inMemoryAccessToken ?? await _storage.read(key: _accessTokenKey);

  Future<String?> get refreshToken async =>
      _inMemoryRefreshToken ?? await _storage.read(key: _refreshTokenKey);

  Future<void> clear() async {
    _inMemoryAccessToken = null;
    _inMemoryRefreshToken = null;
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }
}
