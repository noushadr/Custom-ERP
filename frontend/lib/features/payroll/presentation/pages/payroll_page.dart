import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/utils/currency_format.dart';
import '../../../../shared/widgets/department_breakdown_section.dart';
import '../../../../shared/widgets/metric_card.dart';
import '../../../../shared/widgets/permission_gate.dart';
import '../../../authentication/application/auth_providers.dart';
import '../../../authentication/application/auth_state.dart';
import '../../../employee/application/employee_providers.dart';
import '../../../freelancers/application/freelancers_providers.dart';
import '../../../freelancers/domain/entities/freelancer.dart';
import '../../../freelancers/domain/exceptions/freelancer_exception.dart';
import '../../application/payroll_providers.dart';
import '../../domain/entities/payroll_run_status.dart';
import '../../domain/entities/payroll_run_summary.dart';
import '../../domain/exceptions/payroll_exception.dart';
import '../widgets/payroll_run_status_badge.dart';
import 'payroll_run_detail_page.dart';

/// Payroll Runs + a Freelancers roster — shared by Super Admin and
/// HR/Manager (gated by nav visibility in main.dart, and by
/// `payroll.manage` on the backend routes for both tabs).
class PayrollPage extends ConsumerWidget {
  const PayrollPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    if (authState is! AuthAuthenticated ||
        !authState.user.hasPermission('payroll.manage')) {
      return const AccessDeniedView();
    }

    return DefaultTabController(
      length: 2,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            // Scrollable, with the tab content given a fixed height instead
            // of Expanded (which needs a bounded-height ancestor, not a
            // scroll view) — same shape as ClientsProjectsPage, needed once
            // _PayrollStats/_DepartmentPayrollTotals above the tabs made
            // this page's content taller than a typical viewport.
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _PayrollStats(),
                  const SizedBox(height: 10),
                  const _DepartmentPayrollTotals(),
                  const SizedBox(height: 20),
                  const TabBar(
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    labelColor: AppColors.primary,
                    unselectedLabelColor: AppColors.textSecondary,
                    indicatorColor: AppColors.primary,
                    tabs: [Tab(text: 'Runs'), Tab(text: 'Freelancers')],
                  ),
                  const SizedBox(height: 16),
                  const SizedBox(
                    height: 640,
                    child: TabBarView(
                      children: [_RunsTab(), _FreelancersTab()],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Monthly and daily payroll of active employees, derived from each one's
/// current salary — moved here from the Dashboard so headline payroll
/// figures live on the page about payroll, not the company-wide overview.
class _PayrollStats extends ConsumerWidget {
  const _PayrollStats();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payrollAsync = ref.watch(payrollSummaryProvider);

    return payrollAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: LinearProgressIndicator(),
      ),
      error: (_, _) => Text(
        'Could not load payroll figures.',
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      ),
      data: (payroll) {
        final averageSalary = payroll.activeEmployeeCount == 0
            ? 0.0
            : payroll.totalMonthlyPayroll / payroll.activeEmployeeCount;

        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            MetricCard(
              label: 'Monthly Payroll',
              value: 'PKR ${formatWholeAmount(payroll.totalMonthlyPayroll)}',
              secondaryValue: formatUsdApprox(payroll.totalMonthlyPayroll),
              color: AppColors.primary,
              icon: Icons.account_balance_wallet_outlined,
            ),
            MetricCard(
              label: 'Daily Payroll',
              value: 'PKR ${formatWholeAmount(payroll.dailyPayroll)}',
              secondaryValue: formatUsdApprox(payroll.dailyPayroll),
              color: AppColors.accentTeal,
              icon: Icons.today_outlined,
            ),
            MetricCard(
              label: 'Average Salary',
              value: 'PKR ${formatWholeAmount(averageSalary)}',
              secondaryValue: formatUsdApprox(averageSalary),
              color: AppColors.secondary,
              icon: Icons.person_outline,
            ),
            const _LatestPayrollRunCard(),
            const _TotalFreelancersCard(),
          ],
        );
      },
    );
  }
}

/// The most recently generated payroll run's status and total, sorted
/// client-side since there's no dedicated "latest run" endpoint — moved
/// here from the Dashboard alongside [_PayrollStats].
class _LatestPayrollRunCard extends ConsumerWidget {
  const _LatestPayrollRunCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final runsAsync = ref.watch(payrollRunsListProvider);
    final latest = runsAsync.whenOrNull(
      data: (runs) => runs.isEmpty ? null : _latestOf(runs),
    );

