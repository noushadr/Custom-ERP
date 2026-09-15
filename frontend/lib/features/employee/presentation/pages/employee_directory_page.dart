import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/metric_card.dart';
import '../../../../shared/widgets/pie_chart_panel.dart';
import '../../../../shared/widgets/top_breakdown_panel.dart';
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
import 'add_employee_page.dart';
import 'employee_profile_page.dart';

enum _DirectoryViewMode { list, hierarchy }

/// A sentinel status-filter value, distinct from every real
/// `Employee.employmentStatus` value — "on probation" isn't an employment
/// status of its own (it stays `active`/whatever it already was, so
/// probationary employees keep showing up in payroll, leave, etc.), just a
/// computed read of [Employee.probationEndDate]. Reusing the exact string
/// [Employee.probationStatus] already returns for "currently on probation"
/// keeps this filter and that field in lockstep by construction.
const _probationFilterValue = 'on_probation';

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
  String? _statusFilter;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // This page is built once, up front, and kept mounted in the app's
    // IndexedStack-based nav (see main.dart's `_HomeShellState`) — it is
    // never freshly constructed when the user actually navigates here, so
    // `initState` cannot reliably pick up a pre-filter requested well after
    // the app first mounted (e.g. the Dashboard's Notice Period tile).
    // `ref.listen` reacts whenever the provider changes, regardless of when.
    ref.listen<String?>(employeeStatusFilterProvider, (previous, next) {
      if (next == null) return;
      setState(() => _statusFilter = next);
      ref.read(employeeStatusFilterProvider.notifier).state = null;
    });

    final authState = ref.watch(authControllerProvider);
    final authUser = authState is AuthAuthenticated ? authState.user : null;
    final canRead = authUser?.hasPermission('employees.read') ?? false;
    final canManage = authUser?.hasPermission('employees.manage') ?? false;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1040),
          // The whole page scrolls as one unit (matching every other page
          // in this app, e.g. the Dashboard) rather than splitting into a
          // fixed header + independently-scrolling list — the stats row
          // grew tall enough (Avg. Profile Completion/Notice Period/On
          // Leave/On Probation/Pending Performance Reviews plus the
          // department pie chart) that a fixed, non-scrolling header no
          // longer reliably fits above the fold on real screen sizes.
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (canRead) ...[
                  const _EmployeeStatsSection(),
                  const SizedBox(height: 16),
                ],
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
                    if (canRead && _viewMode == _DirectoryViewMode.list)
                      _StatusFilterRow(
                        value: _statusFilter,
                        onChanged: (value) =>
                            setState(() => _statusFilter = value),
                      ),
                    if (canManage)
                      ElevatedButton.icon(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const AddEmployeePage(),
                          ),
                        ),
                        icon: const Icon(Icons.person_add_outlined, size: 18),
                        label: const Text('Add Employee'),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                canRead
                    ? _DirectoryBody(
                        viewMode: _viewMode,
                        searchQuery: _searchQuery,
                        statusFilter: _statusFilter,
                      )
                    : const _NoDirectoryAccess(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DirectoryBody extends ConsumerWidget {
  const _DirectoryBody({
    required this.viewMode,
    required this.searchQuery,
    required this.statusFilter,
  });

  final _DirectoryViewMode viewMode;
  final String searchQuery;
  final String? statusFilter;

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
          return EmployeeHierarchyView(employees: employees);
        }

        final filtered = _filterEmployees(employees, searchQuery, statusFilter);
        return filtered.isEmpty
            ? const Center(child: Text('No employees match your search.'))
            : _EmployeeList(
                employees: filtered,
                canViewPerformance: canViewPerformance,
                reviewSummaries: reviewSummaries,
              );
      },
    );
  }

  List<Employee> _filterEmployees(
    List<Employee> employees,
    String query,
    String? statusFilter,
  ) {
    var filtered = employees;
    if (statusFilter != null) {
      filtered = filtered
          .where(
            (employee) => statusFilter == _probationFilterValue
                ? employee.probationStatus == 'on_probation'
                : employee.employmentStatus == statusFilter,
          )
          .toList();
    }
    if (query.isEmpty) return filtered;
    final needle = query.toLowerCase();
    return filtered
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

/// A dropdown to narrow the list to one employment status — e.g. landing
/// here from the Dashboard's Notice Period tile pre-selects "Notice
/// Period". Only shown in List view; a search-query narrows further on top
/// of whatever status is selected here. "On Probation" rides along in this
/// same list even though it isn't a real `employmentStatus` value — see
/// [_probationFilterValue].
class _StatusFilterRow extends StatelessWidget {
  const _StatusFilterRow({required this.value, required this.onChanged});

  final String? value;
  final ValueChanged<String?> onChanged;

  static const _statuses = <String, String>{
    'active': 'Active',
    _probationFilterValue: 'On Probation',
    'on_leave': 'On Leave',
    'notice_period': 'Notice Period',
    'resigned': 'Resigned',
    'terminated': 'Terminated',
  };

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: DropdownButtonFormField<String?>(
        initialValue: value,
        isExpanded: true,
        decoration: InputDecoration(
          isDense: true,
          suffixIcon: value == null
              ? null
              : IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  tooltip: 'Clear filter',
                  onPressed: () => onChanged(null),
                ),
        ),
        items: [
          const DropdownMenuItem(value: null, child: Text('All statuses')),
          for (final entry in _statuses.entries)
            DropdownMenuItem(value: entry.key, child: Text(entry.value)),
        ],
        onChanged: onChanged,
      ),
    );
  }
}

