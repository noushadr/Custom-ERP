import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/utils/date_format.dart';
import '../../../../shared/widgets/form_section.dart';
import '../../../authentication/application/auth_providers.dart';
import '../../../authentication/domain/exceptions/auth_exception.dart';
import '../../../notices/application/notice_providers.dart';
import '../../../notices/domain/entities/notice.dart';
import '../../../requests/application/request_providers.dart';
import '../../../requests/domain/entities/employee_request.dart';
import '../../../requests/domain/exceptions/request_exception.dart';
import '../../application/employee_providers.dart';
import '../../domain/entities/employee.dart';
import '../../domain/exceptions/employee_exception.dart';
import '../widgets/employee_audit_log_panel.dart';
import '../widgets/employee_avatar.dart';
import '../widgets/employee_status_badges.dart';
import 'employee_profile_page.dart';

class UserDashboardPage extends ConsumerWidget {
  const UserDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employeeAsync = ref.watch(myProfileProvider);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1040),
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
        ),
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
          const _CompanyNoticesSection(),
          const SizedBox(height: 16),
          const _MyRequestsSection(),
          const SizedBox(height: 16),
          const _PendingMyApprovalSection(),
          const SizedBox(height: 16),
          const _TeamMembersSection(),
          const SizedBox(height: 16),
          const EmployeeAuditLogPanel(),
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
                      Text(
                        [
                          employee.designation,
                          employee.department?.name,
                        ].whereType<String>().join(' · '),
                        style: Theme.of(context).textTheme.bodyMedium
                            ?.copyWith(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          InfoChip(
                            icon: Icons.badge_outlined,
                            label: employee.employeeCode,
                          ),
                        ],
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
  }
}

void _showChangePasswordDialog(BuildContext context) {
  showDialog<void>(context: context, builder: (_) => const _ChangePasswordDialog());
}

class _ChangePasswordDialog extends ConsumerStatefulWidget {
  const _ChangePasswordDialog();

  @override
  ConsumerState<_ChangePasswordDialog> createState() =>
      _ChangePasswordDialogState();
}

class _ChangePasswordDialogState
    extends ConsumerState<_ChangePasswordDialog> {
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password changed.')),
      );
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

class _CompanyNoticesSection extends ConsumerWidget {
  const _CompanyNoticesSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final noticesAsync = ref.watch(noticeListProvider);

    return FormSection(
      title: 'Company Notices',
      child: noticesAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: LinearProgressIndicator(),
        ),
        error: (_, _) => const Text('Could not load company notices.'),
        data: (notices) {
          if (notices.isEmpty) {
            return Text(
              'No company notices yet.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < notices.length; i++) ...[
                _NoticeRow(notice: notices[i]),
                if (i < notices.length - 1)
                  const Divider(height: 20, color: AppColors.borderSubtle),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _NoticeRow extends StatelessWidget {
  const _NoticeRow({required this.notice});

  final Notice notice;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          notice.title,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(notice.body, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 4),
        Text(
          '${notice.authorName} · ${formatDisplayDateTime(notice.createdAt)}',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _MyRequestsSection extends ConsumerWidget {
  const _MyRequestsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(myRequestsProvider);

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
                    'My Requests',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (_) => const _SubmitRequestDialog(),
                  ),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('New request'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            requestsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: LinearProgressIndicator(),
              ),
              error: (_, _) => const Text('Could not load your requests.'),
              data: (requests) {
                if (requests.isEmpty) {
                  return Text(
                    "You haven't submitted any requests yet.",
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var i = 0; i < requests.length; i++) ...[
                      _MyRequestRow(request: requests[i]),
                      if (i < requests.length - 1)
                        const Divider(
                          height: 20,
                          color: AppColors.borderSubtle,
                        ),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MyRequestRow extends StatelessWidget {
  const _MyRequestRow({required this.request});

  final EmployeeRequest request;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                request.subject,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            _RequestStatusBadge(status: request.status),
          ],
        ),
        const SizedBox(height: 4),
        Text(request.description, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 4),
        Text(
          formatDisplayDateTime(request.createdAt),
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
        ),
        if (request.rejectionReason != null) ...[
          const SizedBox(height: 4),
          Text(
            'Reason: ${request.rejectionReason}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.error,
            ),
          ),
        ],
      ],
    );
  }
}

class _RequestStatusBadge extends StatelessWidget {
  const _RequestStatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'submitted' => ('Submitted', AppColors.warning),
      'manager_approved' => ('Manager Approved', AppColors.primary),
      'completed' => ('Completed', AppColors.success),
      'rejected' => ('Rejected', AppColors.error),
      _ => (status, AppColors.textSecondary),
    };
    return StatusBadge(label: label, color: color);
  }
}

class _SubmitRequestDialog extends ConsumerStatefulWidget {
  const _SubmitRequestDialog();

