import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../features/announcements/application/announcement_providers.dart';
import '../../features/announcements/domain/entities/today_announcements.dart';

/// The wording of a work-from-home day, shared by the top-bar banner and the
/// dashboards so they always say the same thing.
List<String> workFromHomeMessages(TodayWorkFromHome? wfh) {
  if (wfh == null) return const [];
  String line(String when, TodayWfhNotice notice) {
    final what = notice.personal
        ? (when == 'Today'
              ? "You're working from home today"
              : "You're working from home tomorrow")
        : '$when is a work-from-home day';
    return notice.note == null || notice.note!.isEmpty
        ? what
        : '$what — ${notice.note}';
  }

  return [
    if (wfh.today != null) line('Today', wfh.today!),
    if (wfh.tomorrow != null) line('Tomorrow', wfh.tomorrow!),
  ];
}

/// A card at the top of a dashboard telling the viewer about a work-from-home
/// day (today or tomorrow, company-wide or their own). Nothing when there is
/// none, while loading, or on any error.
class WorkFromHomeNotice extends ConsumerWidget {
  const WorkFromHomeNotice({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messages = workFromHomeMessages(
      ref.watch(todayAnnouncementsProvider).valueOrNull?.workFromHome,
    );
    if (messages.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        key: const Key('work-from-home-notice'),
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.home_work_outlined, color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final message in messages)
                    Text(
                      message,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
