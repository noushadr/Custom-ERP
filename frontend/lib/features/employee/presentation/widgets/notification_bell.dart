import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/utils/date_format.dart';
import '../../../authentication/application/auth_providers.dart';
import '../../../authentication/application/auth_state.dart';
import '../../../leave/application/leave_providers.dart';
import '../../../leave/domain/entities/leave_request.dart';
import '../../../notices/application/notice_providers.dart';
import '../../../requests/application/request_providers.dart';
import '../../../requests/domain/entities/employee_request.dart';
import '../../application/employee_providers.dart';
import '../../domain/entities/upcoming_birthday.dart';
import '../../domain/entities/upcoming_work_anniversary.dart';

const _panelWidth = 320.0;

/// Where tapping a section-level notification should take the viewer.
enum NotificationLinkTarget { adminDashboard, userDashboard, leavePage }

/// Tapping a birthday or work-anniversary item opens that employee's own
/// profile rather than just a generic destination.
class _OpenEmployeeProfile {
  const _OpenEmployeeProfile(this.employeeId);
  final String employeeId;
}

/// Tapping a notice both navigates to the dashboard it lives on and tells
/// CompanyNoticesSection which specific notice to jump to — pagination means
/// page 1 alone wouldn't necessarily show it.
class _FocusNotice {
  const _FocusNotice(this.noticeId, this.target);
  final String noticeId;
  final NotificationLinkTarget target;
}

// How many past (already-decided) items to keep per history list — a record
// of what happened, not just what's still pending, but bounded so the list
// doesn't grow forever for a long-tenured employee. Unlike the old 7-day
// cutoff this never hides something just because time passed.
const _maxDecidedHistory = 10;

// Company notices have no targeting/read state, so every viewer sees the
// same feed — capped to the most recent few so the bell isn't dominated by
// old announcements.
const _maxNoticeHistory = 5;

/// Bell + dropdown shown in the top bar, next to the account menu — mirrors
/// how most SaaS/social apps surface notifications rather than giving them
/// their own nav destination. Combines birthday and work-anniversary
/// reminders (Super Admin/HR-Manager only, recently-passed or upcoming,
/// active employees only), company notices, requests/leave awaiting the
/// viewer's approval, a leave-balance-reset reminder (Super Admin/HR only),
/// and the viewer's own recently-decided requests/leave — grouped under
/// category labels, with every notification's full text readable (no
/// truncation) rather than clipped to a single ellipsized line.
class NotificationBell extends ConsumerWidget {
  const NotificationBell({
    super.key,
    required this.onNavigate,
    required this.onOpenEmployeeProfile,
  });

  final ValueChanged<NotificationLinkTarget> onNavigate;

  /// Called with an employeeId when the viewer taps a birthday or
  /// work-anniversary notification.
  final ValueChanged<String> onOpenEmployeeProfile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final authUser = authState is AuthAuthenticated ? authState.user : null;
    final canSeeBirthdays =
        authUser?.hasPermission('employees.manage') ?? false;
    final canSeeHrApprovals = authUser?.hasPermission('users.manage') ?? false;
    final canManageLeave = authUser?.hasPermission('leave.manage') ?? false;
    final seesAdminDashboard =
        authUser?.role == 'Super Admin' || authUser?.role == 'HR/Manager';
    final noticeTarget = seesAdminDashboard
        ? NotificationLinkTarget.adminDashboard
        : NotificationLinkTarget.userDashboard;

