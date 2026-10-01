import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/layout/breakpoints.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../authentication/application/auth_providers.dart';
import '../../../authentication/application/auth_state.dart';
import '../../../authentication/domain/exceptions/auth_exception.dart';
import '../../../../shared/utils/date_format.dart';
import '../../../checklists/presentation/widgets/employee_checklist_section.dart';
import '../../../goals/application/goal_providers.dart';
import '../../../goals/domain/entities/goal.dart';
import '../../../goals/domain/exceptions/goal_exception.dart';
import '../../../leave/application/leave_providers.dart';
import '../../../leave/presentation/widgets/leave_balances_section.dart';
import '../../../payroll/presentation/widgets/payslip_list_section.dart';
import '../../../performance_reviews/presentation/widgets/employee_performance_reviews_section.dart';
import '../../../tasks/application/task_providers.dart';
import '../../../tasks/domain/entities/task.dart';
import '../../../tasks/domain/entities/task_status.dart';
import '../../../tasks/presentation/widgets/task_summary_row.dart';
import '../../application/employee_providers.dart';
import '../../domain/entities/employee.dart';
import '../widgets/employee_assets_section.dart';
import '../widgets/employee_audit_log_panel.dart';
import '../widgets/employee_avatar.dart';
import '../widgets/employee_documents_section.dart';
import '../widgets/employee_education_section.dart';
import '../widgets/employee_salary_history_section.dart';
import '../widgets/employee_status_badges.dart';
import '../widgets/employee_tags_section.dart';
import 'edit_employee_page.dart';
import 'edit_my_profile_page.dart';
import '../../../../shared/widgets/app_dialog.dart';

/// Shows an employee's profile. Pass null for [employeeId] to view the
/// current user's own profile.
class EmployeeProfilePage extends ConsumerWidget {
  const EmployeeProfilePage({super.key, required this.employeeId});

  final String? employeeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employeeAsync = employeeId == null
        ? ref.watch(myProfileProvider)
        : ref.watch(employeeDetailProvider(employeeId!));

    return Scaffold(
      appBar: AppBar(title: const Text('Employee Profile')),
      body: employeeAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            const Center(child: Text('Could not load this profile.')),
        data: (employee) => _ProfileBody(employee: employee),
      ),
    );
  }
}

class _ProfileBody extends ConsumerWidget {
  const _ProfileBody({required this.employee});

  final Employee employee;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final isOwnProfile =
        authState is AuthAuthenticated &&
        authState.user.email == employee.email;
    final canManage =
        authState is AuthAuthenticated &&
        authState.user.hasPermission('employees.manage');
    final showAuditLog = isOwnProfile || canManage;
    final canImpersonate =
        authState is AuthAuthenticated &&
        authState.user.hasPermission('users.impersonate') &&
        !isOwnProfile &&
        employee.accountStatus != 'disabled';
    final canResetPassword =
        authState is AuthAuthenticated &&
        authState.user.hasPermission('users.manage');
    // Each of these three overview sections has its own permission, distinct
    // from `employees.manage` (which gates the profile's more sensitive
    // fields below) — a viewer might hold one, some, or none of them for
    // someone else's profile, so each section gates itself independently.
    // Always true for a viewer's own profile, same as every self-service
    // section elsewhere in this app.
    final canViewLeave =
        isOwnProfile ||
        (authState is AuthAuthenticated &&
            authState.user.hasPermission('leave.manage'));
    final canViewTasks =
        isOwnProfile ||
        (authState is AuthAuthenticated &&
            authState.user.hasPermission('tasks.manage'));
    final canViewGoals =
        isOwnProfile ||
        (authState is AuthAuthenticated &&
            authState.user.hasPermission('goals.manage'));
    // Not tied to isOwnProfile — the viewer's own payslips already live on
    // their User Dashboard (see MyPayslipsSection); this is specifically
    // the HR/Admin-facing "someone else's payslips" view.
    final canViewPayslips =
        authState is AuthAuthenticated &&
        authState.user.hasPermission('payroll.manage');

