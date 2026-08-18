import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/utils/currency_format.dart';
import '../../../../shared/widgets/metric_card.dart';
import '../../../authentication/application/auth_providers.dart';
import '../../../authentication/application/auth_state.dart';
import '../../../notices/application/notice_providers.dart';
import '../../../notices/domain/exceptions/notice_exception.dart';
import '../../application/employee_providers.dart';
import '../../domain/entities/employee.dart';
import '../widgets/company_audit_log_section.dart';
import '../widgets/company_notices_section.dart';

class AdminDashboardPage extends ConsumerWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employeesAsync = ref.watch(employeeListProvider);
    final authState = ref.watch(authControllerProvider);
    final canViewAllAudit =
        authState is AuthAuthenticated &&
        authState.user.hasPermission('audit.viewAll');
    final canViewPayroll =
        authState is AuthAuthenticated &&
        authState.user.hasPermission('employees.manage');

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
              showPayroll: canViewPayroll,
            ),
          ),
        ),
      ),
    );
  }
}

class _DashboardStats extends ConsumerWidget {
  const _DashboardStats({
    required this.employees,
    required this.showCompanyAuditLog,
    required this.showPayroll,
  });

  final List<Employee> employees;
  final bool showCompanyAuditLog;
  final bool showPayroll;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final total = employees.length;
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
      // Work mode only makes sense for people currently working, so resigned/
      // terminated/on-leave/notice-period employees aren't counted here.
      if (employee.employmentStatus == 'active') {
        byWorkMode.update(
          employee.workMode,
          (count) => count + 1,
          ifAbsent: () => 1,
        );
      }
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
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              MetricCard(
                label: 'Total Employees',
                value: '$total',
                color: AppColors.primary,
                icon: Icons.people_alt_outlined,
              ),
              MetricCard(
                label: 'Active',
                value: '${byStatus['active'] ?? 0}',
                color: AppColors.success,
                icon: Icons.check_circle_outline,
              ),
              MetricCard(
                label: 'New Hires (This Month)',
                value: '$newHiresThisMonth',
                color: AppColors.success,
                icon: Icons.person_add_alt_outlined,
              ),
              MetricCard(
                label: 'Avg. Profile Completion',
                value: '$avgProfileCompletion%',
                color: AppColors.accentTeal,
                icon: Icons.donut_large_outlined,
              ),
              MetricCard(
                label: 'On Leave',
                value: '${byStatus['on_leave'] ?? 0}',
                color: AppColors.warning,
                icon: Icons.beach_access_outlined,
              ),
              MetricCard(
                label: 'Notice Period',
                value: '${byStatus['notice_period'] ?? 0}',
                color: AppColors.secondary,
                icon: Icons.event_busy_outlined,
              ),
              MetricCard(
                label: 'Resigned',
                value: '${byStatus['resigned'] ?? 0}',
                color: AppColors.error,
                icon: Icons.logout_outlined,
              ),
              MetricCard(
                label: 'Terminated',
                value: '${byStatus['terminated'] ?? 0}',
                color: AppColors.error,
                icon: Icons.cancel_outlined,
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
                icon: Icons.apartment_outlined,
              ),
              MetricCard(
                label: 'Remote',
                value: '${byWorkMode['remote'] ?? 0}',
                color: AppColors.textSecondary,
                icon: Icons.home_outlined,
              ),
              MetricCard(
                label: 'Hybrid',
                value: '${byWorkMode['hybrid'] ?? 0}',
                color: AppColors.textSecondary,
                icon: Icons.sync_alt_outlined,
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (showPayroll) ...[
            const _SectionHeader('Payroll'),
            const SizedBox(height: 10),
            const _PayrollStats(),
            const SizedBox(height: 18),
          ],
          const CompanyNoticesSection(),
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

/// Monthly and daily payroll of active employees, derived from each one's
/// current salary. A separate small async section (rather than folding into
/// the Overview stats above) since it depends on a different, more tightly
/// permissioned endpoint than the plain employee list.
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
              color: AppColors.primary,
              icon: Icons.account_balance_wallet_outlined,
            ),
            MetricCard(
              label: 'Daily Payroll',
              value: 'PKR ${formatWholeAmount(payroll.dailyPayroll)}',
              color: AppColors.accentTeal,
              icon: Icons.today_outlined,
            ),
            MetricCard(
              label: 'Average Salary',
              value: 'PKR ${formatWholeAmount(averageSalary)}',
              color: AppColors.secondary,
              icon: Icons.person_outline,
            ),
          ],
        );
      },
    );
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
