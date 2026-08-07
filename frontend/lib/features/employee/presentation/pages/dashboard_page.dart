import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/metric_card.dart';
import '../../../authentication/application/auth_providers.dart';
import '../../../authentication/application/auth_state.dart';
import '../../application/employee_providers.dart';
import '../../domain/entities/employee.dart';
import '../widgets/company_audit_log_section.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employeesAsync = ref.watch(employeeListProvider);
    final authState = ref.watch(authControllerProvider);
    final canViewAllAudit =
        authState is AuthAuthenticated &&
        authState.user.hasPermission('audit.viewAll');

    return Padding(
      padding: const EdgeInsets.all(32),
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
          const _SectionHeader('Overview'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
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
          const SizedBox(height: 28),
          const _SectionHeader('Employment Status'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
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
          const SizedBox(height: 28),
          const _SectionHeader('Work Mode'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
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
          if (showCompanyAuditLog) ...[
            const SizedBox(height: 28),
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
