import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'browser_storage.dart';

/// Holds the current session's tokens in memory for the lifetime of the app,
/// and mirrors them to persistent secure storage only when the session
/// should survive a restart (`rememberMe`). This way a "not remembered"
/// session still works normally (API calls, silent refresh) until the app
/// closes, but a fresh launch afterwards finds nothing to restore.
class TokenStorage {
  TokenStorage(
    this._storage, {
    BrowserStorage? persistentFallback,
    BrowserStorage? sessionFallback,
  }) : _persistentFallback =
           persistentFallback ?? createBrowserStorage(sessionOnly: false),
       _sessionFallback =
           sessionFallback ?? createBrowserStorage(sessionOnly: true);

  final FlutterSecureStorage _storage;

  /// Used when secure storage is unavailable (plain-HTTP LAN address) so a
  /// remembered login still survives a reload / closing the browser.
  final BrowserStorage _persistentFallback;

  /// Where a "don't remember me" login lives: survives a page reload (so
  /// being signed in really does last the working day) but is gone when the
  /// tab closes.
  final BrowserStorage _sessionFallback;

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

    // Persisting is a nice-to-have (survives a page refresh/app restart) —
    // the in-memory copies above already make the session usable for the
    // rest of this run, so a storage failure here must never block login or
    // leave the caller waiting on a broken write.
    //
    //  - Remembered: secure storage; if that's unavailable (flutter_secure_
    //    storage's web backend needs a "secure context" — HTTPS or localhost —
    //    and throws over a plain-HTTP LAN address) plain localStorage instead.
    //  - Not remembered: sessionStorage only, so a reload doesn't sign the
    //    user out but closing the tab does.
    if (_rememberMe) {
      final secureOk = await _trySecure(() async {
        await _storage.write(key: _accessTokenKey, value: accessToken);
        await _storage.write(key: _refreshTokenKey, value: refreshToken);
      });
      if (secureOk) {
        _deleteFrom(_persistentFallback);
      } else {
        _persistentFallback.write(_accessTokenKey, accessToken);
        _persistentFallback.write(_refreshTokenKey, refreshToken);
      }
      _deleteFrom(_sessionFallback);
    } else {
      await _trySecure(() async {
        await _storage.delete(key: _accessTokenKey);
        await _storage.delete(key: _refreshTokenKey);
      });
      _deleteFrom(_persistentFallback);
      _sessionFallback.write(_accessTokenKey, accessToken);
      _sessionFallback.write(_refreshTokenKey, refreshToken);
    }
  }

  Future<String?> get accessToken async =>
      _inMemoryAccessToken ?? await _readPersisted(_accessTokenKey);

  Future<String?> get refreshToken async =>
      _inMemoryRefreshToken ?? await _readPersisted(_refreshTokenKey);

  /// Secure storage first, then the browser fallbacks — no persisted token
  /// anywhere is indistinguishable from "storage isn't available here" as
  /// far as the caller needs to know: both just mean start signed out
  /// instead of leaving `restoreSession` hanging on a broken read.
  Future<String?> _readPersisted(String key) async {
    try {
      final secure = await _storage.read(key: key);
      if (secure != null) return secure;
    } catch (_) {
      // Fall through to the browser fallbacks.
    }
    return _persistentFallback.read(key) ?? _sessionFallback.read(key);
  }

  /// Runs a secure-storage operation, reporting whether it worked.
  Future<bool> _trySecure(Future<void> Function() operation) async {
    try {
      await operation();
      return true;
    } catch (_) {
      return false;
    }
  }

  void _deleteFrom(BrowserStorage storage) {
    storage.delete(_accessTokenKey);
    storage.delete(_refreshTokenKey);
  }

  Future<void> clear() async {
    _inMemoryAccessToken = null;
    _inMemoryRefreshToken = null;
    // Already cleared in memory, which is what actually gates auth state —
    // a failure to wipe the persisted copies mustn't surface as an error.
    await _trySecure(() async {
      await _storage.delete(key: _accessTokenKey);
      await _storage.delete(key: _refreshTokenKey);
    });
    _deleteFrom(_persistentFallback);
    _deleteFrom(_sessionFallback);
  }
}