    final birthdays = canSeeBirthdays
        ? ref.watch(upcomingBirthdaysProvider).valueOrNull ?? const []
        : const <UpcomingBirthday>[];
    final anniversaries = canSeeBirthdays
        ? ref.watch(upcomingWorkAnniversariesProvider).valueOrNull ?? const []
        : const <UpcomingWorkAnniversary>[];
    // No targeting/permission on notices — every authenticated viewer sees
    // the same feed, so no gate here.
    final recentNotices =
        (ref.watch(noticeListProvider).valueOrNull ?? const [])
            .take(_maxNoticeHistory)
            .toList();
    final hrApprovals = canSeeHrApprovals
        ? ref.watch(pendingHrApprovalRequestsProvider).valueOrNull ?? const []
        : const <EmployeeRequest>[];
    // No permission guard on the backend for this one — safe for everyone,
    // and naturally empty for anyone who isn't a reporting manager.
    final managerApprovals =
        ref.watch(pendingManagerApprovalRequestsProvider).valueOrNull ??
        const <EmployeeRequest>[];

    final leaveHrApprovals = canManageLeave
        ? ref.watch(pendingHrApprovalLeaveRequestsProvider).valueOrNull ??
              const []
        : const <LeaveRequest>[];
    final leaveManagerApprovals =
        ref.watch(pendingManagerApprovalLeaveRequestsProvider).valueOrNull ??
        const <LeaveRequest>[];
    final resetStatus = canManageLeave
        ? ref.watch(leaveResetStatusProvider).valueOrNull
        : null;
    final needsLeaveReset = resetStatus != null && !resetStatus.isInitialized;

    final myRecentLeaveDecisions = _recentlyDecided(
      ref.watch(myLeaveRequestsProvider).valueOrNull ?? const [],
      isDecided: (r) => r.status == 'approved' || r.status == 'rejected',
      decidedAt: (r) => r.hrDecisionAt ?? r.managerDecisionAt,
    );
    final myRecentRequestDecisions = _recentlyDecided(
      ref.watch(myRequestsProvider).valueOrNull ?? const [],
      isDecided: (r) => r.status == 'completed' || r.status == 'rejected',
      decidedAt: (r) => r.hrDecisionAt ?? r.managerDecisionAt,
    );

    final totalCount =
        birthdays.length +
        anniversaries.length +
        recentNotices.length +
        hrApprovals.length +
        managerApprovals.length +
        leaveHrApprovals.length +
        leaveManagerApprovals.length +
        myRecentLeaveDecisions.length +
        myRecentRequestDecisions.length +
        (needsLeaveReset ? 1 : 0);

