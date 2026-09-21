import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/models/named_ref.dart';
import '../../../../shared/utils/date_format.dart';
import '../../../../shared/widgets/form_section.dart';
import '../../../../shared/widgets/responsive_card_row.dart';
import '../../../authentication/application/auth_providers.dart';
import '../../../authentication/domain/exceptions/auth_exception.dart';
import '../../../goals/application/goal_providers.dart';
import '../../../leave/presentation/widgets/leave_balances_section.dart';
import '../../../performance_reviews/application/performance_review_providers.dart';
import '../../../performance_reviews/domain/entities/performance_review_summary.dart';
import '../../../tasks/application/task_providers.dart';
import '../../../tasks/domain/entities/task.dart';
import '../../../tasks/presentation/pages/task_detail_page.dart';
import '../../../tasks/presentation/widgets/task_badges.dart';
import '../../application/employee_providers.dart';
import '../../domain/entities/employee.dart';
import '../../domain/exceptions/employee_exception.dart';
import '../widgets/company_notices_section.dart';
import '../widgets/employee_avatar.dart';
import '../widgets/employee_status_badges.dart';
import 'employee_profile_page.dart';

class UserDashboardPage extends ConsumerWidget {
  const UserDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employeeAsync = ref.watch(myProfileProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: employeeAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text(
            error is EmployeeException && error.message == 'Not found.'
                ? "This login isn't linked to an employee profile, so "
                      "there's nothing personal to show here."
                : 'Could not load your dashboard. Please try again.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
        data: (employee) => _UserDashboardBody(employee: employee),
      ),
    );
  }
}

class _UserDashboardBody extends StatelessWidget {
  const _UserDashboardBody({required this.employee});

  final Employee employee;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ProfileSummaryCard(employee: employee),
          const SizedBox(height: 16),
          const CompanyNoticesSection(),
          const SizedBox(height: 16),
          const FormSection(
            title: 'Leave Balances',
            child: LeaveBalancesSection(),
          ),
          const SizedBox(height: 16),
          const _MyGoalsSection(),
          const SizedBox(height: 16),
          const _MyTasksSection(),
          const SizedBox(height: 16),
          const _TeamMembersSection(),
        ],
      ),
    );
  }
}

class _ProfileSummaryCard extends StatelessWidget {
  const _ProfileSummaryCard({required this.employee});

