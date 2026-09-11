import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/metric_card.dart';
import '../../../../shared/widgets/monthly_bar_chart.dart';
import '../../../../shared/widgets/top_breakdown_panel.dart';
import '../../../authentication/application/auth_providers.dart';
import '../../../authentication/application/auth_state.dart';
import '../../../notices/application/notice_providers.dart';
import '../../../notices/domain/exceptions/notice_exception.dart';
import '../../../performance_reviews/application/performance_review_providers.dart';
import '../../application/employee_providers.dart';
import '../../domain/entities/employee.dart';
import '../widgets/company_notices_section.dart';

class AdminDashboardPage extends ConsumerWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employeesAsync = ref.watch(employeeListProvider);
    final authState = ref.watch(authControllerProvider);
    final canViewPerformance =
        authState is AuthAuthenticated &&
        authState.user.hasPermission('performance.manage');

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
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
              showPendingReviews: canViewPerformance,
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
    required this.showPendingReviews,
  });

  final List<Employee> employees;
  final bool showPendingReviews;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final total = employees.length;
    final avgProfileCompletion = total == 0
        ? 0
        : (employees.map((e) => e.profileCompletionPercentage).reduce(
                (a, b) => a + b,
              ) /
              total)
              .round();

    final byStatus = <String, int>{};
    for (final employee in employees) {
      byStatus.update(
        employee.employmentStatus,
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
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              MetricCard(
                label: 'Avg. Profile Completion',
                value: '$avgProfileCompletion%',
                color: AppColors.accentTeal,
                icon: Icons.donut_large_outlined,
              ),
              MetricCard(
                label: 'Notice Period',
                value: '${byStatus['notice_period'] ?? 0}',
                color: AppColors.secondary,
                icon: Icons.event_busy_outlined,
                onTap: () {
                  ref.read(employeeStatusFilterProvider.notifier).state =
                      'notice_period';
                  ref.read(pendingSectionNavigationProvider.notifier).state =
                      'Employees';
                },
              ),
              if (showPendingReviews) const _PendingReviewsCard(),
            ],
          ),
          const SizedBox(height: 18),
          MonthlyBarChart(
            title: 'New Hires (Last 12 Months)',
            counts: _newHiresByMonth(employees),
            color: AppColors.primary,
            unitLabel: 'hire',
          ),
          const SizedBox(height: 14),
          TopBreakdownRow(
            panels: [
              TopBreakdownPanel(
                title: 'Employees by Department',
                icon: Icons.apartment_outlined,
                color: AppColors.accentTeal,
                counts: computeTopCounts(
                  employees
                      .where((e) => e.employmentStatus == 'active')
                      .toList(),
                  (e) => e.department?.name,
                  limit: 10,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const CompanyNoticesSection(),
        ],
      ),
    );
  }

  /// Counts, keyed by `'YYYY-MM'`, of everyone whose `joiningDate` falls in
  /// the last 12 months — a historical hiring trend, so it counts everyone
  /// hired in that window regardless of whether they're still active today.
  Map<String, int> _newHiresByMonth(List<Employee> employees) {
    final cutoff = DateTime.now().subtract(const Duration(days: 365));
    final counts = <String, int>{};
    for (final employee in employees) {
      final date = DateTime.tryParse(employee.joiningDate);
      if (date == null || date.isBefore(cutoff)) continue;
      final key =
          '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}';
      counts[key] = (counts[key] ?? 0) + 1;
    }
    return counts;
  }
}

/// Formats a stat tile's trend for [MetricCard.secondaryValue] over
/// [days] — e.g. "+1 in last 30 days", "-1 in last 30 days", or "No change
/// in last 30 days" once the delta loads; null while it's still loading or
/// failed, so the tile just shows its main value with no secondary line
/// rather than a flickering or broken one.
String? _formatDelta(AsyncValue<int> deltaAsync, int days) {
  final delta = deltaAsync.valueOrNull;
  if (delta == null) return null;
  if (delta == 0) return 'No change in last $days days';
  return '${delta > 0 ? '+' : ''}$delta in last $days days';
}

/// Company-wide count of reviews still awaiting a manager's/HR's
/// completion — a separate async fetch from the (already-loaded) employee
/// list, so it renders its own loading/error value rather than blocking the
/// rest of the Overview stats.
class _PendingReviewsCard extends ConsumerWidget {
  const _PendingReviewsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewsAsync = ref.watch(allPendingPerformanceReviewsProvider);
    final deltaAsync = ref.watch(pendingReviewsDeltaProvider);

    return MetricCard(
      label: 'Pending Performance Reviews',
      value: reviewsAsync.when(
        data: (reviews) => '${reviews.length}',
        loading: () => '…',
        error: (_, _) => '—',
      ),
      secondaryValue: _formatDelta(deltaAsync, 7),
      color: AppColors.secondary,
      icon: Icons.rate_review_outlined,
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
