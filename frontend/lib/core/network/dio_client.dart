import 'package:dio/dio.dart';
import '../config/app_config.dart';
import 'token_storage.dart';

/// Wraps a configured [Dio] instance that attaches the stored access token to
/// outgoing requests and transparently refreshes it once on a 401 response.
class DioClient {
  DioClient(this._tokenStorage) {
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
    _refreshDio = Dio(timeouts.copyWith(baseUrl: AppConfig.apiBaseUrl));

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

  Future<bool> _tryRefresh() async {
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
    } on DioException {
      await _tokenStorage.clear();
      return false;
    }
  }
}