  final Employee employee;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                      if (employee.designation != null)
                        Text(
                          employee.designation!,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _showChangePasswordDialog(context),
                      icon: const Icon(Icons.password, size: 16),
                      label: const Text('Change password'),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              const EmployeeProfilePage(employeeId: null),
                        ),
                      ),
                      child: const Text('View full profile'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            // A full-width row rather than nested inside the Expanded above,
            // so these chips still have room to wrap at narrow widths instead
            // of being squeezed by the button column next to them. The
            // completion ring trails the chips on the same row (rather than
            // its own full-width bar below) so the row's right side never
            // reads as empty dead space on a wide screen.
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      InfoChip(
                        icon: Icons.badge_outlined,
                        label: employee.employeeCode,
                      ),
                      EmploymentStatusBadge(status: employee.employmentStatus),
                      WorkModeBadge(workMode: employee.workMode),
                      if (employee.department != null)
                        InfoChip(
                          icon: Icons.apartment_outlined,
                          label: 'Department: ${employee.department!.name}',
                        ),
                      if (employee.reportingManager != null)
                        _ReportingManagerChip(
                          manager: employee.reportingManager!,
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                _ProfileCompletionRing(
                  percentage: employee.profileCompletionPercentage,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// A compact ring gauge for `profileCompletionPercentage` — replaces the old
/// full-width linear bar + caption below the info chips, so this reads at a
/// glance instead of needing its own row, and the color scales with
/// completeness (amber while incomplete, green once done) rather than
/// staying a single flat tone regardless of progress.
class _ProfileCompletionRing extends StatelessWidget {
  const _ProfileCompletionRing({required this.percentage});

  final int percentage;

  @override
  Widget build(BuildContext context) {
    final isComplete = percentage >= 100;
    final ringColor = isComplete ? AppColors.success : AppColors.warning;

    return Tooltip(
      message: 'Profile $percentage% complete',
      child: SizedBox(
        width: 46,
        height: 46,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 46,
              height: 46,
              child: CircularProgressIndicator(
                value: percentage / 100,
                strokeWidth: 4,
                strokeCap: StrokeCap.round,
                backgroundColor: AppColors.borderSubtle,
                valueColor: AlwaysStoppedAnimation(ringColor),
              ),
            ),
            isComplete
                ? Icon(Icons.check, size: 18, color: ringColor)
                : Text(
                    '$percentage%',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: ringColor,
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

class _ReportingManagerChip extends StatelessWidget {
  const _ReportingManagerChip({required this.manager});

  final NamedRef manager;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => EmployeeProfilePage(employeeId: manager.id),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          EmployeeAvatar(
            fullName: manager.name,
            photoUrl: manager.photoUrl,
            radius: 12,
          ),
          const SizedBox(width: 6),
          Text(
            'Reporting Manager: ${manager.name}',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

void _showChangePasswordDialog(BuildContext context) {
  showDialog<void>(
    context: context,
    builder: (_) => const _ChangePasswordDialog(),
  );
}

class _ChangePasswordDialog extends ConsumerStatefulWidget {
  const _ChangePasswordDialog();

  @override
  ConsumerState<_ChangePasswordDialog> createState() =>
      _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends ConsumerState<_ChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _submitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    try {
      await ref
          .read(authControllerProvider.notifier)
          .changePassword(_currentController.text, _newController.text);
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Password changed.')));
    } on AuthException catch (error) {
      setState(() => _errorMessage = error.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Change password'),
      content: Form(
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
              controller: _currentController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Current password'),
              validator: (value) =>
                  (value == null || value.isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _newController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'New password'),
              validator: (value) {
                if (value == null || value.length < 8) {
                  return 'Must be at least 8 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _confirmController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirm new password',
              ),
              validator: (value) =>
                  value != _newController.text ? "Passwords don't match" : null,
            ),
          ],
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
              : const Text('Change password'),
        ),
      ],
    );
  }
}

/// Read-only — goals are set by Admin/HR or the viewer's own Team Lead
/// (see `GoalsPage`), the employee just sees them here.
class _MyGoalsSection extends ConsumerWidget {
  const _MyGoalsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(myGoalsProvider);

    return FormSection(
      title: 'My Goals',
      child: goalsAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: LinearProgressIndicator(),
        ),
        error: (_, _) => const Text('Could not load your goals.'),
        data: (goals) {
          if (goals.isEmpty) {
            return Text(
              'No goals have been set for you yet.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < goals.length; i++) ...[
                Text(
                  goals[i].title,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                if (goals[i].description != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    goals[i].description!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: goals[i].achievementPercentage / 100,
                          minHeight: 6,
                          backgroundColor: AppColors.borderSubtle,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${goals[i].achievementPercentage}%',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Set by ${goals[i].createdByName}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                if (i < goals.length - 1)
                  const Divider(height: 20, color: AppColors.borderSubtle),
              ],
            ],
          );
        },
      ),
    );
  }
}

/// Both directions at a glance: tasks assigned to the viewer, and tasks the
/// viewer assigned to someone else — the same two providers the Tasks
/// page's own "My Tasks"/"Assigned Tasks" tabs use, just summarized here
/// rather than as a full board. Tapping a row opens that task's detail
/// page directly.
class _MyTasksSection extends ConsumerWidget {
  const _MyTasksSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myTasksAsync = ref.watch(myTasksProvider);
    final assignedByMeAsync = ref.watch(tasksAssignedByMeProvider);

    return FormSection(
      title: 'My Tasks',
      child: myTasksAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: LinearProgressIndicator(),
        ),
        error: (_, _) => const Text('Could not load your tasks.'),
        data: (myTasks) => assignedByMeAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: LinearProgressIndicator(),
          ),
          error: (_, _) => const Text('Could not load your tasks.'),
          data: (assignedByMe) {
            if (myTasks.isEmpty && assignedByMe.isEmpty) {
              return Text(
                'No tasks yet.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (myTasks.isNotEmpty) ...[
                  Text(
                    'Assigned to you',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 8),
                  for (var i = 0; i < myTasks.length; i++) ...[
                    _TaskSummaryRow(task: myTasks[i]),
                    if (i < myTasks.length - 1)
                      const Divider(height: 16, color: AppColors.borderSubtle),
                  ],
                ],
                if (myTasks.isNotEmpty && assignedByMe.isNotEmpty)
                  const SizedBox(height: 16),
                if (assignedByMe.isNotEmpty) ...[
                  Text(
                    'Assigned by you',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 8),
                  for (var i = 0; i < assignedByMe.length; i++) ...[
                    _TaskSummaryRow(task: assignedByMe[i]),
                    if (i < assignedByMe.length - 1)
                      const Divider(height: 16, color: AppColors.borderSubtle),
                  ],
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _TaskSummaryRow extends StatelessWidget {
  const _TaskSummaryRow({required this.task});

  final Task task;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => TaskDetailPage(taskId: task.id)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    task.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Due ${formatDisplayDate(task.dueDate)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            TaskStatusBadge(status: task.status, dense: true),
            const SizedBox(width: 4),
            const Icon(
              Icons.chevron_right,
              size: 18,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

/// Hidden entirely once it's known the viewer has no direct reports — a
/// "My Team" card with nothing in it (and the old "No team members are
/// assigned to you yet." filler text) was dead weight for the majority of
/// employees who don't lead anyone. Still renders normally (with its own
/// loading/error states) for anyone who does.
class _TeamMembersSection extends ConsumerWidget {
  const _TeamMembersSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportsAsync = ref.watch(myDirectReportsProvider);

    return reportsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const FormSection(
        title: 'My Team',
        child: Text('Could not load your team members.'),
      ),
      data: (reports) {
        if (reports.isEmpty) return const SizedBox.shrink();
        return _TeamMembersList(reports: reports);
      },
    );
  }
}

class _TeamMembersList extends ConsumerWidget {
  const _TeamMembersList({required this.reports});

  final List<Employee> reports;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewSummariesAsync = ref.watch(
      latestPerformanceReviewsForMyTeamProvider,
    );
    final reviewSummaries =
        reviewSummariesAsync.valueOrNull ??
        const <String, PerformanceReviewSummary>{};

    return FormSection(
      title: 'My Team (${reports.length})',
      child: ResponsiveCardRow(
        minItemWidth: _teamTileWidth,
        spacing: 16,
        runSpacing: 16,
        children: [
          for (final report in reports)
            _TeamMemberTile(
              employee: report,
              reviewSummary: reviewSummaries[report.id],
            ),
        ],
      ),
    );
  }
}

const _teamTileWidth = 260.0;

class _TeamMemberTile extends StatelessWidget {
  const _TeamMemberTile({required this.employee, this.reviewSummary});

  final Employee employee;
  final PerformanceReviewSummary? reviewSummary;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => EmployeeProfilePage(employeeId: employee.id),
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          // The chips need an explicit max width to know when to ellipsize —
          // read from the tile's own rendered width (no longer fixed, now
          // that ResponsiveCardRow stretches it to fill its row) rather than
          // a hardcoded constant.
          child: LayoutBuilder(
            builder: (context, constraints) =>
                _buildContent(context, contentWidth: constraints.maxWidth - 32),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, {required double contentWidth}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            EmployeeAvatar(
              fullName: employee.fullName,
              photoUrl: employee.profilePhotoUrl,
              radius: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    employee.fullName,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  Text(
                    employee.designation ?? employee.role,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 8,
          children: [
            WorkModeBadge(workMode: employee.workMode, dense: true),
            StatusBadge(
              label: formatEmploymentType(employee.employmentType),
              color: AppColors.textSecondary,
              icon: Icons.work_outline,
              dense: true,
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 8,
          children: [
            InfoChip(
              icon: Icons.email_outlined,
              label: employee.email,
              maxWidth: contentWidth,
            ),
            InfoChip(
              icon: Icons.timelapse_outlined,
              label: formatTenure(employee.joiningDate),
              maxWidth: contentWidth,
            ),
            InfoChip(
              icon: Icons.cake_outlined,
              label: employee.dateOfBirth == null
                  ? '—'
                  : formatMonthDay(employee.dateOfBirth!),
              maxWidth: contentWidth,
            ),
            InfoChip(
              icon: Icons.fact_check_outlined,
              label: _reviewLabel(reviewSummary),
              maxWidth: contentWidth,
            ),
          ],
        ),
      ],
    );
  }

  /// "Last Performance Review: " followed by the date once
  /// completed/finalized, "Last Performance Review: Pending" while awaiting
  /// it, or "No review yet" before their first work anniversary.
  String _reviewLabel(PerformanceReviewSummary? summary) {
    if (summary == null) return 'No review yet';
    if (summary.status == 'pending') {
      return 'Last Performance Review: Pending';
    }
    final doneAt = summary.finalizedAt ?? summary.completedAt;
    if (doneAt == null) return 'Last Performance Review: Pending';
    return 'Last Performance Review: ${formatDisplayDateOnly(doneAt)}';
  }
}