    final headerCard = Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                EmployeeAvatar(
                  fullName: employee.fullName,
                  photoUrl: employee.profilePhotoUrl,
                  radius: 32,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        employee.fullName,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        employee.designation ?? employee.role,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (canResetPassword) ...[
                      _ProfileActionButton(
                        onPressed: () => _resetPassword(context, ref, employee),
                        icon: Icons.password,
                        label: 'Reset password',
                      ),
                      const SizedBox(width: 6),
                    ],
                    if (canImpersonate) ...[
                      _ProfileActionButton(
                        onPressed: () => _loginAsUser(context, ref, employee),
                        icon: Icons.login,
                        label: 'Login as',
                      ),
                      const SizedBox(width: 6),
                    ],
                    if (isOwnProfile)
                      _ProfileActionButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                EditMyProfilePage(employee: employee),
                          ),
                        ),
                        icon: Icons.edit_outlined,
                        label: 'Edit',
                      )
                    else if (canManage)
                      _ProfileActionButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                EditEmployeePage(employee: employee),
                          ),
                        ),
                        icon: Icons.edit_outlined,
                        label: 'Edit',
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                EmploymentStatusBadge(status: employee.employmentStatus),
                if (employee.employmentStatus == 'resigned' &&
                    employee.dateOfLeaving != null)
                  Text(
                    'Resigned on ${formatDisplayDate(employee.dateOfLeaving!)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                WorkModeBadge(workMode: employee.workMode),
                InfoChip(
                  icon: Icons.badge_outlined,
                  label: employee.employeeCode,
                ),
              ],
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: employee.profileCompletionPercentage / 100,
                minHeight: 6,
                backgroundColor: AppColors.borderSubtle,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Profile ${employee.profileCompletionPercentage}% complete',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );

    // Left (60%): day-to-day, activity-oriented data someone visiting this
    // profile most likely wants first. Right (40%): administrative/reference
    // data (banking, documents, emergency contact, ...) filled in once and
    // rarely revisited, same split as EditEmployeePage's own layout.
    final leftColumn = Column(
      // Stretch, not start — several of these sections (Leave Balances,
      // Tasks, Goals) hold a `Wrap` or bare `Text` rather than a full-width
      // `Row`, so without stretching their cards shrink-wrap to their own
      // content width instead of matching the Work/Contact/Bank cards,
      // which happen to fill the width anyway because `_LabeledRow` uses a
      // `Row`.
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Section(
          title: 'Work',
          children: [
            _LabeledRow(
              label: 'Employee ID',
              child: Text(employee.employeeCode),
            ),
            _LabeledRow(
              label: 'Department',
              child: Text(employee.department?.name ?? '—'),
            ),
            _LabeledRow(
              label: 'Reporting Manager',
              child: employee.reportingManager == null
                  ? const Text('—')
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        EmployeeAvatar(
                          fullName: employee.reportingManager!.name,
                          photoUrl: employee.reportingManager!.photoUrl,
                          radius: 12,
                        ),
                        const SizedBox(width: 8),
                        Text(employee.reportingManager!.name),
                      ],
                    ),
            ),
            _LabeledRow(
              label: 'Employment type',
              child: Text(formatEmploymentType(employee.employmentType)),
            ),
            _LabeledRow(
              label: 'Employment status',
              child: Text(employee.employmentStatus),
            ),
            _LabeledRow(
              label: 'Joining date',
              child: Text(formatDisplayDate(employee.joiningDate)),
            ),
            if (showAuditLog) ...[
              _LabeledRow(
                label: 'Joining salary',
                child: SalaryHeadlineValue(
                  employeeId: isOwnProfile ? null : employee.id,
                  which: SalaryHeadline.joining,
                ),
              ),
              _LabeledRow(
                label: 'Current salary',
                child: SalaryHeadlineValue(
                  employeeId: isOwnProfile ? null : employee.id,
                  which: SalaryHeadline.current,
                ),
              ),
            ],
            _LabeledRow(
              label: employee.employmentStatus == 'resigned'
                  ? 'Resignation date'
                  : 'Date of leaving',
              child: Text(
                employee.dateOfLeaving == null
                    ? '—'
                    : formatDisplayDate(employee.dateOfLeaving!),
              ),
            ),
            _LabeledRow(
              label: 'Probation',
              child: employee.probationEndDate == null
                  ? const Text('—')
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Until ${formatDisplayDate(employee.probationEndDate!)}',
                        ),
                        const SizedBox(width: 8),
                        if (employee.probationStatus != null)
                          ProbationBadge(
                            status: employee.probationStatus!,
                            dense: true,
                          ),
                      ],
                    ),
            ),
          ],
        ),
        if (canViewLeave) ...[
          const SizedBox(height: 16),
          _EmployeeLeaveBalancesSection(
            employeeId: employee.id,
            isOwnProfile: isOwnProfile,
          ),
        ],
        if (canViewTasks) ...[
          const SizedBox(height: 16),
          _EmployeeTasksSection(
            employeeId: employee.id,
            isOwnProfile: isOwnProfile,
          ),
        ],
        if (canViewGoals) ...[
          const SizedBox(height: 16),
          _EmployeeGoalsSection(
            employeeId: employee.id,
            isOwnProfile: isOwnProfile,
          ),
        ],
        // Not nested under any of the permission checks above — this
        // section gates itself on the separate performance.manage
        // permission, so it stays visible to a custom role that holds
        // performance.manage without any of leave.manage/tasks.manage/
        // goals.manage too.
        const SizedBox(height: 16),
        EmployeePerformanceReviewsSection(
          employeeId: employee.id,
          isSelf: isOwnProfile,
        ),
        const SizedBox(height: 16),
        _Section(
          title: 'Contact',
          children: [
            _LabeledRow(label: 'Company email', child: Text(employee.email)),
            // The backend already strips these for a viewer who is neither
            // the employee themselves nor an employees.manage holder — this
            // gate is a second line of defense so a regression there
            // wouldn't also mean this page renders a real leaked value.
            if (showAuditLog) ...[
              _LabeledRow(
                label: 'Personal email',
                child: Text(employee.personalEmail ?? '—'),
              ),
              _LabeledRow(
                label: 'Phone',
                child: Text(employee.phoneNumber ?? '—'),
              ),
              _LabeledRow(
                label: 'Date of birth',
                child: Text(
                  employee.dateOfBirth == null
                      ? '—'
                      : formatDisplayDate(employee.dateOfBirth!),
                ),
              ),
              _LabeledRow(
                label: 'Address',
                child: Text(employee.address ?? '—'),
              ),
            ],
          ],
        ),
        if (showAuditLog) ...[
          const SizedBox(height: 16),
          _Section(
            title: 'Bank Information',
            children: [
              _LabeledRow(
                label: 'Bank name',
                child: Text(employee.bankName ?? '—'),
              ),
              _LabeledRow(
                label: 'Account title',
                child: Text(employee.accountTitle ?? '—'),
              ),
              _LabeledRow(
                label: 'Account number',
                child: Text(employee.accountNumber ?? '—'),
              ),
              _LabeledRow(
                label: 'Branch code',
                child: Text(employee.branchCode ?? '—'),
              ),
              _LabeledRow(label: 'IBAN', child: Text(employee.iban ?? '—')),
            ],
          ),
        ],
        if (showAuditLog) ...[
          const SizedBox(height: 16),
          _Section(
            title: 'Emergency contact',
            children: [
              _LabeledRow(
                label: 'Name',
                child: Text(employee.emergencyContactName ?? '—'),
              ),
              _LabeledRow(
                label: 'Phone',
                child: Text(employee.emergencyContactPhone ?? '—'),
              ),
              _LabeledRow(
                label: 'Relation',
                child: Text(employee.emergencyContactRelation ?? '—'),
              ),
            ],
          ),
        ],
      ],
    );

    final rightColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showAuditLog) ...[
          EmployeeSalaryHistorySection(
            employeeId: employee.id,
            isSelf: isOwnProfile,
            canManage: canManage,
          ),
          if (canViewPayslips) ...[
            const SizedBox(height: 16),
            EmployeePayslipsSection(employeeId: employee.id),
          ],
          const SizedBox(height: 16),
          EmployeeAssetsSection(
            employeeId: employee.id,
            isSelf: isOwnProfile,
            canManage: canManage,
          ),
          const SizedBox(height: 16),
          EmployeeDocumentsSection(
            employeeId: isOwnProfile ? null : employee.id,
          ),
          const SizedBox(height: 16),
          EmployeeChecklistSection(
            employeeId: employee.id,
            isSelf: isOwnProfile,
            canManage: canManage,
          ),
          const SizedBox(height: 16),
          EmployeeEducationSection(
            employeeId: isOwnProfile ? null : employee.id,
          ),
          const SizedBox(height: 16),
          EmployeeTagsSection(
            title: 'Skills',
            values: employee.skills,
            field: EmployeeTagsField.skills,
            employeeId: isOwnProfile ? null : employee.id,
          ),
          const SizedBox(height: 16),
          EmployeeTagsSection(
            title: 'Certifications',
            values: employee.certifications,
            field: EmployeeTagsField.certifications,
            employeeId: isOwnProfile ? null : employee.id,
          ),
          const SizedBox(height: 16),
          EmployeeAuditLogPanel(employeeId: isOwnProfile ? null : employee.id),
        ],
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= Breakpoints.tabletMax;

        if (isWide) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    headerCard,
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 6, child: leftColumn),
                        const SizedBox(width: 24),
                        Expanded(flex: 4, child: rightColumn),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  headerCard,
                  const SizedBox(height: 16),
                  leftColumn,
                  const SizedBox(height: 16),
                  rightColumn,
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Switches the active session to [employee], then pops back to the section
/// root so the viewer doesn't stay on a page that may not apply to them.
Future<void> _loginAsUser(
  BuildContext context,
  WidgetRef ref,
  Employee employee,
) async {
  try {
    await ref
        .read(authControllerProvider.notifier)
        .impersonate(employee.userId);
    if (!context.mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  } on AuthException catch (error) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(error.message)));
  }
}

