import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Remembers that the viewer dismissed the top-bar announcement banner for
/// the current calendar day, so it doesn't reappear on every page visit —
/// but does reappear tomorrow if something's still relevant then. Per
/// browser/device (not synced), same as every other locally-stored UI
/// preference in this app.
class AnnouncementDismissalStorage {
  AnnouncementDismissalStorage(this._storage);

  final FlutterSecureStorage _storage;

  static const _dismissedDateKey = 'announcement_banner_dismissed_date';

  Future<bool> isDismissedForToday() async {
    final stored = await _storage.read(key: _dismissedDateKey);
    return stored == _todayKey();
  }

  Future<void> dismissForToday() =>
      _storage.write(key: _dismissedDateKey, value: _todayKey());

  String _todayKey() {
    final now = DateTime.now();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    return '${now.year}-$month-$day';
  }
}
