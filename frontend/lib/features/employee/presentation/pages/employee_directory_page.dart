import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../authentication/application/auth_providers.dart';
import '../../../authentication/application/auth_state.dart';
import '../../../../shared/utils/date_format.dart';
import '../../../performance_reviews/application/performance_review_providers.dart';
import '../../../performance_reviews/domain/entities/performance_review_summary.dart';
import '../../application/employee_providers.dart';
import '../../domain/entities/employee.dart';
import '../widgets/employee_avatar.dart';
import '../widgets/employee_hierarchy_view.dart';
import '../widgets/employee_status_badges.dart';
import 'employee_profile_page.dart';
import 'invite_employee_page.dart';

enum _DirectoryViewMode { list, hierarchy }

class EmployeeDirectoryPage extends ConsumerStatefulWidget {
  const EmployeeDirectoryPage({super.key});

  @override
  ConsumerState<EmployeeDirectoryPage> createState() =>
      _EmployeeDirectoryPageState();
}

class _EmployeeDirectoryPageState
    extends ConsumerState<EmployeeDirectoryPage> {
  _DirectoryViewMode _viewMode = _DirectoryViewMode.list;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final authUser = authState is AuthAuthenticated ? authState.user : null;
    final canRead = authUser?.hasPermission('employees.read') ?? false;
    final canManage = authUser?.hasPermission('employees.manage') ?? false;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1040),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (canRead)
                    _ViewModeToggle(
                      value: _viewMode,
                      onChanged: (mode) => setState(() => _viewMode = mode),
                    ),
                  if (canRead && _viewMode == _DirectoryViewMode.list)
                    SizedBox(
                      width: 280,
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) =>
                            setState(() => _searchQuery = value.trim()),
                        decoration: InputDecoration(
                          hintText: 'Search employees',
                          prefixIcon: const Icon(Icons.search, size: 20),
                          suffixIcon: _searchQuery.isEmpty
                              ? null
                              : IconButton(
                                  icon: const Icon(Icons.close, size: 18),
                                  onPressed: () => setState(() {
                                    _searchController.clear();
                                    _searchQuery = '';
                                  }),
                                ),
                          isDense: true,
                        ),
                      ),
                    ),
                  if (canManage)
                    ElevatedButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const InviteEmployeePage(),
                        ),
                      ),
                      icon: const Icon(Icons.person_add_outlined, size: 18),
                      label: const Text('Invite Employee'),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: canRead
                    ? _DirectoryBody(
                        viewMode: _viewMode,
                        searchQuery: _searchQuery,
                      )
                    : const _NoDirectoryAccess(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DirectoryBody extends ConsumerWidget {
  const _DirectoryBody({required this.viewMode, required this.searchQuery});

  final _DirectoryViewMode viewMode;
  final String searchQuery;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employeesAsync = ref.watch(employeeListProvider);
    final authState = ref.watch(authControllerProvider);
    final authUser = authState is AuthAuthenticated ? authState.user : null;
    final canViewPerformance =
        authUser?.hasPermission('performance.manage') ?? false;
    // Loading/error states here just mean the review chip stays absent
    // until it resolves — never block the (already-loaded) employee list on
    // this secondary fetch.
    final reviewSummaries = canViewPerformance
        ? ref.watch(latestPerformanceReviewsByEmployeeProvider).valueOrNull ??
              const <String, PerformanceReviewSummary>{}
        : const <String, PerformanceReviewSummary>{};

    return employeesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Text(
          'Could not load the directory. Please try again.',
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      ),
      data: (employees) {
        if (employees.isEmpty) {
          return const Center(child: Text('No employees yet.'));
        }

        if (viewMode == _DirectoryViewMode.hierarchy) {
          final shown = employees
              .where((employee) => employee.isCurrentEmployee)
              .length;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DirectorySummary(employees: employees, shown: shown),
              const SizedBox(height: 14),
              Expanded(child: EmployeeHierarchyView(employees: employees)),
            ],
          );
        }

        final filtered = _filterEmployees(employees, searchQuery);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DirectorySummary(employees: employees, shown: filtered.length),
            const SizedBox(height: 14),
            Expanded(
              child: filtered.isEmpty
                  ? const Center(
                      child: Text('No employees match your search.'),
                    )
                  : _EmployeeList(
                      employees: filtered,
                      canViewPerformance: canViewPerformance,
                      reviewSummaries: reviewSummaries,
                    ),
            ),
          ],
        );
      },
    );
  }

  List<Employee> _filterEmployees(List<Employee> employees, String query) {
    if (query.isEmpty) return employees;
    final needle = query.toLowerCase();
    return employees
        .where(
          (employee) =>
              employee.fullName.toLowerCase().contains(needle) ||
              employee.email.toLowerCase().contains(needle) ||
              employee.employeeCode.toLowerCase().contains(needle) ||
              (employee.designation ?? '').toLowerCase().contains(needle),
        )
        .toList();
  }
}