/// Currently-active employee count (not the full headcount — resigned/
/// terminated employees don't count as "total" here), with a 30-day trend
/// line — moved here from the Dashboard. [count] comes from the
/// already-loaded employee list (like every other tile in this section),
/// but the delta is a separate fetch reconstructed server-side from the
/// audit log (see `getActiveEmployeeDelta`), so it's watched independently
/// rather than derived from [count] itself.
class _TotalEmployeesCard extends ConsumerWidget {
  const _TotalEmployeesCard({required this.count});

  final int count;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deltaAsync = ref.watch(employeeActiveDeltaProvider);
    final delta = deltaAsync.valueOrNull;
    final secondaryValue = delta == null
        ? null
        : delta == 0
        ? 'No change in last 30 days'
        : '${delta > 0 ? '+' : ''}$delta in last 30 days';

    return MetricCard(
      label: 'Total Employees',
      value: '$count',
      secondaryValue: secondaryValue,
      color: AppColors.primary,
      icon: Icons.people_alt_outlined,
      dense: true,
    );
  }
}

/// The page's whole stats row — kept deliberately compact (every tile
/// `dense`) since it now holds several tiles instead of the two or three a
/// full-size `MetricCard` row comfortably fits. On-site/Remote/Hybrid,
/// previously three separate tiles, are combined into one [_WorkModeCard]
/// here; Freelancers was dropped entirely (freelancers aren't `Employee`
/// rows, so a headcount page isn't the right place for them — Payroll's own
/// stats already cover them). Avg. Profile Completion and Pending
/// Performance Reviews moved in from the Dashboard's own Overview section —
/// Notice Period was also part of that move, but this page already had its
/// own Notice Period tile (below), so nothing new was needed for it.
class _EmployeeStatsSection extends ConsumerWidget {
  const _EmployeeStatsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employeesAsync = ref.watch(employeeListProvider);
    final employees = employeesAsync.valueOrNull ?? const <Employee>[];
    final authState = ref.watch(authControllerProvider);
    final canViewPerformance =
        authState is AuthAuthenticated &&
        authState.user.hasPermission('performance.manage');