/// Confirms, then resets [employee]'s password to a new temporary one and
/// shows it once so the admin/HR can share it directly.
Future<void> _resetPassword(
  BuildContext context,
  WidgetRef ref,
  Employee employee,
) async {
  final confirmed = await showAppDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Reset password?'),
      content: Text(
        '${employee.fullName} will need a new temporary password to log '
        'in — this cannot be undone.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Reset password'),
        ),
      ],
    ),
  );
  if (confirmed != true) return;

  try {
    final temporaryPassword = await ref
        .read(authControllerProvider.notifier)
        .resetPassword(employee.userId);
    if (!context.mounted) return;
    await showAppDialog<void>(
      context: context,
      builder: (_) => _TemporaryPasswordDialog(password: temporaryPassword),
    );
  } on AuthException catch (error) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(error.message)));
  }
}

class _TemporaryPasswordDialog extends StatelessWidget {
  const _TemporaryPasswordDialog({required this.password});

  final String password;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New temporary password'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Share this with them directly — it will only be shown once.',
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).dividerColor),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SelectableText(
                  password,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontFeatures: [const FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.copy_outlined, size: 18),
                  tooltip: 'Copy',
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: password));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Copied to clipboard')),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Done'),
        ),
      ],
    );
  }
}

/// A compact outlined button for the profile header's action row (Reset
/// password/Login as/Edit) — smaller than the app's default `OutlinedButton`
/// sizing so up to three of these fit comfortably beside the employee's
/// name/title without crowding the header.
class _ProfileActionButton extends StatelessWidget {
  const _ProfileActionButton({
    required this.onPressed,
    required this.icon,
    required this.label,
  });