    return PopupMenuButton<Object>(
      tooltip: 'Notifications',
      offset: const Offset(0, 44),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      constraints: const BoxConstraints(maxHeight: 480),
      onSelected: (value) {
        switch (value) {
          case NotificationLinkTarget target:
            onNavigate(target);
          case _OpenEmployeeProfile(:final employeeId):
            onOpenEmployeeProfile(employeeId);
          case _FocusNotice(:final noticeId, :final target):
            ref.read(focusedNoticeIdProvider.notifier).state = noticeId;
            onNavigate(target);
        }
      },
      itemBuilder: (context) {
        final items = <PopupMenuEntry<Object>>[
          PopupMenuItem<Object>(
            enabled: false,
            child: SizedBox(
              width: _panelWidth,
              child: Text(
                'Notifications',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const PopupMenuDivider(height: 1),
        ];

        if (totalCount == 0) {
          items.add(
            PopupMenuItem<Object>(
              enabled: false,
              child: SizedBox(
                width: _panelWidth,
                child: Text(
                  'No notifications right now.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          );
          return items;
        }

        void addSection(String label, List<PopupMenuEntry<Object>> entries) {
          if (entries.isEmpty) return;
          items.add(_categoryLabel(label));
          items.addAll(entries);
        }

        addSection('Celebrations', [
          for (final birthday in birthdays)
            PopupMenuItem<Object>(
              value: _OpenEmployeeProfile(birthday.employeeId),
              child: _NotificationTile(
                icon: Icons.cake_outlined,
                iconColor: AppColors.secondary,
                title: "${birthday.fullName}'s birthday",
                subtitle:
                    '${formatMonthDay(birthday.dateOfBirth)} · '
                    '${_relativeDayLabel(birthday.daysUntil)}',
                // Already happened this week — old news, so fade it.
                muted: birthday.daysUntil < 0,
              ),
            ),
          for (final anniversary in anniversaries)
            PopupMenuItem<Object>(
              value: _OpenEmployeeProfile(anniversary.employeeId),
              child: _NotificationTile(
                icon: Icons.celebration_outlined,
                iconColor: AppColors.accentTeal,
                title:
                    "${anniversary.fullName}'s ${anniversary.yearsOfService}"
                    '-year anniversary',
                subtitle:
                    '${formatMonthDay(anniversary.joiningDate)} · '
                    '${_relativeDayLabel(anniversary.daysUntil)}',
                muted: anniversary.daysUntil < 0,
              ),
            ),
        ]);

        addSection('Notices', [
          for (var i = 0; i < recentNotices.length; i++)
            PopupMenuItem<Object>(
              value: _FocusNotice(recentNotices[i].id, noticeTarget),
              child: _NotificationTile(
                icon: Icons.campaign_outlined,
                iconColor: AppColors.primary,
                title: recentNotices[i].title,
                subtitle: recentNotices[i].body,
                caption: 'Company notice',
                trailing: formatRelativeTime(recentNotices[i].createdAt),
                // Only the newest notice stays full-color, mirroring the
                // same latest-vs-older treatment CompanyNoticesSection uses.
                muted: i != 0,
              ),
            ),
        ]);

        addSection('Awaiting your action', [
          if (needsLeaveReset)
            PopupMenuItem<Object>(
              value: NotificationLinkTarget.leavePage,
              child: _NotificationTile(
                icon: Icons.event_repeat_outlined,
                iconColor: AppColors.warning,
                title:
                    'Annual leave balances for ${resetStatus.year} need to '
                    'be reset',
              ),
            ),
          for (final request in hrApprovals)
            PopupMenuItem<Object>(
              value: NotificationLinkTarget.adminDashboard,
              child: _NotificationTile(
                icon: Icons.assignment_outlined,
                iconColor: AppColors.warning,
                title: '${request.subject} — ${request.requesterName}',
                caption: 'Awaiting HR approval',
                trailing: formatRelativeTime(
                  request.managerDecisionAt ?? request.createdAt,
                ),
              ),
            ),
          for (final request in managerApprovals)
            PopupMenuItem<Object>(
              value: NotificationLinkTarget.userDashboard,
              child: _NotificationTile(
                icon: Icons.assignment_outlined,
                iconColor: AppColors.warning,
                title: '${request.subject} — ${request.requesterName}',
                caption: 'Awaiting your approval',
                trailing: formatRelativeTime(request.createdAt),
              ),
            ),
          for (final request in leaveHrApprovals)
            PopupMenuItem<Object>(
              value: NotificationLinkTarget.leavePage,
              child: _NotificationTile(
                icon: Icons.beach_access_outlined,
                iconColor: AppColors.warning,
                title: '${request.leaveTypeName} — ${request.requesterName}',
                caption: 'Leave awaiting HR approval',
                trailing: formatRelativeTime(
                  request.managerDecisionAt ?? request.createdAt,
                ),
              ),
            ),
          for (final request in leaveManagerApprovals)
            PopupMenuItem<Object>(
              value: NotificationLinkTarget.leavePage,
              child: _NotificationTile(
                icon: Icons.beach_access_outlined,
                iconColor: AppColors.warning,
                title: '${request.leaveTypeName} — ${request.requesterName}',
                caption: 'Leave awaiting your approval',
                trailing: formatRelativeTime(request.createdAt),
              ),
            ),
        ]);

        addSection('Recent updates', [
          // Already-decided — old news the viewer has effectively already
          // seen play out, so these fade rather than compete with the
          // still-pending items above.
          for (final request in myRecentLeaveDecisions)
            PopupMenuItem<Object>(
              value: NotificationLinkTarget.leavePage,
              child: _NotificationTile(
                icon: Icons.beach_access_outlined,
                iconColor: request.status == 'approved'
                    ? AppColors.success
                    : AppColors.error,
                title: '${request.leaveTypeName} — ${request.requesterName}',
                caption: request.status == 'approved'
                    ? 'Your leave was approved'
                    : 'Your leave was rejected',
                trailing: formatRelativeTime(
                  request.hrDecisionAt ??
                      request.managerDecisionAt ??
                      request.createdAt,
                ),
                muted: true,
              ),
            ),
          for (final request in myRecentRequestDecisions)
            PopupMenuItem<Object>(
              value: NotificationLinkTarget.userDashboard,
              child: _NotificationTile(
                icon: Icons.assignment_outlined,
                iconColor: request.status == 'completed'
                    ? AppColors.success
                    : AppColors.error,
                title: '${request.subject} — ${request.requesterName}',
                caption: request.status == 'completed'
                    ? 'Your request was completed'
                    : 'Your request was rejected',
                trailing: formatRelativeTime(
                  request.hrDecisionAt ??
                      request.managerDecisionAt ??
                      request.createdAt,
                ),
                muted: true,
              ),
            ),
        ]);

        return items;
      },
      child: Badge(
        label: Text('+$totalCount'),
        isLabelVisible: totalCount > 0,
        backgroundColor: AppColors.error,
        textStyle: const TextStyle(fontSize: 10),
        child: const Icon(Icons.notifications_outlined),
      ),
    );
  }
}

PopupMenuItem<Object> _categoryLabel(String text) {
  return PopupMenuItem<Object>(
    enabled: false,
    height: 28,
    child: Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
        color: AppColors.textSecondary,
      ),
    ),
  );
}

/// Keeps only the already-decided items (per [isDecided]), newest-first by
/// [decidedAt], capped to [_maxDecidedHistory] — a bounded history rather
/// than a time-window cutoff, so nothing vanishes just because time passed.
List<T> _recentlyDecided<T>(
  List<T> items, {
  required bool Function(T) isDecided,
  required DateTime? Function(T) decidedAt,
}) {
  final decided = items.where(isDecided).toList()
    ..sort((a, b) {
      final aAt = decidedAt(a) ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bAt = decidedAt(b) ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bAt.compareTo(aAt);
    });
  return decided.take(_maxDecidedHistory).toList();
}

/// 0 means today; negative means it already happened this many days ago;
/// positive means it's this many days away.
String _relativeDayLabel(int daysUntil) {
  if (daysUntil == 0) return 'Today';
  if (daysUntil == 1) return 'Tomorrow';
  if (daysUntil > 1) return 'In $daysUntil days';
  if (daysUntil == -1) return '1 day ago';
  return '${-daysUntil} days ago';
}

/// The single visual building block for every notification in the bell — an
/// icon chip plus title/subtitle that wrap across as many lines as needed
/// (never truncated), with an optional caption/timestamp footer for items
/// that have both a status and an age.
class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.caption,
    this.trailing,
    this.muted = false,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final String? caption;
  final String? trailing;

  /// True for a notification about something already past or resolved (a
  /// birthday/anniversary that already happened, an older notice, an
  /// already-decided request) — faded so still-relevant items stand out.
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: muted ? 0.55 : 1,
      child: SizedBox(
        width: _panelWidth,
        // Vertical breathing room between one notification and the next —
        // PopupMenuItem itself adds no vertical padding, so without this,
        // adjacent notifications' text runs directly into each other.
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, size: 16, color: iconColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                    if (caption != null || trailing != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (caption != null)
                            Expanded(
                              child: Text(
                                caption!,
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(color: AppColors.textSecondary),
                              ),
                            ),
                          if (trailing != null) ...[
                            if (caption != null) const SizedBox(width: 8),
                            Text(
                              trailing!,
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: AppColors.textSecondary.withValues(
                                      alpha: 0.7,
                                    ),
                                  ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
