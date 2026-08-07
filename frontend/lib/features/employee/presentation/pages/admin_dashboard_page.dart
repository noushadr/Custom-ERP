import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/form_section.dart';
import '../../../../shared/widgets/metric_card.dart';
import '../../../authentication/application/auth_providers.dart';
import '../../../authentication/application/auth_state.dart';
import '../../../notices/application/notice_providers.dart';
import '../../../notices/domain/exceptions/notice_exception.dart';
import '../../../requests/application/request_providers.dart';
import '../../../requests/domain/entities/employee_request.dart';
import '../../../requests/domain/exceptions/request_exception.dart';
import '../../application/employee_providers.dart';
import '../../domain/entities/employee.dart';
import '../widgets/company_audit_log_section.dart';

class AdminDashboardPage extends ConsumerWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employeesAsync = ref.watch(employeeListProvider);
    final authState = ref.watch(authControllerProvider);
    final canViewAllAudit =
        authState is AuthAuthenticated &&
        authState.user.hasPermission('audit.viewAll');

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1040),
          child: employeesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(
              child: Text(
                'Could not load dashboard stats. Please try again.',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
            data: (employees) => _DashboardStats(
              employees: employees,
              showCompanyAuditLog: canViewAllAudit,
            ),
          ),
        ),
      ),
    );
  }
}

class _DashboardStats extends StatelessWidget {
  const _DashboardStats({
    required this.employees,
    required this.showCompanyAuditLog,
  });

  final List<Employee> employees;
  final bool showCompanyAuditLog;

  @override
  Widget build(BuildContext context) {
    final total = employees.length;
    final departmentCount = employees
        .map((e) => e.department?.id)
        .whereType<String>()
        .toSet()
        .length;
    final pendingInvites = employees
        .where((e) => e.accountStatus == 'pending_invite')
        .length;
    final now = DateTime.now();
    final newHiresThisMonth = employees.where((e) {
      final joined = DateTime.tryParse(e.joiningDate);
      return joined != null &&
          joined.year == now.year &&
          joined.month == now.month;
    }).length;
    final avgProfileCompletion = total == 0
        ? 0
        : (employees.map((e) => e.profileCompletionPercentage).reduce(
                (a, b) => a + b,
              ) /
              total)
              .round();

    final byStatus = <String, int>{};
    final byWorkMode = <String, int>{};
    for (final employee in employees) {
      byStatus.update(
        employee.employmentStatus,
        (count) => count + 1,
        ifAbsent: () => 1,
      );
      byWorkMode.update(
        employee.workMode,
        (count) => count + 1,
        ifAbsent: () => 1,
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: const _SectionHeader('Overview')),
              FilledButton.icon(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => const _PostNoticeDialog(),
                ),
                icon: const Icon(Icons.campaign_outlined, size: 16),
                label: const Text('Post notice'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              MetricCard(
                label: 'Total Employees',
                value: '$total',
                color: AppColors.primary,
              ),
              MetricCard(
                label: 'Departments',
                value: '$departmentCount',
                color: AppColors.primary,
              ),
              MetricCard(
                label: 'Pending Invites',
                value: '$pendingInvites',
                color: AppColors.warning,
              ),
              MetricCard(
                label: 'New Hires (This Month)',
                value: '$newHiresThisMonth',
                color: AppColors.success,
              ),
              MetricCard(
                label: 'Avg. Profile Completion',
                value: '$avgProfileCompletion%',
                color: AppColors.textSecondary,
              ),
            ],
          ),
          const SizedBox(height: 18),
          const _SectionHeader('Employment Status'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              MetricCard(
                label: 'Active',
                value: '${byStatus['active'] ?? 0}',
                color: AppColors.success,
              ),
              MetricCard(
                label: 'On Leave',
                value: '${byStatus['on_leave'] ?? 0}',
                color: AppColors.warning,
              ),
              MetricCard(
                label: 'Notice Period',
                value: '${byStatus['notice_period'] ?? 0}',
                color: AppColors.warning,
              ),
              MetricCard(
                label: 'Resigned',
                value: '${byStatus['resigned'] ?? 0}',
                color: AppColors.error,
              ),
              MetricCard(
                label: 'Terminated',
                value: '${byStatus['terminated'] ?? 0}',
                color: AppColors.error,
              ),
            ],
          ),
          const SizedBox(height: 18),
          const _SectionHeader('Work Mode'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              MetricCard(
                label: 'On-site',
                value: '${byWorkMode['on_site'] ?? 0}',
                color: AppColors.textSecondary,
              ),
              MetricCard(
                label: 'Remote',
                value: '${byWorkMode['remote'] ?? 0}',
                color: AppColors.textSecondary,
              ),
              MetricCard(
                label: 'Hybrid',
                value: '${byWorkMode['hybrid'] ?? 0}',
                color: AppColors.textSecondary,
              ),
            ],
          ),
          const SizedBox(height: 18),
          const _PendingHrApprovalSection(),
          if (showCompanyAuditLog) ...[
            const SizedBox(height: 18),
            const CompanyAuditLogSection(),
          ],
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(title, style: Theme.of(context).textTheme.titleMedium);
  }
}

class _PostNoticeDialog extends ConsumerStatefulWidget {
  const _PostNoticeDialog();

  @override
  ConsumerState<_PostNoticeDialog> createState() => _PostNoticeDialogState();
}

class _PostNoticeDialogState extends ConsumerState<_PostNoticeDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  bool _submitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
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
          .read(noticeRepositoryProvider)
          .create(title: _titleController.text, body: _bodyController.text);
      ref.invalidate(noticeListProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
    } on NoticeException catch (error) {
      setState(() => _errorMessage = error.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Post a company notice'),
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
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (value) =>
                    (value == null || value.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _bodyController,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Message'),
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
              : const Text('Post'),
        ),
      ],
    );
  }
}

/// Requests that have cleared manager approval and are awaiting the final
/// HR/Admin decision.
class _PendingHrApprovalSection extends ConsumerWidget {
  const _PendingHrApprovalSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(pendingHrApprovalRequestsProvider);

    return FormSection(
      title: 'Requests Awaiting HR Approval',
      child: requestsAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: LinearProgressIndicator(),
        ),
        error: (_, _) => const Text('Could not load pending requests.'),
        data: (requests) {
          if (requests.isEmpty) {
            return Text(
              'Nothing is awaiting HR approval right now.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < requests.length; i++) ...[
                _PendingHrRequestRow(request: requests[i]),
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

class _PendingHrRequestRow extends ConsumerStatefulWidget {
  const _PendingHrRequestRow({required this.request});

  final EmployeeRequest request;

  @override
  ConsumerState<_PendingHrRequestRow> createState() =>
      _PendingHrRequestRowState();
}

class _PendingHrRequestRowState extends ConsumerState<_PendingHrRequestRow> {
  bool _working = false;

  Future<void> _decide(bool approve) async {
    setState(() => _working = true);
    try {
      if (approve) {
        await ref
            .read(requestRepositoryProvider)
            .approveAsHr(widget.request.id);
      } else {
        await ref.read(requestRepositoryProvider).rejectAsHr(widget.request.id);
      }
      ref.invalidate(pendingHrApprovalRequestsProvider);
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
              const SizedBox(height: 4),
              Text(
                'Approved by manager: ${request.managerDecisionByName ?? '—'}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
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