  final VoidCallback onPressed;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 13),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        minimumSize: const Size(0, 0),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        textStyle: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children, this.trailing});

  final String title;
  final List<Widget> children;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                ?trailing,
              ],
            ),
            const SizedBox(height: 10),
            ...children,
          ],
        ),
      ),
    );
  }
}

/// A label + value row used inside [_Section] — [child] can be plain text
/// or a richer widget (e.g. an avatar next to a name).
class _LabeledRow extends StatelessWidget {
  const _LabeledRow({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 160,
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          Expanded(
            child: DefaultTextStyle.merge(
              style: Theme.of(context).textTheme.bodyMedium!,
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

/// This employee's current-year leave balances — the viewer's own via the
/// same self-service provider the Leave page/User Dashboard use, or (with
/// `leave.manage`) anyone else's via the same admin-facing per-employee
/// endpoint the "Apply Leave for Employee" dialog already relies on.
class _EmployeeLeaveBalancesSection extends ConsumerWidget {
  const _EmployeeLeaveBalancesSection({
    required this.employeeId,
    required this.isOwnProfile,
  });

  final String employeeId;
  final bool isOwnProfile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balancesAsync = isOwnProfile
        ? ref.watch(myLeaveBalancesProvider)
        : ref.watch(employeeLeaveBalancesProvider(employeeId));

    return _Section(
      title: 'Leave Balances',
      children: [
        balancesAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: LinearProgressIndicator(),
          ),
          error: (_, _) => const Text('Could not load leave balances.'),
          data: (balances) {
            if (balances.isEmpty) {
              return Text(
                'No leave balances yet.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              );
            }
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final balance in balances)
                  LeaveBalanceCard(balance: balance),
              ],
            );
          },
        ),
      ],
    );
  }
}