  @override
  ConsumerState<_SubmitRequestDialog> createState() =>
      _SubmitRequestDialogState();
}

class _SubmitRequestDialogState extends ConsumerState<_SubmitRequestDialog> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _typeController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _submitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _subjectController.dispose();
    _typeController.dispose();
    _descriptionController.dispose();
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
          .read(requestRepositoryProvider)
          .submit(
            subject: _subjectController.text,
            description: _descriptionController.text,
            type: _typeController.text.trim().isEmpty
                ? null
                : _typeController.text.trim(),
          );
      ref.invalidate(myRequestsProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
    } on RequestException catch (error) {
      setState(() => _errorMessage = error.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New request'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_errorMessage != null) ...[
                Text(
                  _errorMessage!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
                const SizedBox(height: 12),
              ],
              TextFormField(
                controller: _subjectController,
                decoration: const InputDecoration(labelText: 'Subject'),
                validator: (value) =>
                    (value == null || value.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _typeController,
                decoration: const InputDecoration(
                  labelText: 'Category (optional)',
                  hintText: 'e.g. Equipment, Document, Access',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Description'),
                validator: (value) =>
                    (value == null || value.isEmpty) ? 'Required' : null,
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
              : const Text('Submit'),
        ),
      ],
    );
  }
}

/// Requests submitted by one of this viewer's direct reports, awaiting their
/// approval as reporting manager. Empty for anyone without direct reports.
class _PendingMyApprovalSection extends ConsumerWidget {
  const _PendingMyApprovalSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(pendingManagerApprovalRequestsProvider);

    return FormSection(
      title: 'Requests Awaiting My Approval',
      child: requestsAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: LinearProgressIndicator(),
        ),
        error: (_, _) => const Text('Could not load pending requests.'),
        data: (requests) {
          if (requests.isEmpty) {
            return Text(
              'Nothing is waiting for your approval.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < requests.length; i++) ...[
                _PendingManagerRequestRow(request: requests[i]),
                if (i < requests.length - 1)
                  const Divider(height: 20, color: AppColors.borderSubtle),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _PendingManagerRequestRow extends ConsumerStatefulWidget {
  const _PendingManagerRequestRow({required this.request});

  final EmployeeRequest request;

  @override
  ConsumerState<_PendingManagerRequestRow> createState() =>
      _PendingManagerRequestRowState();
}

class _PendingManagerRequestRowState
    extends ConsumerState<_PendingManagerRequestRow> {
  bool _working = false;

  Future<void> _decide(bool approve) async {
    setState(() => _working = true);
    try {
      if (approve) {
        await ref
            .read(requestRepositoryProvider)
            .approveAsManager(widget.request.id);
      } else {
        await ref
            .read(requestRepositoryProvider)
            .rejectAsManager(widget.request.id);
      }
      ref.invalidate(pendingManagerApprovalRequestsProvider);
    } on RequestException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final request = widget.request;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${request.subject} — ${request.requesterName}',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                request.description,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        if (_working)
          const Padding(
            padding: EdgeInsets.all(8),
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
        else ...[
          TextButton(
            onPressed: () => _decide(false),
            child: const Text('Reject'),
          ),
          FilledButton(
            onPressed: () => _decide(true),
            child: const Text('Approve'),
          ),
        ],
      ],
    );
  }
}

class _TeamMembersSection extends ConsumerWidget {
  const _TeamMembersSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportsAsync = ref.watch(myDirectReportsProvider);

    return FormSection(
      title: 'Team Members',
      child: reportsAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: LinearProgressIndicator(),
        ),
        error: (_, _) => const Text('Could not load your team members.'),
        data: (reports) {
          if (reports.isEmpty) {
            return Text(
              'No team members are assigned to you yet.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            );
          }
          return Wrap(
            spacing: 16,
            runSpacing: 12,
            children: [
              for (final report in reports) _TeamMemberTile(employee: report),
            ],
          );
        },
      ),
    );
  }
}

class _TeamMemberTile extends StatelessWidget {
  const _TeamMemberTile({required this.employee});

  final Employee employee;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 220),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          EmployeeAvatar(
            fullName: employee.fullName,
            photoUrl: employee.profilePhotoUrl,
            radius: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  employee.fullName,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium,
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
    );
  }
}
