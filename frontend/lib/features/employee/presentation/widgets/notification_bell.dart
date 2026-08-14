import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/utils/date_format.dart';
import '../../../authentication/application/auth_providers.dart';
import '../../../authentication/application/auth_state.dart';
import '../../../leave/application/leave_providers.dart';
import '../../../leave/domain/entities/leave_request.dart';
import '../../../requests/application/request_providers.dart';
import '../../../requests/domain/entities/employee_request.dart';
import '../../application/employee_providers.dart';
import '../../domain/entities/upcoming_birthday.dart';

/// Where tapping a notification should take the viewer.
enum NotificationLinkTarget { adminDashboard, userDashboard, leavePage }

// How many past (already-decided) items to keep per history list — a record
// of what happened, not just what's still pending, but bounded so the list
// doesn't grow forever for a long-tenured employee. Unlike the old 7-day
// cutoff this never hides something just because time passed.
const _maxDecidedHistory = 10;

/// Bell + dropdown shown in the top bar, next to the account menu — mirrors
/// how most SaaS/social apps surface notifications rather than giving them
/// their own nav destination. Combines birthday reminders (Super
/// Admin/HR-Manager only), requests/leave awaiting the viewer's approval, a
/// leave-balance-reset reminder (Super Admin/HR only), and the viewer's own
/// recently-decided requests/leave — every item shows how long ago it
/// happened.
class NotificationBell extends ConsumerWidget {
  const NotificationBell({super.key, required this.onNavigate});

  final ValueChanged<NotificationLinkTarget> onNavigate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final authUser = authState is AuthAuthenticated ? authState.user : null;
    final canSeeBirthdays = authUser?.hasPermission('employees.manage') ?? false;
    final canSeeHrApprovals = authUser?.hasPermission('users.manage') ?? false;
    final canManageLeave = authUser?.hasPermission('leave.manage') ?? false;

    final birthdays = canSeeBirthdays
        ? ref.watch(upcomingBirthdaysProvider).valueOrNull ?? const []
        : const <UpcomingBirthday>[];
    final hrApprovals = canSeeHrApprovals
        ? ref.watch(pendingHrApprovalRequestsProvider).valueOrNull ?? const []
        : const <EmployeeRequest>[];
    // No permission guard on the backend for this one — safe for everyone,
    // and naturally empty for anyone who isn't a reporting manager.
    final managerApprovals =
        ref.watch(pendingManagerApprovalRequestsProvider).valueOrNull ??
        const <EmployeeRequest>[];

    final leaveHrApprovals = canManageLeave
        ? ref.watch(pendingHrApprovalLeaveRequestsProvider).valueOrNull ?? const []
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
        hrApprovals.length +
        managerApprovals.length +
        leaveHrApprovals.length +
        leaveManagerApprovals.length +
        myRecentLeaveDecisions.length +
        myRecentRequestDecisions.length +
        (needsLeaveReset ? 1 : 0);

    return PopupMenuButton<NotificationLinkTarget>(
      tooltip: 'Notifications',
      offset: const Offset(0, 44),
      onSelected: onNavigate,
      itemBuilder: (context) => [
        if (totalCount == 0)
          PopupMenuItem<NotificationLinkTarget>(
            enabled: false,
            child: Text(
              'No notifications right now.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          )
        else ...[
          for (final birthday in birthdays)
            PopupMenuItem<NotificationLinkTarget>(
              enabled: false,
              height: 36,
              child: _BirthdayRow(birthday: birthday),
            ),
          if (needsLeaveReset)
            PopupMenuItem<NotificationLinkTarget>(
              value: NotificationLinkTarget.leavePage,
              height: 36,
              child: Text(
                '⏰ Annual leave balances for ${resetStatus.year} need to be reset',
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          for (final request in hrApprovals)
            PopupMenuItem<NotificationLinkTarget>(
              value: NotificationLinkTarget.adminDashboard,
              height: 44,
              child: _RequestRow(
                request: request,
                caption: 'Awaiting HR approval',
                timestamp: request.managerDecisionAt ?? request.createdAt,
              ),
            ),
          for (final request in managerApprovals)
            PopupMenuItem<NotificationLinkTarget>(
              value: NotificationLinkTarget.userDashboard,
              height: 44,
              child: _RequestRow(
                request: request,
                caption: 'Awaiting your approval',
                timestamp: request.createdAt,
              ),
            ),
          for (final request in leaveHrApprovals)
            PopupMenuItem<NotificationLinkTarget>(
              value: NotificationLinkTarget.leavePage,
              height: 44,
              child: _LeaveRequestRow(
                request: request,
                caption: 'Leave awaiting HR approval',
                timestamp: request.managerDecisionAt ?? request.createdAt,
              ),
            ),
          for (final request in leaveManagerApprovals)
            PopupMenuItem<NotificationLinkTarget>(
              value: NotificationLinkTarget.leavePage,
              height: 44,
              child: _LeaveRequestRow(
                request: request,
                caption: 'Leave awaiting your approval',
                timestamp: request.createdAt,
              ),
            ),
          for (final request in myRecentLeaveDecisions)
            PopupMenuItem<NotificationLinkTarget>(
              value: NotificationLinkTarget.leavePage,
              height: 44,
              child: _LeaveRequestRow(
                request: request,
                caption: request.status == 'approved'
                    ? 'Your leave was approved'
                    : 'Your leave was rejected',
                timestamp:
                    request.hrDecisionAt ??
                    request.managerDecisionAt ??
                    request.createdAt,
              ),
            ),
          for (final request in myRecentRequestDecisions)
            PopupMenuItem<NotificationLinkTarget>(
              value: NotificationLinkTarget.userDashboard,
              height: 44,
              child: _RequestRow(
                request: request,
                caption: request.status == 'completed'
                    ? 'Your request was completed'
                    : 'Your request was rejected',
                timestamp:
                    request.hrDecisionAt ??
                    request.managerDecisionAt ??
                    request.createdAt,
              ),
            ),
        ],
      ],
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

class _BirthdayRow extends StatelessWidget {
  const _BirthdayRow({required this.birthday});

  final UpcomingBirthday birthday;

  String get _whenLabel {
    switch (birthday.daysUntil) {
      case 0:
        return 'Today';
      case 1:
        return 'Tomorrow';
      default:
        return 'In ${birthday.daysUntil} days';
    }
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 280),
      child: Text(
        "🎂 ${birthday.fullName}'s birthday — $_whenLabel",
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}

class _LeaveRequestRow extends StatelessWidget {
  const _LeaveRequestRow({
    required this.request,
    required this.caption,
    required this.timestamp,
  });

  final LeaveRequest request;
  final String caption;
  final DateTime timestamp;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 280),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${request.leaveTypeName} — ${request.requesterName}',
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          Row(
            children: [
              Expanded(
                child: Text(
                  caption,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                formatRelativeTime(timestamp),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textSecondary.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RequestRow extends StatelessWidget {
  const _RequestRow({
    required this.request,
    required this.caption,
    required this.timestamp,
  });

  final EmployeeRequest request;
  final String caption;
  final DateTime timestamp;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 280),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${request.subject} — ${request.requesterName}',
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          Row(
            children: [
              Expanded(
                child: Text(
                  caption,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                formatRelativeTime(timestamp),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textSecondary.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