/// This employee's task counts — the viewer's own tasks (assigned to them
/// plus whatever they've assigned to others, same split the User Dashboard's
/// own "My Tasks" box uses) for their own profile, or (with `tasks.manage`)
/// anyone else's tasks-assigned-to-them count, filtered client-side from the
/// same company-wide list the Team Task Board already fetches — no new
/// backend endpoint needed for either case.
class _EmployeeTasksSection extends ConsumerWidget {
  const _EmployeeTasksSection({
    required this.employeeId,
    required this.isOwnProfile,
  });

  final String employeeId;
  final bool isOwnProfile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (isOwnProfile) {
      final myTasksAsync = ref.watch(myTasksProvider);
      final assignedByMeAsync = ref.watch(tasksAssignedByMeProvider);
      return _Section(
        title: 'Tasks',
        children: [
          myTasksAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: LinearProgressIndicator(),
            ),
            error: (_, _) => const Text('Could not load tasks.'),
            data: (myTasks) => assignedByMeAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: LinearProgressIndicator(),
              ),
              error: (_, _) => const Text('Could not load tasks.'),
              data: (assignedByMe) => _TaskCounts(
                assignedToThem: myTasks,
                assignedByThem: assignedByMe,
              ),
            ),
          ),
        ],
      );
    }

    final teamTasksAsync = ref.watch(teamTasksProvider);
    return _Section(
      title: 'Tasks',
      children: [
        teamTasksAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: LinearProgressIndicator(),
          ),
          error: (_, _) => const Text('Could not load tasks.'),
          data: (tasks) {
            final assigned = tasks
                .where((t) => t.assigneeEmployeeId == employeeId)
                .toList();
            return _TaskCounts(assignedToThem: assigned, assignedByThem: null);
          },
        ),
      ],
    );
  }
}

class _TaskCounts extends StatelessWidget {
  const _TaskCounts({required this.assignedToThem, this.assignedByThem});

  final List<Task> assignedToThem;

  /// The tasks this employee has assigned to others — only known (and only
  /// shown) for the viewer's own profile, since a `tasks.manage` viewer
  /// looking at someone else's profile only gets that person's
  /// assigned-to-them tasks from the filtered company-wide list.
  final List<Task>? assignedByThem;