    return MetricCard(
      label: 'Latest Payroll Run',
      value: runsAsync.when(
        data: (runs) =>
            runs.isEmpty ? 'None yet' : _formatRunStatus(latest!.status),
        loading: () => '…',
        error: (_, _) => '—',
      ),
      secondaryValue: latest == null
          ? null
          : 'PKR ${formatWholeAmount(latest.totalNetPay)}',
      color: AppColors.primary,
      icon: Icons.receipt_outlined,
    );
  }

  // Not `runs.reduce(...)`: at runtime `runs` is a `List<PayrollRunSummaryModel>`
  // (the repository's concrete type), and `reduce`'s combine callback is
  // checked against that runtime element type — a callback typed with the
  // base `PayrollRunSummary` throws a TypeError there. A plain loop avoids
  // binding the callback to either type.
  PayrollRunSummary _latestOf(List<PayrollRunSummary> runs) {
    var latest = runs.first;
    for (final run in runs.skip(1)) {
      if ((run.year * 12 + run.month) >= (latest.year * 12 + latest.month)) {
        latest = run;
      }
    }
    return latest;
  }

  String _formatRunStatus(String status) {
    switch (status) {
      case PayrollRunStatus.draft:
        return 'Draft';
      case PayrollRunStatus.finalized:
        return 'Finalized';
      case PayrollRunStatus.paid:
        return 'Paid';
      default:
        return status;
    }
  }
}

/// Active freelancer count — moved here from the Dashboard alongside
/// [_PayrollStats], since freelancers are managed from this page's own
/// Freelancers tab.
class _TotalFreelancersCard extends ConsumerWidget {
  const _TotalFreelancersCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final freelancersAsync = ref.watch(freelancersListProvider);

    return MetricCard(
      label: 'Total Freelancers',
      value: freelancersAsync.when(
        data: (freelancers) =>
            '${freelancers.where((f) => f.isActive).length}',
        loading: () => '…',
        error: (_, _) => '—',
      ),
      color: AppColors.accentTeal,
      icon: Icons.badge_outlined,
    );
  }
}

/// Each department's share of the current monthly payroll, sorted highest
/// total first (as returned by the backend) — moved here from the Dashboard
/// alongside [_PayrollStats]. Renders via the shared
/// [DepartmentBreakdownSection] so this and the single-run breakdown on
/// `PayrollRunDetailPage` stay visually identical.
class _DepartmentPayrollTotals extends ConsumerWidget {
  const _DepartmentPayrollTotals();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payrollAsync = ref.watch(payrollSummaryProvider);

    return payrollAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (payroll) => DepartmentBreakdownSection(
        title: 'Payroll by Department',
        totalAmount: payroll.totalMonthlyPayroll,
        countLabel: (count) => count == 1 ? '1 employee' : '$count employees',
        rows: [
          for (final total in payroll.departmentTotals)
            DepartmentBreakdownRow(
              name: total.departmentName,
              amount: total.totalMonthlyPayroll,
              count: total.employeeCount,
            ),
        ],
      ),
    );
  }
}

class _RunsTab extends ConsumerWidget {
  const _RunsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final runsAsync = ref.watch(payrollRunsListProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: () async {
              await showDialog<void>(
                context: context,
                builder: (_) => const _GeneratePayrollDialog(),
              );
              ref.invalidate(payrollRunsListProvider);
            },
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Generate Payroll'),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: runsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => Text(
              'Could not load payroll runs. Please try again.',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            data: (runs) => runs.isEmpty
                ? Center(
                    child: Text(
                      'No payroll runs generated yet.',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  )
                : ListView.separated(
                    itemCount: runs.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) => _RunRow(run: runs[index]),
                  ),
          ),
        ),
      ],
    );
  }
}

class _FreelancersTab extends ConsumerWidget {
  const _FreelancersTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final freelancersAsync = ref.watch(freelancersListProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: () async {
              await showDialog<void>(
                context: context,
                builder: (_) => const _FreelancerEditorDialog(),
              );
              ref.invalidate(freelancersListProvider);
            },
            icon: const Icon(Icons.person_add_alt_outlined, size: 16),
            label: const Text('Add Freelancer'),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: freelancersAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => Text(
              'Could not load freelancers. Please try again.',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            data: (freelancers) => freelancers.isEmpty
                ? Center(
                    child: Text(
                      'No freelancers added yet.',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  )
                : ListView.separated(
                    itemCount: freelancers.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) =>
                        _FreelancerRow(freelancer: freelancers[index]),
                  ),
          ),
        ),
      ],
    );
  }
}

class _FreelancerRow extends ConsumerWidget {
  const _FreelancerRow({required this.freelancer});

  final Freelancer freelancer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: ListTile(
        onTap: () async {
          await showDialog<void>(
            context: context,
            builder: (_) => _FreelancerEditorDialog(freelancer: freelancer),
          );
          ref.invalidate(freelancersListProvider);
        },
        title: Text(freelancer.fullName),
        subtitle: freelancer.role == null ? null : Text(freelancer.role!),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: (freelancer.isActive ? AppColors.success : AppColors.error)
                .withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            freelancer.isActive ? 'Active' : 'Inactive',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: freelancer.isActive
                  ? AppColors.success
                  : AppColors.error,
            ),
          ),
        ),
      ),
    );
  }
}

