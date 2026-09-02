import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/storage/announcement_dismissal_storage.dart';
import '../../core/theme/app_colors.dart';
import '../../features/announcements/application/announcement_providers.dart';
import '../../features/announcements/domain/entities/today_announcements.dart';
import '../../features/authentication/application/auth_providers.dart';

const _rotateInterval = Duration(seconds: 6);

class _BannerItem {
  const _BannerItem({
    required this.icon,
    required this.color,
    required this.text,
  });

  final IconData icon;
  final Color color;
  final String text;
}

final _dismissalStorageProvider = Provider<AnnouncementDismissalStorage>(
  (ref) => AnnouncementDismissalStorage(ref.watch(secureStorageProvider)),
);

/// Slim, dismissible strip shown right under the top bar on every page —
/// rotates through today's birthdays, work anniversaries, public holidays,
/// and freshly-posted company notices. Visible to every employee, not just
/// HR/Admin (unlike the notification bell's "Celebrations" section).
class AnnouncementBanner extends ConsumerStatefulWidget {
  const AnnouncementBanner({super.key});

  @override
  ConsumerState<AnnouncementBanner> createState() =>
      _AnnouncementBannerState();
}

class _AnnouncementBannerState extends ConsumerState<AnnouncementBanner> {
  int _index = 0;
  int _itemCount = 0;
  Timer? _timer;
  bool _dismissedForToday = false;
  bool _checkedDismissal = false;

  @override
  void initState() {
    super.initState();
    ref.read(_dismissalStorageProvider).isDismissedForToday().then((
      dismissed,
    ) {
      if (!mounted) return;
      setState(() {
        _dismissedForToday = dismissed;
        _checkedDismissal = true;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startRotating(int itemCount) {
    _timer?.cancel();
    if (itemCount <= 1) return;
    _timer = Timer.periodic(_rotateInterval, (_) {
      if (!mounted) return;
      setState(() => _index = (_index + 1) % itemCount);
    });
  }

  Future<void> _dismiss() async {
    setState(() => _dismissedForToday = true);
    await ref.read(_dismissalStorageProvider).dismissForToday();
  }

  List<_BannerItem> _buildItems(TodayAnnouncements data) {
    final items = <_BannerItem>[];

    if (data.holiday != null) {
      items.add(
        _BannerItem(
          icon: Icons.festival_outlined,
          color: AppColors.warning,
          text: 'Happy ${data.holiday!.name}! 🎆',
        ),
      );
    }
    for (final birthday in data.birthdays) {
      items.add(
        _BannerItem(
          icon: Icons.cake_outlined,
          color: AppColors.secondary,
          text: 'Happy Birthday, ${birthday.fullName}! 🎉',
        ),
      );
    }
    for (final anniversary in data.workAnniversaries) {
      items.add(
        _BannerItem(
          icon: Icons.celebration_outlined,
          color: AppColors.accentTeal,
          text:
              'Happy ${anniversary.yearsOfService}-Year Anniversary, '
              '${anniversary.fullName}! 🎊',
        ),
      );
    }
    for (final notice in data.notices) {
      items.add(
        _BannerItem(
          icon: Icons.campaign_outlined,
          color: AppColors.primary,
          text: 'New announcement: "${notice.title}" — please check 📢',
        ),
      );
    }

    return items;
  }

  @override
  Widget build(BuildContext context) {
    if (!_checkedDismissal || _dismissedForToday) return const SizedBox.shrink();

    final asyncData = ref.watch(todayAnnouncementsProvider);
    final data = asyncData.valueOrNull;
    if (data == null || data.isEmpty) return const SizedBox.shrink();

    final items = _buildItems(data);
    if (items.isEmpty) return const SizedBox.shrink();

    if (_index >= items.length) _index = 0;
    // Only (re)start the rotation timer when the item count actually
    // changes — not on every rebuild, which includes the ones the timer's
    // own setState causes each tick.
    if (items.length != _itemCount) {
      _itemCount = items.length;
      _startRotating(items.length);
    }

    final item = items[_index];

    return Container(
      width: double.infinity,
      color: item.color.withValues(alpha: 0.12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(item.icon, size: 16, color: item.color),
          const SizedBox(width: 8),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                item.text,
                key: ValueKey(item.text),
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: item.color),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          if (items.length > 1) ...[
            const SizedBox(width: 8),
            for (var i = 0; i < items.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i == _index
                        ? item.color
                        : item.color.withValues(alpha: 0.3),
                  ),
                ),
              ),
          ],
          const SizedBox(width: 8),
          InkWell(
            onTap: _dismiss,
            borderRadius: BorderRadius.circular(12),
            child: Icon(Icons.close, size: 16, color: item.color),
          ),
        ],
      ),
    );
  }
}
