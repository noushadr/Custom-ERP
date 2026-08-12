import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/form_section.dart';
import '../../../authentication/application/auth_providers.dart';
import '../../../authentication/application/auth_state.dart';
import '../../../employee/presentation/widgets/employee_status_badges.dart';
import '../../application/leave_providers.dart';
import '../../domain/entities/leave_balance.dart';
import '../../domain/entities/leave_request.dart';
import '../../domain/exceptions/leave_exception.dart';
import '../utils/leave_format_utils.dart';
import '../widgets/leave_calendar_view.dart';
import 'leave_settings_page.dart';

/// Consolidates everything about leave in one place: the viewer's own
/// balances and submitted requests, requests awaiting their approval as a
/// reporting manager, and — for HR/Admin — requests awaiting the final
/// HR/Admin decision.
class LeavePage extends ConsumerWidget {
  const LeavePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final authUser = authState is AuthAuthenticated ? authState.user : null;
    final canSeeHrApprovals = authUser?.hasPermission('leave.manage') ?? false;
    // Super Admin has no Employee profile (see RequestsPage), so they have no
    // personal leave balance or history of their own — only the approval
    // sections and (via leave.manage) the settings/reset banner apply.
    final isSuperAdmin = authUser?.role == 'Super Admin';

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1040),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (canSeeHrApprovals) ...[
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const LeaveSettingsPage(),
                        ),
                      ),
                      icon: const Icon(Icons.settings_outlined, size: 16),
                      label: const Text('Leave Settings'),
                    ),
                  ),
                  const _ResetReminderBanner(),
                  const SizedBox(height: 16),
                ],
                if (!isSuperAdmin) ...[
                  const _BalancesSection(),
                  const SizedBox(height: 16),
                  const _MyLeaveRequestsSection(),
                  const SizedBox(height: 16),
                ],
                const LeaveCalendarView(),
                const SizedBox(height: 16),
                const _PendingMyApprovalSection(),
                if (canSeeHrApprovals) ...[
                  const SizedBox(height: 16),
                  const _PendingHrApprovalSection(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BalancesSection extends ConsumerWidget {
  const _BalancesSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balancesAsync = ref.watch(myLeaveBalancesProvider);

    return balancesAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: LinearProgressIndicator(),
      ),
      error: (_, _) => const Text('Could not load your leave balances.'),
      data: (balances) {
        if (balances.isEmpty) return const SizedBox.shrink();
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [for (final balance in balances) _BalanceCard(balance: balance)],
        );
      },
    );
  }
}

/// Shown to Super Admin/HR only, when the current year's leave balances
/// haven't been initialized yet — a derived on-load check rather than a
/// backend cron job, so it stays correct even if the server was offline
/// exactly at midnight on Jan 1st.
class _ResetReminderBanner extends ConsumerStatefulWidget {
  const _ResetReminderBanner();

  @override
  ConsumerState<_ResetReminderBanner> createState() =>
      _ResetReminderBannerState();
}

class _ResetReminderBannerState extends ConsumerState<_ResetReminderBanner> {
  bool _resetting = false;

