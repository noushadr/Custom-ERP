import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/app_config.dart';
import 'token_storage.dart';

/// Wraps a configured [Dio] instance that attaches the stored access token to
/// outgoing requests and transparently refreshes it once on a 401 response.
class DioClient {
  DioClient(this._tokenStorage, {@visibleForTesting Dio? refreshDio}) {
    // Without an explicit timeout, Dio waits forever on a request that never
    // gets a response (e.g. a device that can't actually reach the server on
    // its network) — the UI is left spinning with no way to tell the user
    // anything is wrong. 15s gives a slow LAN/Wi-Fi round trip room to
    // complete while still surfacing a real error otherwise.
    final timeouts = BaseOptions(
      connectTimeout: Duration(seconds: 15),
      sendTimeout: Duration(seconds: 15),
      receiveTimeout: Duration(seconds: 15),
    );
    _dio = Dio(timeouts.copyWith(baseUrl: AppConfig.apiBaseUrl));
    _refreshDio =
        refreshDio ?? Dio(timeouts.copyWith(baseUrl: AppConfig.apiBaseUrl));

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          if (!_isPublicPath(options.path)) {
            final token = await _tokenStorage.accessToken;
            if (token != null) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          final shouldRetry =
              error.response?.statusCode == 401 &&
              !_isPublicPath(error.requestOptions.path);

          if (shouldRetry && await _tryRefresh()) {
            try {
              final retried = await _dio.fetch(error.requestOptions);
              return handler.resolve(retried);
            } on DioException {
              // Fall through and surface the original error below.
            }
          }
          handler.next(error);
        },
      ),
    );
  }

  late final Dio _dio;
  late final Dio _refreshDio;
  final TokenStorage _tokenStorage;

  Dio get dio => _dio;

  bool _isPublicPath(String path) =>
      path.contains('/auth/login') || path.contains('/auth/refresh');

  /// The refresh currently in flight, if any. When the access token expires
  /// (every 15 minutes) a busy page has a dozen-plus requests in the air that
  /// all come back 401 at once; without this each one fired its own
  /// `/auth/refresh` plus a retry, a self-inflicted request storm that could
  /// trip the API's rate limit and fail the very calls it was trying to save.
  /// Every concurrent 401 now awaits this one shared refresh instead.
  Future<bool>? _refreshing;

  Future<bool> _tryRefresh() =>
      _refreshing ??= _refreshOnce().whenComplete(() => _refreshing = null);

  Future<bool> _refreshOnce() async {
    final refreshToken = await _tokenStorage.refreshToken;
    if (refreshToken == null) return false;

    try {
      final response = await _refreshDio.post<Map<String, dynamic>>(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );
      final data = response.data!;
      await _tokenStorage.saveTokens(
        accessToken: data['accessToken'] as String,
        refreshToken: data['refreshToken'] as String,
      );
      return true;
    } on DioException catch (error) {
      // Only a rejection from the server means the session is really over.
      // A network blip, timeout, rate-limit (429) or 5xx says nothing about
      // the refresh token, and wiping the saved login on one of those used
      // to sign the user out (or leave every later request failing) over a
      // momentary hiccup.
      final status = error.response?.statusCode;
      if (status == 401 || status == 403) {
        await _tokenStorage.clear();
      }
      return false;
    }
  }
}