class _FreelancerEditorDialog extends ConsumerStatefulWidget {
  const _FreelancerEditorDialog({this.freelancer});

  /// `null` creates a new freelancer; non-null edits an existing one.
  final Freelancer? freelancer;

  @override
  ConsumerState<_FreelancerEditorDialog> createState() =>
      _FreelancerEditorDialogState();
}

class _FreelancerEditorDialogState
    extends ConsumerState<_FreelancerEditorDialog> {
  late final TextEditingController _fullNameController;
  late final TextEditingController _roleController;
  late final TextEditingController _notesController;
  late bool _isActive;
  bool _saving = false;
  String? _errorMessage;

  bool get _isEditing => widget.freelancer != null;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController(
      text: widget.freelancer?.fullName ?? '',
    );
    _roleController = TextEditingController(
      text: widget.freelancer?.role ?? '',
    );
    _notesController = TextEditingController(
      text: widget.freelancer?.notes ?? '',
    );
    _isActive = widget.freelancer?.isActive ?? true;
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _roleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_fullNameController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Full name is required.');
      return;
    }
    setState(() {
      _saving = true;
      _errorMessage = null;
    });
    try {
      final repository = ref.read(freelancersRepositoryProvider);
      final role = _roleController.text.trim().isEmpty
          ? null
          : _roleController.text.trim();
      final notes = _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim();
      if (_isEditing) {
        await repository.updateFreelancer(
          widget.freelancer!.id,
          fullName: _fullNameController.text.trim(),
          role: role,
          notes: notes,
          isActive: _isActive,
        );
      } else {
        await repository.createFreelancer(
          fullName: _fullNameController.text.trim(),
          role: role,
          notes: notes,
        );
      }
      if (mounted) Navigator.of(context).pop();
    } on FreelancerException catch (error) {
      setState(() => _errorMessage = error.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEditing ? 'Edit Freelancer' : 'Add Freelancer'),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_errorMessage != null) ...[
              Text(
                _errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: _fullNameController,
              enabled: !_saving,
              decoration: const InputDecoration(labelText: 'Full name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _roleController,
              enabled: !_saving,
              decoration: const InputDecoration(
                labelText: 'Role (optional)',
                hintText: 'e.g. Content Writer',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              enabled: !_saving,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Notes (optional)'),
            ),
            if (_isEditing) ...[
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Active'),
                value: _isActive,
                onChanged: _saving
                    ? null
                    : (value) => setState(() => _isActive = value),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _submit,
          child: _saving
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(_isEditing ? 'Save' : 'Add'),
        ),
      ],
    );
  }
}

class _RunRow extends StatelessWidget {
  const _RunRow({required this.run});

  final PayrollRunSummary run;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => PayrollRunDetailPage(runId: run.id)),
        ),
        title: Text(formatPayrollRunPeriod(run.month, run.year)),
        subtitle: Text('${run.employeeCount} employee(s)'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'PKR ${formatAmount(run.totalNetPay)}',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 12),
            PayrollRunStatusBadge(status: run.status),
          ],
        ),
      ),
    );
  }
}

class _GeneratePayrollDialog extends ConsumerStatefulWidget {
  const _GeneratePayrollDialog();

  @override
  ConsumerState<_GeneratePayrollDialog> createState() =>
      _GeneratePayrollDialogState();
}

class _GeneratePayrollDialogState extends ConsumerState<_GeneratePayrollDialog> {
  late int _month;
  late int _year;
  bool _saving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = now.month;
    _year = now.year;
  }

  Future<void> _submit() async {
    setState(() {
      _saving = true;
      _errorMessage = null;
    });
    try {
      await ref
          .read(payrollRepositoryProvider)
          .generateRun(month: _month, year: _year);
      if (mounted) Navigator.of(context).pop();
    } on PayrollException catch (error) {
      setState(() => _errorMessage = error.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return AlertDialog(
      title: const Text('Generate Payroll'),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_errorMessage != null) ...[
              Text(
                _errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              const SizedBox(height: 12),
            ],
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: _month,
                    decoration: const InputDecoration(labelText: 'Month'),
                    items: [
                      for (var m = 1; m <= 12; m++)
                        DropdownMenuItem(
                          value: m,
                          child: Text(formatPayrollRunPeriod(m, _year).split(' ').first),
                        ),
                    ],
                    onChanged: _saving
                        ? null
                        : (value) {
                            if (value != null) setState(() => _month = value);
                          },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: _year,
                    decoration: const InputDecoration(labelText: 'Year'),
                    items: [
                      for (var y = now.year - 2; y <= now.year + 1; y++)
                        DropdownMenuItem(value: y, child: Text('$y')),
                    ],
                    onChanged: _saving
                        ? null
                        : (value) {
                            if (value != null) setState(() => _year = value);
                          },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _submit,
          child: _saving
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Generate'),
        ),
      ],
    );
  }
}