  @override
  Widget build(BuildContext context) {
    if (assignedToThem.isEmpty && (assignedByThem?.isEmpty ?? true)) {
      return Text(
        'No tasks yet.',
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
      );
    }

    final pendingOrInProgress = assignedToThem
        .where(
          (t) =>
              t.status == TaskStatus.todo ||
              t.status == TaskStatus.pending ||
              t.status == TaskStatus.inProgress,
        )
        .length;
    final done = assignedToThem
        .where((t) => t.status == TaskStatus.completed)
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 28,
          runSpacing: 12,
          children: [
            _StatBlock(
              label: 'Total',
              value: assignedToThem.length,
              color: AppColors.textPrimary,
            ),
            _StatBlock(
              label: 'Pending / In Progress',
              value: pendingOrInProgress,
              color: AppColors.warning,
            ),
            _StatBlock(label: 'Done', value: done, color: AppColors.success),
            if (assignedByThem != null)
              _StatBlock(
                label: 'Assigned by them',
                value: assignedByThem!.length,
                color: AppColors.textSecondary,
              ),
          ],
        ),
        if (assignedToThem.isNotEmpty) ...[
          const SizedBox(height: 12),
          for (var i = 0; i < assignedToThem.length; i++) ...[
            TaskSummaryRow(task: assignedToThem[i]),
            if (i < assignedToThem.length - 1)
              const Divider(height: 16, color: AppColors.borderSubtle),
          ],
        ],
        if (assignedByThem != null && assignedByThem!.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            'Assigned by them',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          for (var i = 0; i < assignedByThem!.length; i++) ...[
            TaskSummaryRow(task: assignedByThem![i]),
            if (i < assignedByThem!.length - 1)
              const Divider(height: 16, color: AppColors.borderSubtle),
          ],
        ],
      ],
    );
  }
}

