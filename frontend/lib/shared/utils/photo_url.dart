import '../../core/config/app_config.dart';

/// The backend returns photo/avatar paths relative to itself (e.g.
/// `/uploads/avatars/ZC-00001.jpg`) on every response that echoes back an
/// employee's `profilePhotoUrl` — not just the main employee record, but
/// every denormalized copy of it (goal/task/leave/payroll/request/review
/// employee snapshots, birthday/anniversary spotlights, announcements...).
/// Resolve it against our known API base before handing it to a
/// `NetworkImage`, or the browser can't fetch a bare relative path and the
/// avatar silently falls back to initials forever. Already-absolute URLs
/// pass through unchanged.
String? resolvePhotoUrl(String? url) {
  if (url == null || url.isEmpty) return null;
  if (url.startsWith('http://') || url.startsWith('https://')) return url;
  return '${AppConfig.apiBaseUrl}$url';
}