    final activeCount = employees
        .where((employee) => employee.employmentStatus == 'active')
        .length;
    final avgProfileCompletion = employees.isEmpty
        ? 0
        : (employees
                      .map((e) => e.profileCompletionPercentage)
                      .reduce((a, b) => a + b) /
                  employees.length)
              .round();
    final byWorkMode = <String, int>{};
    for (final employee in employees) {
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
    final noticePeriodCount = employees
        .where((employee) => employee.employmentStatus == 'notice_period')
        .length;
    final onLeaveCount = employees
        .where((employee) => employee.employmentStatus == 'on_leave')
        .length;
    final onProbationCount = employees
        .where((employee) => employee.probationStatus == 'on_probation')
        .length;

    // Every tile forced to the same fixed width (`_StatTile`) so the left
    // column reads as a uniform grid regardless of each tile's own natural
    // content width — `_WorkModeCard`'s three icon+count pairs need the
    // most room of any tile, so this width is sized to fit that one
    // comfortably rather than the (narrower) plain MetricCards.
    final tiles = <Widget>[
      _TotalEmployeesCard(count: activeCount),
      MetricCard(
        label: 'Avg. Profile Completion',
        value: '$avgProfileCompletion%',
        color: AppColors.accentTeal,
        icon: Icons.donut_large_outlined,
        dense: true,
      ),
      _WorkModeCard(byWorkMode: byWorkMode),
      MetricCard(
        label: 'Notice Period',
        value: '$noticePeriodCount',
        color: AppColors.secondary,
        icon: Icons.event_busy_outlined,
        dense: true,
      ),
      MetricCard(
        label: 'On Leave',
        value: '$onLeaveCount',
        color: AppColors.warning,
        icon: Icons.beach_access_outlined,
        dense: true,
      ),
      MetricCard(
        label: 'On Probation',
        value: '$onProbationCount',
        color: AppColors.accentTeal,
        icon: Icons.hourglass_bottom_outlined,
        dense: true,
      ),
      if (canViewPerformance) const _PendingReviewsCard(),
    ];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final tile in tiles) _StatTile(child: tile),
            ],
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 260,
          child: PieChartPanel(
            title: 'Employees by Department',
            icon: Icons.apartment_outlined,
            compact: true,
            counts: computeTopCounts(
              employees.where((e) => e.employmentStatus == 'active').toList(),
              (e) => e.department?.name,
              limit: 20,
            ),
          ),
        ),
      ],
    );
  }
}

/// Forces every stat tile in [_EmployeeStatsSection]'s left column to the
/// same fixed width, whatever its own natural content width would have
/// been — a plain `MetricCard`'s dense minimum (120) and `_WorkModeCard`'s
/// three-pair row (its own widest content) would otherwise render at
/// visibly different sizes side by side.
class _StatTile extends StatelessWidget {
  const _StatTile({required this.child});

  final Widget child;

  static const _width = 150.0;

  @override
  Widget build(BuildContext context) => SizedBox(width: _width, child: child);
}

/// Company-wide count of reviews still awaiting a manager's/HR's
/// completion — moved here from the Dashboard's own Overview section
/// (identical computation/providers). A separate async fetch from the
/// (already-loaded) employee list, so it renders its own loading/error
/// value rather than blocking the rest of the stats row.
class _PendingReviewsCard extends ConsumerWidget {
  const _PendingReviewsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewsAsync = ref.watch(allPendingPerformanceReviewsProvider);
    final deltaAsync = ref.watch(pendingReviewsDeltaProvider);
    final delta = deltaAsync.valueOrNull;
    final secondaryValue = delta == null
        ? null
        : delta == 0
        ? 'No change in last 7 days'
        : '${delta > 0 ? '+' : ''}$delta in last 7 days';

    return MetricCard(
      label: 'Pending Performance Reviews',
      value: reviewsAsync.when(
        data: (reviews) => '${reviews.length}',
        loading: () => '…',
        error: (_, _) => '—',
      ),
      secondaryValue: secondaryValue,
      color: AppColors.secondary,
      icon: Icons.rate_review_outlined,
      dense: true,
    );
  }
}

/// On-site/Remote/Hybrid, combined into one compact tile (previously three
/// separate `MetricCard`s) — a single small icon+count per work mode inside
/// one card, rather than a headline number.
class _WorkModeCard extends StatelessWidget {
  const _WorkModeCard({required this.byWorkMode});

  final Map<String, int> byWorkMode;

  static const _modes = <(String key, String label, IconData icon)>[
    ('on_site', 'On-site', Icons.apartment_outlined),
    ('remote', 'Remote', Icons.home_outlined),
    ('hybrid', 'Hybrid', Icons.sync_alt_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('work-mode-card'),
      constraints: const BoxConstraints(minWidth: 150),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.textSecondary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Work Mode',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final (key, label, icon) in _modes) ...[
                Tooltip(
                  message: label,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        '${byWorkMode[key] ?? 0}',
                        style: Theme.of(context).textTheme.titleSmall
                            ?.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
              ],
            ]..removeLast(),
          ),
        ],
      ),
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
                  EmploymentTypeBadge(
                    employmentType: employee.employmentType,
                    dense: true,
                  ),
                  if (employee.probationStatus != null)
                    ProbationBadge(
                      status: employee.probationStatus!,
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
