abstract final class AppConfig {
  /// Set at build time with `--dart-define=API_BASE_URL=...` when the API
  /// lives somewhere other than next to the page (e.g. a cPanel deployment
  /// with the API under a path prefix).
  static const String _configuredApiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
  );

  /// Without an explicit [_configuredApiBaseUrl], the API is assumed to be on
  /// port 3000 of whatever host served this page. This used to be baked in at
  /// build time as the server PC's LAN IP, and silently broke every other
  /// computer the moment DHCP gave that PC a new address (it did, 2026-10-19):
  /// the page still loaded, but every request went to the old, dead IP.
  /// Deriving it from the page's own address survives any IP or hostname.
  static final String apiBaseUrl = _configuredApiBaseUrl.isNotEmpty
      ? _configuredApiBaseUrl
      : _sameHostApiUrl(Uri.base);

  /// Visible for tests. `Uri.base` is a `file:` URI outside a browser (host
  /// empty), which falls back to the local dev default.
  static String sameHostApiUrlFor(Uri pageUri) => _sameHostApiUrl(pageUri);

  static String _sameHostApiUrl(Uri pageUri) {
    final isWebPage =
        (pageUri.scheme == 'http' || pageUri.scheme == 'https') &&
        pageUri.host.isNotEmpty;
    if (!isWebPage) return 'http://localhost:3000';
    // An IPv6 literal host comes back from Uri.host without its brackets.
    final host = pageUri.host.contains(':')
        ? '[${pageUri.host}]'
        : pageUri.host;
    return '${pageUri.scheme}://$host:3000';
  }
}