class _StatBlock extends StatelessWidget {
  const _StatBlock({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$value',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

/// This employee's goals — the viewer's own via `myGoalsProvider` (same
/// provider the User Dashboard's own "My Goals" box uses), or (with
/// `goals.manage`) anyone else's, filtered client-side from the same
/// company-wide list the Goals page's "All Goals" view already fetches.
class _EmployeeGoalsSection extends ConsumerWidget {
  const _EmployeeGoalsSection({
    required this.employeeId,
    required this.isOwnProfile,
  });

  final String employeeId;
  final bool isOwnProfile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = isOwnProfile
        ? ref.watch(myGoalsProvider)
        : ref.watch(allGoalsProvider);

    return _Section(
      title: 'Goals',
      trailing: IconButton(
        icon: const Icon(Icons.add, size: 20),
        tooltip: 'Add goal',
        onPressed: () => showAppDialog<void>(
          context: context,
          builder: (_) => _AddEmployeeGoalDialog(
            employeeId: employeeId,
            isOwnProfile: isOwnProfile,
          ),
        ),
      ),
      children: [
        goalsAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: LinearProgressIndicator(),
          ),
          error: (_, _) => const Text('Could not load goals.'),
          data: (goals) {
            final relevant = isOwnProfile
                ? goals
                : goals.where((g) => g.employeeId == employeeId).toList();
            if (relevant.isEmpty) {
              return Text(
                'No goals set yet.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < relevant.length; i++) ...[
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => showAppDialog<void>(
                      context: context,
                      builder: (_) => _EditEmployeeGoalDialog(
                        goal: relevant[i],
                        isOwnProfile: isOwnProfile,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: _GoalSummaryRow(goal: relevant[i]),
                    ),
                  ),
                  if (i < relevant.length - 1)
                    const Divider(height: 20, color: AppColors.borderSubtle),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

class _GoalSummaryRow extends StatelessWidget {
  const _GoalSummaryRow({required this.goal});

  final Goal goal;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          goal.title,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: goal.achievementPercentage / 100,
                  minHeight: 6,
                  backgroundColor: AppColors.borderSubtle,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${goal.achievementPercentage}%',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// A goal for [employeeId] specifically — no employee/department picker,
/// unlike the standalone Goals page's own Add Goal dialog, since the
/// employee is already fixed by whichever profile this was opened from.
class _AddEmployeeGoalDialog extends ConsumerStatefulWidget {
  const _AddEmployeeGoalDialog({
    required this.employeeId,
    required this.isOwnProfile,
  });

  final String employeeId;
  final bool isOwnProfile;

  @override
  ConsumerState<_AddEmployeeGoalDialog> createState() =>
      _AddEmployeeGoalDialogState();
}

class _AddEmployeeGoalDialogState
    extends ConsumerState<_AddEmployeeGoalDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _submitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _invalidateGoalProviders() {
    ref.invalidate(allGoalsProvider);
    ref.invalidate(myGoalsProvider);
    ref.invalidate(teamGoalsProvider);
    ref.invalidate(myAndTeamGoalsProvider);
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final description = _descriptionController.text.trim().isEmpty
        ? null
        : _descriptionController.text.trim();

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });
    try {
      final repository = ref.read(goalRepositoryProvider);
      if (widget.isOwnProfile) {
        await repository.createForSelf(
          title: _titleController.text,
          description: description,
        );
      } else {
        await repository.createForEmployee(
          employeeId: widget.employeeId,
          title: _titleController.text,
          description: description,
        );
      }
      _invalidateGoalProviders();
      if (!mounted) return;
      Navigator.of(context).pop();
    } on GoalException catch (error) {
      setState(() => _errorMessage = error.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Goal'),
      content: SizedBox(
        width: 380,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_errorMessage != null) ...[
                Text(
                  _errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                const SizedBox(height: 12),
              ],
              TextFormField(
                controller: _titleController,
                enabled: !_submitting,
                decoration: const InputDecoration(labelText: 'Goal'),
                validator: (value) =>
                    (value == null || value.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                enabled: !_submitting,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Add'),
        ),
      ],
    );
  }
}

class _EditEmployeeGoalDialog extends ConsumerStatefulWidget {
  const _EditEmployeeGoalDialog({
    required this.goal,
    required this.isOwnProfile,
  });

  final Goal goal;
  final bool isOwnProfile;

  @override
  ConsumerState<_EditEmployeeGoalDialog> createState() =>
      _EditEmployeeGoalDialogState();
}

class _EditEmployeeGoalDialogState
    extends ConsumerState<_EditEmployeeGoalDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late int _achievementPercentage;
  bool _submitting = false;
  bool _archiving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.goal.title);
    _descriptionController = TextEditingController(
      text: widget.goal.description ?? '',
    );
    _achievementPercentage = widget.goal.achievementPercentage;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _invalidateGoalProviders() {
    ref.invalidate(allGoalsProvider);
    ref.invalidate(myGoalsProvider);
    ref.invalidate(teamGoalsProvider);
    ref.invalidate(myAndTeamGoalsProvider);
  }

  Future<void> _submit() async {
    final description = _descriptionController.text.trim().isEmpty
        ? null
        : _descriptionController.text.trim();

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });
    try {
      final repository = ref.read(goalRepositoryProvider);
      if (widget.isOwnProfile) {
        await repository.updateAsSelf(
          widget.goal.id,
          title: _titleController.text,
          description: description,
          achievementPercentage: _achievementPercentage,
        );
      } else {
        await repository.update(
          widget.goal.id,
          title: _titleController.text,
          description: description,
          achievementPercentage: _achievementPercentage,
        );
      }
      _invalidateGoalProviders();
      if (!mounted) return;
      Navigator.of(context).pop();
    } on GoalException catch (error) {
      setState(() => _errorMessage = error.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _archive() async {
    setState(() {
      _archiving = true;
      _errorMessage = null;
    });
    try {
      final repository = ref.read(goalRepositoryProvider);
      if (widget.isOwnProfile) {
        await repository.archiveAsSelf(widget.goal.id);
      } else {
        await repository.archive(widget.goal.id);
      }
      _invalidateGoalProviders();
      if (!mounted) return;
      Navigator.of(context).pop();
    } on GoalException catch (error) {
      setState(() => _errorMessage = error.message);
    } finally {
      if (mounted) setState(() => _archiving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = _submitting || _archiving;
    return AlertDialog(
      title: const Text('Edit Goal'),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_errorMessage != null) ...[
              Text(
                _errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: _titleController,
              enabled: !busy,
              decoration: const InputDecoration(labelText: 'Goal'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              enabled: !busy,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Achievement: $_achievementPercentage%',
              style: Theme.of(context).textTheme.labelMedium,
            ),
            Slider(
              value: _achievementPercentage.toDouble(),
              min: 0,
              max: 100,
              divisions: 20,
              label: '$_achievementPercentage%',
              onChanged: busy
                  ? null
                  : (value) =>
                        setState(() => _achievementPercentage = value.round()),
            ),
          ],
        ),
      ),
      actionsAlignment: MainAxisAlignment.spaceBetween,
      actions: [
        TextButton(
          onPressed: busy ? null : _archive,
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.error,
          ),
          child: _archiving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Archive'),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(
              onPressed: busy ? null : () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: busy ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
            ),
          ],
        ),
      ],
    );
  }
}