  Future<void> _runReset() async {
    setState(() => _resetting = true);
    try {
      await ref.read(leaveRepositoryProvider).runAnnualReset();
      ref.invalidate(leaveResetStatusProvider);
      ref.invalidate(myLeaveBalancesProvider);
    } on LeaveException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _resetting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusAsync = ref.watch(leaveResetStatusProvider);
    final status = statusAsync.valueOrNull;
    if (status == null || status.isInitialized) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.event_repeat, color: AppColors.warning),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "Annual leave balances for ${status.year} haven't been set up "
              'yet. Employees will see last year\'s figures until you reset.',
            ),
          ),
          const SizedBox(width: 12),
          FilledButton(
            onPressed: _resetting ? null : _runReset,
            child: _resetting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Reset now'),
          ),
        ],
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.balance});

  final LeaveBalance balance;

  @override
  Widget build(BuildContext context) {
    final color = parseLeaveColor(balance.colorHex) ?? AppColors.primary;
    return Container(
      width: 190,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  balance.leaveTypeName,
                  style: Theme.of(context).textTheme.titleSmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            formatLeaveDays(balance.remaining),
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          Text(
            'remaining of ${formatLeaveDays(balance.allocated)}',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _MyLeaveRequestsSection extends ConsumerWidget {
  const _MyLeaveRequestsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(myLeaveRequestsProvider);

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
                    'My Leave Requests',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                FilledButton.icon(
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (_) => const _ApplyLeaveDialog(),
                  ),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Apply for leave'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            requestsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: LinearProgressIndicator(),
              ),
              error: (_, _) => const Text('Could not load your leave requests.'),
              data: (requests) {
                if (requests.isEmpty) {
                  return Text(
                    "You haven't applied for any leave yet.",
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var i = 0; i < requests.length; i++) ...[
                      _MyLeaveRequestRow(request: requests[i]),
                      if (i < requests.length - 1)
                        const Divider(height: 20, color: AppColors.borderSubtle),
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

class _MyLeaveRequestRow extends ConsumerStatefulWidget {
  const _MyLeaveRequestRow({required this.request});

  final LeaveRequest request;

  @override
  ConsumerState<_MyLeaveRequestRow> createState() => _MyLeaveRequestRowState();
}

class _MyLeaveRequestRowState extends ConsumerState<_MyLeaveRequestRow> {
  bool _cancelling = false;

  bool get _isPending =>
      widget.request.status == 'submitted' ||
      widget.request.status == 'manager_approved';

  Future<void> _cancel() async {
    setState(() => _cancelling = true);
    try {
      await ref.read(leaveRepositoryProvider).cancelLeaveRequest(widget.request.id);
      ref.invalidate(myLeaveRequestsProvider);
    } on LeaveException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _cancelling = false);
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
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${request.leaveTypeName} — ${request.startDate} to ${request.endDate}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  _LeaveStatusBadge(status: request.status),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${formatLeaveDays(request.numberOfDays)} day(s) — ${request.reason}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (request.managerComment != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Manager: ${request.managerComment}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
              if (request.hrComment != null) ...[
                const SizedBox(height: 4),
                Text(
                  'HR/Admin: ${request.hrComment}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (_isPending) ...[
          const SizedBox(width: 8),
          _cancelling
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : TextButton(onPressed: _cancel, child: const Text('Cancel')),
        ],
      ],
    );
  }
}

class _LeaveStatusBadge extends StatelessWidget {
  const _LeaveStatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'submitted' => ('Submitted', AppColors.warning),
      'manager_approved' => ('Manager Approved', AppColors.primary),
      'approved' => ('Approved', AppColors.success),
      'rejected' => ('Rejected', AppColors.error),
      'cancelled' => ('Cancelled', AppColors.textSecondary),
      _ => (status, AppColors.textSecondary),
    };
    return StatusBadge(label: label, color: color);
  }
}

class _ApplyLeaveDialog extends ConsumerStatefulWidget {
  const _ApplyLeaveDialog();

  @override
  ConsumerState<_ApplyLeaveDialog> createState() => _ApplyLeaveDialogState();
}

class _ApplyLeaveDialogState extends ConsumerState<_ApplyLeaveDialog> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  String? _leaveTypeId;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _submitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  static String _isoDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  Future<void> _pickDate({required bool isStart}) async {
    final initial = (isStart ? _startDate : _endDate) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startDate = picked;
      } else {
        _endDate = picked;
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_leaveTypeId == null || _startDate == null || _endDate == null) {
      setState(() => _errorMessage = 'Please fill in every field.');
      return;
    }
    if (_endDate!.isBefore(_startDate!)) {
      setState(() => _errorMessage = 'End date must be on or after the start date.');
      return;
    }

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    try {
      await ref
          .read(leaveRepositoryProvider)
          .submitLeaveRequest(
            leaveTypeId: _leaveTypeId!,
            startDate: _isoDate(_startDate!),
            endDate: _isoDate(_endDate!),
            reason: _reasonController.text.trim(),
          );
      ref.invalidate(myLeaveRequestsProvider);
      ref.invalidate(myLeaveBalancesProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
    } on LeaveException catch (error) {
      setState(() => _errorMessage = error.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final leaveTypesAsync = ref.watch(leaveTypesProvider(false));

    return AlertDialog(
      title: const Text('Apply for leave'),
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
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                const SizedBox(height: 12),
              ],
              leaveTypesAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (_, _) => const Text('Could not load leave types.'),
                data: (leaveTypes) => DropdownButtonFormField<String>(
                  initialValue: _leaveTypeId,
                  decoration: const InputDecoration(labelText: 'Leave type'),
                  items: [
                    for (final type in leaveTypes)
                      DropdownMenuItem(value: type.id, child: Text(type.name)),
                  ],
                  onChanged: _submitting
                      ? null
                      : (value) => setState(() => _leaveTypeId = value),
                  validator: (value) => value == null ? 'Required' : null,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      key: const Key('leave-start-date'),
                      onTap: _submitting ? null : () => _pickDate(isStart: true),
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'Start date'),
                        child: Text(
                          _startDate == null ? '—' : _isoDate(_startDate!),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      key: const Key('leave-end-date'),
                      onTap: _submitting ? null : () => _pickDate(isStart: false),
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'End date'),
                        child: Text(
                          _endDate == null ? '—' : _isoDate(_endDate!),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _reasonController,
                enabled: !_submitting,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Reason'),
                validator: (value) =>
                    (value == null || value.trim().isEmpty) ? 'Required' : null,
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
    final requestsAsync = ref.watch(pendingManagerApprovalLeaveRequestsProvider);

    return FormSection(
      title: 'Leave Requests Awaiting My Approval',
      child: requestsAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: LinearProgressIndicator(),
        ),
        error: (_, _) => const Text('Could not load pending leave requests.'),
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
                _PendingLeaveRequestRow(
                  request: requests[i],
                  onApprove: (id, comment) =>
                      ref.read(leaveRepositoryProvider).approveAsManager(id, comment: comment),
                  onReject: (id, comment) =>
                      ref.read(leaveRepositoryProvider).rejectAsManager(id, comment: comment),
                  onDecided: () =>
                      ref.invalidate(pendingManagerApprovalLeaveRequestsProvider),
                ),
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

/// Requests that have cleared manager approval and are awaiting the final
/// HR/Admin decision.
class _PendingHrApprovalSection extends ConsumerWidget {
  const _PendingHrApprovalSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(pendingHrApprovalLeaveRequestsProvider);

    return FormSection(
      title: 'Leave Requests Awaiting HR Approval',
      child: requestsAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: LinearProgressIndicator(),
        ),
        error: (_, _) => const Text('Could not load pending leave requests.'),
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
                _PendingLeaveRequestRow(
                  request: requests[i],
                  onApprove: (id, comment) =>
                      ref.read(leaveRepositoryProvider).approveAsHr(id, comment: comment),
                  onReject: (id, comment) =>
                      ref.read(leaveRepositoryProvider).rejectAsHr(id, comment: comment),
                  onDecided: () {
                    ref.invalidate(pendingHrApprovalLeaveRequestsProvider);
                    ref.invalidate(myLeaveBalancesProvider);
                  },
                ),
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

class _PendingLeaveRequestRow extends ConsumerStatefulWidget {
  const _PendingLeaveRequestRow({
    required this.request,
    required this.onApprove,
    required this.onReject,
    required this.onDecided,
  });

  final LeaveRequest request;
  final Future<LeaveRequest> Function(String id, String? comment) onApprove;
  final Future<LeaveRequest> Function(String id, String? comment) onReject;
  final VoidCallback onDecided;

  @override
  ConsumerState<_PendingLeaveRequestRow> createState() =>
      _PendingLeaveRequestRowState();
}

class _PendingLeaveRequestRowState
    extends ConsumerState<_PendingLeaveRequestRow> {
  bool _working = false;

  Future<void> _decide(bool approve) async {
    final comment = await _promptForComment(approve);
    if (comment == null) return;

    setState(() => _working = true);
    try {
      if (approve) {
        await widget.onApprove(widget.request.id, comment.isEmpty ? null : comment);
      } else {
        await widget.onReject(widget.request.id, comment.isEmpty ? null : comment);
      }
      widget.onDecided();
    } on LeaveException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<String?> _promptForComment(bool approve) {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(approve ? 'Approve leave request' : 'Reject leave request'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Comment (optional)'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text.trim()),
            child: Text(approve ? 'Approve' : 'Reject'),
          ),
        ],
      ),
    );
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
                '${request.leaveTypeName} — ${request.requesterName}',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                '${request.startDate} to ${request.endDate} · ${formatLeaveDays(request.numberOfDays)} day(s)',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 4),
              Text(
                request.reason,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              if (request.managerDecisionByName != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Approved by manager: ${request.managerDecisionByName}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
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
