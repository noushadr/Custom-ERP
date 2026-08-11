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
import '../widgets/employee_status_badges.dart';
import 'departments_page.dart';
import 'employee_profile_page.dart';
import 'invite_employee_page.dart';

enum _DirectoryViewMode { list, hierarchy }

enum _SortOption {
  joiningDate('Joining date'),
  companyId('Company ID'),
  department('Department');

  const _SortOption(this.label);
  final String label;
}

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
  _SortOption? _sortOption;

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
    final canManageDepartments =
        authUser?.hasPermission('departments.manage') ?? false;

    return Padding(
      padding: const EdgeInsets.all(20),
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
                  if (canRead && _viewMode == _DirectoryViewMode.list)
                    PopupMenuButton<_SortOption?>(
                      tooltip: 'Sort by',
                      initialValue: _sortOption,
                      onSelected: (value) =>
                          setState(() => _sortOption = value),
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: null,
                          child: Text('Default order'),
                        ),
                        for (final option in _SortOption.values)
                          PopupMenuItem(value: option, child: Text(option.label)),
                      ],
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.sort, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              _sortOption == null
                                  ? 'Sort'
                                  : 'Sort: ${_sortOption!.label}',
                            ),
                            const Icon(Icons.arrow_drop_down, size: 18),
                          ],
                        ),
                      ),
                    ),
                  if (canManageDepartments)
                    OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const DepartmentsPage(),
                        ),
                      ),
                      icon: const Icon(Icons.apartment_outlined, size: 18),
                      label: const Text('Manage Departments'),
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
                        sortOption: _sortOption,
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
  const _DirectoryBody({
    required this.viewMode,
    required this.searchQuery,
    required this.sortOption,
  });

  final _DirectoryViewMode viewMode;
  final String searchQuery;
  final _SortOption? sortOption;

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

        final filtered = _sortEmployees(
          _filterEmployees(employees, searchQuery),
          sortOption,
        );
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

  List<Employee> _sortEmployees(List<Employee> employees, _SortOption? sort) {
    if (sort == null) return employees;
    final sorted = [...employees];
    switch (sort) {
      case _SortOption.joiningDate:
        sorted.sort((a, b) => a.joiningDate.compareTo(b.joiningDate));
      case _SortOption.companyId:
        sorted.sort((a, b) => a.employeeCode.compareTo(b.employeeCode));
      case _SortOption.department:
        sorted.sort((a, b) {
          final aName = a.department?.name ?? '';
          final bName = b.department?.name ?? '';
          if (aName.isEmpty && bName.isEmpty) return 0;
          if (aName.isEmpty) return 1;
          if (bName.isEmpty) return -1;
          return aName.compareTo(bName);
        });
    }
    return sorted;
  }
}

class _EmployeeList extends StatelessWidget {
  const _EmployeeList({required this.employees});

  final List<Employee> employees;

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
                  EmploymentStatusBadge(status: employee.employmentStatus),
                  WorkModeBadge(workMode: employee.workMode),
                  InfoChip(
                    icon: Icons.apartment_outlined,
                    label: employee.department?.name ?? 'No department',
                    maxWidth: contentWidth,
                  ),
                  InfoChip(
                    icon: Icons.supervisor_account_outlined,
                    label: 'Reports to: ${employee.reportingManager?.name ?? '—'}',
                    maxWidth: contentWidth,
                  ),
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
