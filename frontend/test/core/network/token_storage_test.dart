import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zera_erp/core/network/browser_storage.dart';
import 'package:zera_erp/core/network/token_storage.dart';

/// Stand-in for FlutterSecureStorage. With [available] false every call
/// fails, like its web backend does outside a secure context (a plain-HTTP
/// LAN address).
class _FakeSecureStorage implements FlutterSecureStorage {
  _FakeSecureStorage({this.available = true});

  bool available;
  final Map<String, String> data = {};

  @override
  dynamic noSuchMethod(Invocation invocation) {
    final key = invocation.namedArguments[#key] as String?;
    switch (invocation.memberName) {
      case #read:
        return available
            ? Future<String?>.value(data[key])
            : Future<String?>.error(StateError('insecure context'));
      case #write:
        if (!available) return Future<void>.error(StateError('insecure'));
        data[key!] = invocation.namedArguments[#value] as String;
        return Future<void>.value();
      case #delete:
        if (!available) return Future<void>.error(StateError('insecure'));
        data.remove(key);
        return Future<void>.value();
    }
    return super.noSuchMethod(invocation);
  }
}

class _FakeBrowserStorage implements BrowserStorage {
  final Map<String, String> data = {};

  @override
  String? read(String key) => data[key];

  @override
  void write(String key, String value) => data[key] = value;

  @override
  void delete(String key) => data.remove(key);
}

class _Env {
  _Env({bool secureAvailable = true})
    : secure = _FakeSecureStorage(available: secureAvailable);

  final _FakeSecureStorage secure;
  final local = _FakeBrowserStorage();
  final session = _FakeBrowserStorage();

  /// A brand-new TokenStorage over the same underlying stores - what a page
  /// reload produces (in-memory tokens gone, persisted ones still there).
  TokenStorage reload() => TokenStorage(
    secure,
    persistentFallback: local,
    sessionFallback: session,
  );
}

void main() {
  test('a remembered login survives a reload when secure storage is unavailable '
      '(plain-HTTP LAN address)', () async {
    final env = _Env(secureAvailable: false);
    await env.reload().saveTokens(
      accessToken: 'access',
      refreshToken: 'refresh',
      rememberMe: true,
    );

    final afterReload = env.reload();
    expect(await afterReload.accessToken, 'access');
    expect(await afterReload.refreshToken, 'refresh');
  });

  test('with secure storage available the browser fallback is not used', () async {
    final env = _Env();
    await env.reload().saveTokens(
      accessToken: 'access',
      refreshToken: 'refresh',
      rememberMe: true,
    );

    expect(env.secure.data['auth_refresh_token'], 'refresh');
    expect(env.local.data, isEmpty);
    expect(await env.reload().refreshToken, 'refresh');
  });

  test('an un-remembered login survives a reload but only in session storage',
      () async {
    final env = _Env();
    await env.reload().saveTokens(
      accessToken: 'access',
      refreshToken: 'refresh',
      rememberMe: false,
    );

    expect(env.secure.data, isEmpty);
    expect(env.local.data, isEmpty);
    expect(env.session.data['auth_refresh_token'], 'refresh');
    // Same tab reloaded: still signed in.
    expect(await env.reload().refreshToken, 'refresh');
  });

  test('switching from remembered to not-remembered removes the persistent copy',
      () async {
    final env = _Env(secureAvailable: false);
    final storage = env.reload();
    await storage.saveTokens(
      accessToken: 'a1',
      refreshToken: 'r1',
      rememberMe: true,
    );
    expect(env.local.data, isNotEmpty);

    await storage.saveTokens(
      accessToken: 'a2',
      refreshToken: 'r2',
      rememberMe: false,
    );

    expect(env.local.data, isEmpty);
    expect(env.session.data['auth_refresh_token'], 'r2');
  });

  test('clear() signs out everywhere, including the browser fallbacks', () async {
    final env = _Env(secureAvailable: false);
    final storage = env.reload();
    await storage.saveTokens(
      accessToken: 'access',
      refreshToken: 'refresh',
      rememberMe: true,
    );
    await storage.saveTokens(
      accessToken: 'access',
      refreshToken: 'refresh',
      rememberMe: false,
    );

    await storage.clear();

    final afterReload = env.reload();
    expect(await afterReload.accessToken, isNull);
    expect(await afterReload.refreshToken, isNull);
    expect(env.local.data, isEmpty);
    expect(env.session.data, isEmpty);
  });

  test('a token refresh (saveTokens without rememberMe) keeps the earlier choice',
      () async {
    final env = _Env(secureAvailable: false);
    final storage = env.reload();
    await storage.saveTokens(
      accessToken: 'a1',
      refreshToken: 'r1',
      rememberMe: true,
    );

    // What the silent refresh does: new tokens, no rememberMe argument.
    await storage.saveTokens(accessToken: 'a2', refreshToken: 'r2');

    expect(env.local.data['auth_refresh_token'], 'r2');
    expect(await env.reload().accessToken, 'a2');
  });
}