/// A soft, pill-shaped List/Hierarchy switcher matching the app's rounded,
/// pastel-tinted visual language — in place of the stock Material
/// [SegmentedButton] chrome.
class _ViewModeToggle extends StatelessWidget {
  const _ViewModeToggle({required this.value, required this.onChanged});

  final _DirectoryViewMode value;
  final ValueChanged<_DirectoryViewMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.fieldFill,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ViewModeSegment(
            icon: Icons.view_list_outlined,
            label: 'List',
            selected: value == _DirectoryViewMode.list,
            onTap: () => onChanged(_DirectoryViewMode.list),
          ),
          _ViewModeSegment(
            icon: Icons.account_tree_outlined,
            label: 'Hierarchy',
            selected: value == _DirectoryViewMode.hierarchy,
            onTap: () => onChanged(_DirectoryViewMode.hierarchy),
          ),
        ],
      ),
    );
  }
}

class _ViewModeSegment extends StatelessWidget {
  const _ViewModeSegment({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.textSecondary;
    return Material(
      color: selected ? AppColors.primarySoft : Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: color,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A "N employees" (or "Showing N of M") headline, followed by the same
/// employment-status and work-mode breakdown the dashboard shows — as plain,
/// well-spaced text rather than another row of boxes, since this page
/// already has its own card grid below.
class _DirectorySummary extends StatelessWidget {
  const _DirectorySummary({required this.employees, required this.shown});

  final List<Employee> employees;
  final int shown;

  @override
  Widget build(BuildContext context) {
    final total = employees.length;
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

    final headline = shown == total
        ? '$total ${total == 1 ? 'employee' : 'employees'}'
        : 'Showing $shown of $total employees';
    final statLabelStyle = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          headline,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 18,
          runSpacing: 6,
          children: [
            Text('Active: ${byStatus['active'] ?? 0}', style: statLabelStyle),
            Text(
              'On Leave: ${byStatus['on_leave'] ?? 0}',
              style: statLabelStyle,
            ),
            Text(
              'Notice Period: ${byStatus['notice_period'] ?? 0}',
              style: statLabelStyle,
            ),
            Text(
              'Resigned: ${byStatus['resigned'] ?? 0}',
              style: statLabelStyle,
            ),
            Text(
              'Terminated: ${byStatus['terminated'] ?? 0}',
              style: statLabelStyle,
            ),
          ],
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 18,
          runSpacing: 6,
          children: [
            Text(
              'On-site: ${byWorkMode['on_site'] ?? 0}',
              style: statLabelStyle,
            ),
            Text(
              'Remote: ${byWorkMode['remote'] ?? 0}',
              style: statLabelStyle,
            ),
            Text(
              'Hybrid: ${byWorkMode['hybrid'] ?? 0}',
              style: statLabelStyle,
            ),
          ],
        ),
      ],
    );
  }
}

class _EmployeeList extends StatelessWidget {
  const _EmployeeList({
    required this.employees,
    required this.canViewPerformance,
    required this.reviewSummaries,
  });

  final List<Employee> employees;
  final bool canViewPerformance;
  final Map<String, PerformanceReviewSummary> reviewSummaries;

