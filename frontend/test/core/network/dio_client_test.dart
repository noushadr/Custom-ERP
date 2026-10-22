import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zera_erp/core/network/dio_client.dart';
import 'package:zera_erp/core/network/token_storage.dart';

/// Scripted server: `/data` accepts only the `fresh` access token (anything
/// else is a 401, like an expired JWT), and `/auth/refresh` answers with
/// [refreshStatus] after a short delay so concurrent callers genuinely overlap.
class _FakeServer implements HttpClientAdapter {
  _FakeServer({this.refreshStatus = 200});

  final int refreshStatus;
  int refreshCalls = 0;

  ResponseBody _json(int status, Object body) => ResponseBody.fromString(
    jsonEncode(body),
    status,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.path.contains('/auth/refresh')) {
      refreshCalls++;
      await Future<void>.delayed(const Duration(milliseconds: 50));
      if (refreshStatus == 200) {
        return _json(200, {'accessToken': 'fresh', 'refreshToken': 'refresh-2'});
      }
      return _json(refreshStatus, {'message': 'nope'});
    }
    final authorized = options.headers['Authorization'] == 'Bearer fresh';
    return authorized ? _json(200, {'ok': true}) : _json(401, {});
  }

  @override
  void close({bool force = false}) {}
}

({DioClient client, TokenStorage storage, _FakeServer server}) _setup({
  int refreshStatus = 200,
}) {
  final storage = TokenStorage(const FlutterSecureStorage());
  final server = _FakeServer(refreshStatus: refreshStatus);
  final refreshDio = Dio(BaseOptions(baseUrl: 'http://test'))
    ..httpClientAdapter = server;
  final client = DioClient(storage, refreshDio: refreshDio);
  client.dio.options.baseUrl = 'http://test';
  client.dio.httpClientAdapter = server;
  return (client: client, storage: storage, server: server);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a burst of 401s shares ONE refresh and every request recovers', () async {
    final t = _setup();
    await t.storage.saveTokens(
      accessToken: 'expired',
      refreshToken: 'refresh-1',
    );

    final responses = await Future.wait([
      for (var i = 0; i < 12; i++) t.client.dio.get<Map<String, dynamic>>('/data'),
    ]);

    expect(responses.every((r) => r.statusCode == 200), isTrue);
    expect(t.server.refreshCalls, 1);
    expect(await t.storage.accessToken, 'fresh');
  });

  test('a rate-limited (429) refresh keeps the saved login', () async {
    final t = _setup(refreshStatus: 429);
    await t.storage.saveTokens(
      accessToken: 'expired',
      refreshToken: 'refresh-1',
    );

    await expectLater(
      t.client.dio.get<Map<String, dynamic>>('/data'),
      throwsA(isA<DioException>()),
    );

    expect(await t.storage.refreshToken, 'refresh-1');
  });

  test('a rejected (401) refresh token signs the session out', () async {
    final t = _setup(refreshStatus: 401);
    await t.storage.saveTokens(
      accessToken: 'expired',
      refreshToken: 'refresh-1',
    );

    await expectLater(
      t.client.dio.get<Map<String, dynamic>>('/data'),
      throwsA(isA<DioException>()),
    );

    expect(await t.storage.refreshToken, isNull);
  });

  test('a later expiry refreshes again once the first one has finished', () async {
    final t = _setup();
    await t.storage.saveTokens(
      accessToken: 'expired',
      refreshToken: 'refresh-1',
    );
    await t.client.dio.get<Map<String, dynamic>>('/data');
    expect(t.server.refreshCalls, 1);

    await t.storage.saveTokens(
      accessToken: 'expired-again',
      refreshToken: 'refresh-2',
    );
    final response = await t.client.dio.get<Map<String, dynamic>>('/data');

    expect(response.statusCode, 200);
    expect(t.server.refreshCalls, 2);
  });
}
