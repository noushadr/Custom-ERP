import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zera_erp/core/network/token_storage.dart';
import 'package:zera_erp/features/authentication/data/datasources/auth_remote_data_source.dart';
import 'package:zera_erp/features/authentication/data/repositories/auth_repository_impl.dart';

/// Answers `/auth/me` with the next status in [statuses] (200 = a valid user).
class _MeAdapter implements HttpClientAdapter {
  _MeAdapter(this.statuses);

  final List<int> statuses;
  int calls = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final status =
        statuses[calls < statuses.length ? calls : statuses.length - 1];
    calls++;
    final body = status == 200
        ? jsonEncode({
            'id': 'u1',
            'email': 'hr@zeracreative.com',
            'role': 'HR/Manager',
            'permissions': <String>[],
          })
        : jsonEncode({'message': 'x'});
    return ResponseBody.fromString(
      body,
      status,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Future<({AuthRepositoryImpl repo, TokenStorage storage, _MeAdapter adapter})>
_setup(List<int> statuses) async {
  final storage = TokenStorage(const FlutterSecureStorage());
  await storage.saveTokens(accessToken: 'a', refreshToken: 'r');
  final adapter = _MeAdapter(statuses);
  final dio = Dio(BaseOptions(baseUrl: 'http://test'))
    ..httpClientAdapter = adapter;
  final repo = AuthRepositoryImpl(
    AuthRemoteDataSource(dio),
    storage,
    restoreRetryDelays: const [Duration.zero, Duration.zero],
  );
  return (repo: repo, storage: storage, adapter: adapter);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a transient server error is retried and the session is kept', () async {
    final t = await _setup([503, 429, 200]);

    final user = await t.repo.getCurrentUser();

    expect(user, isNotNull);
    expect(t.adapter.calls, 3);
    expect(await t.storage.accessToken, 'a');
  });

  test('if the server stays unreachable the login is NOT wiped', () async {
    final t = await _setup([503]);

    final user = await t.repo.getCurrentUser();

    expect(user, isNull);
    expect(await t.storage.accessToken, 'a');
    expect(await t.storage.refreshToken, 'r');
  });

  test(
    'a 401 means the session is over and the saved login is cleared',
    () async {
      final t = await _setup([401]);

      final user = await t.repo.getCurrentUser();

      expect(user, isNull);
      expect(await t.storage.accessToken, isNull);
    },
  );
}