  @override
  Widget build(BuildContext context) {
    const spacing = 12.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Three per row once there's comfortable room for it, stepping down
        // on narrower screens; one per row (the old behavior) on mobile.
        final columns = constraints.maxWidth >= 1000
            ? 3
            : constraints.maxWidth >= 700
            ? 2
            : 1;
        final cardWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;

        final rows = <List<Employee>>[
          for (var i = 0; i < employees.length; i += columns)
            employees.sublist(
              i,
              i + columns > employees.length ? employees.length : i + columns,
            ),
        ];

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final row in rows) ...[
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var i = 0; i < row.length; i++) ...[
                        SizedBox(
                          width: cardWidth,
                          child: _EmployeeCard(
                            employee: row[i],
                            width: cardWidth,
                            canViewPerformance: canViewPerformance,
                            reviewSummary: reviewSummaries[row[i].id],
                          ),
                        ),
                        if (i != row.length - 1)
                          const SizedBox(width: spacing),
                      ],
                    ],
                  ),
                ),
                if (row != rows.last) const SizedBox(height: spacing),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _EmployeeCard extends StatelessWidget {
  const _EmployeeCard({
    required this.employee,
    required this.width,
    required this.canViewPerformance,
    required this.reviewSummary,
  });

  final Employee employee;
  final double width;
  final bool canViewPerformance;
  final PerformanceReviewSummary? reviewSummary;

  @override
  Widget build(BuildContext context) {
    // The Wrap's items need an explicit max width to know when to
    // ellipsize; derive it from the card width instead of an inner
    // LayoutBuilder, which doesn't play well with the IntrinsicHeight
    // ancestor the grid uses to make every card in a row the same height.
    final contentWidth = width - 40;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => EmployeeProfilePage(employeeId: employee.id),
          ),
        ),
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
                    radius: 24.2,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                employee.fullName,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.badge_outlined,
                              size: 14,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              employee.employeeCode,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                        if ((employee.designation ?? '').isNotEmpty)
                          Text(
                            employee.designation!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                        Text(
                          'Department: ${employee.department?.name ?? 'None'}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                        Text(
                          'Reports to: ${employee.reportingManager?.name ?? '—'}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  EmploymentStatusBadge(
                    status: employee.employmentStatus,
                    dense: true,
                  ),
                  WorkModeBadge(workMode: employee.workMode, dense: true),
                  InfoChip(
                    icon: Icons.email_outlined,
                    label: employee.email,
                    maxWidth: contentWidth,
                  ),
                  InfoChip(
                    icon: Icons.phone_outlined,
                    label: employee.phoneNumber ?? '—',
                    maxWidth: contentWidth,
                  ),
                  InfoChip(
                    icon: Icons.event_outlined,
                    label:
                        'Joined ${formatDisplayDate(employee.joiningDate)}',
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
                        : formatDisplayDate(employee.dateOfBirth!),
                    maxWidth: contentWidth,
                  ),
                  if (canViewPerformance)
                    InfoChip(
                      icon: Icons.fact_check_outlined,
                      label: _reviewLabel(reviewSummary),
                      maxWidth: contentWidth,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// "Last Review: Pending" while awaiting completion/finalization, the
  /// finalized (or, failing that, completed) date once done, or "No review
  /// yet" for someone who hasn't hit their first work anniversary.
  String _reviewLabel(PerformanceReviewSummary? summary) {
    if (summary == null) return 'No review yet';
    if (summary.status == 'pending') return 'Last Review: Pending';
    final doneAt = summary.finalizedAt ?? summary.completedAt;
    if (doneAt == null) return 'Last Review: Pending';
    return 'Last Review: ${formatDisplayDateOnly(doneAt)}';
  }
}

class _NoDirectoryAccess extends StatelessWidget {
  const _NoDirectoryAccess();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lock_outline, size: 40),
          const SizedBox(height: 12),
          const Text("You don't have access to the full directory."),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const EmployeeProfilePage(employeeId: null),
              ),
            ),
            child: const Text('View my profile'),
          ),
        ],
      ),
    );
  }
}
