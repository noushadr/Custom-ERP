import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../authentication/application/auth_providers.dart';
import '../../../authentication/application/auth_state.dart';
import '../../../requests/application/request_providers.dart';
import '../../../requests/domain/entities/employee_request.dart';
import '../../application/employee_providers.dart';
import '../../domain/entities/upcoming_birthday.dart';

/// Where tapping a notification should take the viewer.
enum NotificationLinkTarget { adminDashboard, userDashboard }

/// Bell + dropdown shown in the top bar, next to the account menu — mirrors
/// how most SaaS/social apps surface notifications rather than giving them
/// their own nav destination. Combines birthday reminders (Super
/// Admin/HR-Manager only) with requests awaiting the viewer's approval.
class NotificationBell extends ConsumerWidget {
  const NotificationBell({super.key, required this.onNavigate});

  final ValueChanged<NotificationLinkTarget> onNavigate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final authUser = authState is AuthAuthenticated ? authState.user : null;
    final canSeeBirthdays = authUser?.hasPermission('employees.manage') ?? false;
    final canSeeHrApprovals = authUser?.hasPermission('users.manage') ?? false;

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

    final totalCount =
        birthdays.length + hrApprovals.length + managerApprovals.length;

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
          for (final request in hrApprovals)
            PopupMenuItem<NotificationLinkTarget>(
              value: NotificationLinkTarget.adminDashboard,
              height: 44,
              child: _RequestRow(
                request: request,
                caption: 'Awaiting HR approval',
              ),
            ),
          for (final request in managerApprovals)
            PopupMenuItem<NotificationLinkTarget>(
              value: NotificationLinkTarget.userDashboard,
              height: 44,
              child: _RequestRow(
                request: request,
                caption: 'Awaiting your approval',
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

class _RequestRow extends StatelessWidget {
  const _RequestRow({required this.request, required this.caption});

  final EmployeeRequest request;
  final String caption;

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
          Text(
            caption,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
