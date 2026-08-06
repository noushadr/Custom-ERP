import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../authentication/application/auth_providers.dart';
import '../../../authentication/application/auth_state.dart';
import '../../../../shared/utils/date_format.dart';
import '../../application/employee_providers.dart';
import '../../domain/entities/employee.dart';
import '../widgets/employee_avatar.dart';
import '../widgets/employee_hierarchy_view.dart';
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
      padding: const EdgeInsets.all(32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1040),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (canRead) const _EmployeeMetricsBar(),
              if (canRead) const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (canRead)
                    SegmentedButton<_DirectoryViewMode>(
                      segments: const [
                        ButtonSegment(
                          value: _DirectoryViewMode.list,
                          icon: Icon(Icons.view_list_outlined, size: 18),
                          label: Text('List'),
                        ),
                        ButtonSegment(
                          value: _DirectoryViewMode.hierarchy,
                          icon: Icon(Icons.account_tree_outlined, size: 18),
                          label: Text('Hierarchy'),
                        ),
                      ],
                      selected: {_viewMode},
                      showSelectedIcon: false,
                      onSelectionChanged: (selection) =>
                          setState(() => _viewMode = selection.first),
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
              const SizedBox(height: 24),
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

class _EmployeeMetricsBar extends ConsumerWidget {
  const _EmployeeMetricsBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employeesAsync = ref.watch(employeeListProvider);

    return employeesAsync.maybeWhen(
      data: (employees) {
        final active = employees
            .where((e) => e.employmentStatus == 'active')
            .length;
        final resigned = employees
            .where((e) => e.employmentStatus == 'resigned')
            .length;
        final onSite = employees.where((e) => e.workMode == 'on_site').length;
        final remote = employees.where((e) => e.workMode == 'remote').length;
        final hybrid = employees.where((e) => e.workMode == 'hybrid').length;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _MetricCard(
              label: 'Total Employees',
              value: employees.length,
              color: AppColors.primary,
            ),
            _MetricCard(
              label: 'Active',
              value: active,
              color: AppColors.success,
            ),
            _MetricCard(
              label: 'Resigned',
              value: resigned,
              color: AppColors.error,
            ),
            _MetricCard(
              label: 'On-site',
              value: onSite,
              color: AppColors.textSecondary,
            ),
            _MetricCard(
              label: 'Remote',
              value: remote,
              color: AppColors.textSecondary,
            ),
            _MetricCard(
              label: 'Hybrid',
              value: hybrid,
              color: AppColors.textSecondary,
            ),
          ],
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$value',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(color: color),
          ),
          const SizedBox(height: 4),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
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

        final filtered = _filterEmployees(employees, searchQuery);
        if (filtered.isEmpty) {
          return const Center(child: Text('No employees match your search.'));
        }
        return _EmployeeList(employees: filtered);
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

class _EmployeeList extends StatelessWidget {
  const _EmployeeList({required this.employees});

  final List<Employee> employees;

  @override
  Widget build(BuildContext context) {
    const spacing = 16.0;

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
  const _EmployeeCard({required this.employee, required this.width});

  final Employee employee;
  final double width;

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
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  EmployeeAvatar(
                    fullName: employee.fullName,
                    photoUrl: employee.profilePhotoUrl,
                    radius: 24,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          employee.fullName,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        if ((employee.designation ?? '').isNotEmpty)
                          Text(
                            employee.designation!,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 16,
                runSpacing: 10,
                children: [
                  _EmploymentStatusBadge(status: employee.employmentStatus),
                  _WorkModeBadge(workMode: employee.workMode),
                  _InfoChip(
                    icon: Icons.badge_outlined,
                    label: employee.employeeCode,
                    maxWidth: contentWidth,
                  ),
                  _InfoChip(
                    icon: Icons.email_outlined,
                    label: employee.email,
                    maxWidth: contentWidth,
                  ),
                  _InfoChip(
                    icon: Icons.phone_outlined,
                    label: employee.phoneNumber ?? '—',
                    maxWidth: contentWidth,
                  ),
                  _InfoChip(
                    icon: Icons.event_outlined,
                    label:
                        'Joined ${formatDisplayDate(employee.joiningDate)}',
                    maxWidth: contentWidth,
                  ),
                  _InfoChip(
                    icon: Icons.cake_outlined,
                    label: employee.dateOfBirth == null
                        ? '—'
                        : formatDisplayDate(employee.dateOfBirth!),
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
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label, this.maxWidth});

  final IconData icon;
  final String label;
  final double? maxWidth;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth ?? double.infinity),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmploymentStatusBadge extends StatelessWidget {
  const _EmploymentStatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'active' => ('Active', AppColors.success),
      'on_leave' => ('On Leave', AppColors.warning),
      'notice_period' => ('Notice Period', AppColors.warning),
      'resigned' => ('Resigned', AppColors.error),
      'terminated' => ('Terminated', AppColors.error),
      _ => (status, AppColors.textSecondary),
    };

    return _Badge(label: label, color: color);
  }
}

class _WorkModeBadge extends StatelessWidget {
  const _WorkModeBadge({required this.workMode});

  final String workMode;

  @override
  Widget build(BuildContext context) {
    final (label, icon) = switch (workMode) {
      'remote' => ('Remote', Icons.home_outlined),
      'on_site' => ('On-site', Icons.apartment_outlined),
      'hybrid' => ('Hybrid', Icons.sync_alt_outlined),
      _ => (workMode, Icons.apartment_outlined),
    };

    return _Badge(label: label, color: AppColors.textSecondary, icon: icon);
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color, this.icon});

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: color),
          ),
        ],
      ),
    );
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
